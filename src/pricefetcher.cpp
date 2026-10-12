/* SPDX-License-Identifier: AGPL-3.0-or-later */
#include "pricefetcher.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QTimer>
#include <algorithm>

namespace {
const char *kLatestPricesUrl = "https://api.porssisahko.net/v2/latest-prices.json";
const int kAutoRefreshMs = 30 * 60 * 1000;
}

PriceFetcher::PriceFetcher(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    QTimer *timer = new QTimer(this);
    timer->setInterval(kAutoRefreshMs);
    connect(timer, &QTimer::timeout, this, &PriceFetcher::refresh);
    timer->start();
}

bool PriceFetcher::loading() const { return m_loading; }
bool PriceFetcher::hasData() const { return !m_prices.isEmpty(); }
QString PriceFetcher::errorString() const { return m_error; }
QVariantList PriceFetcher::prices() const { return m_prices; }
QVariantList PriceFetcher::bars() const { return m_bars; }
QVariantList PriceFetcher::allBars() const { return m_allBars; }
int PriceFetcher::allNowIndex() const { return m_allNowIndex; }
double PriceFetcher::currentPrice() const { return m_currentPrice; }

double PriceFetcher::displayPrice() const
{
    if (m_resolution == 60 && m_nowIndex >= 0 && m_nowIndex < m_bars.size()) {
        return m_bars.at(m_nowIndex).toMap().value(QStringLiteral("price")).toDouble();
    }
    return m_currentPrice;
}
double PriceFetcher::avgPrice() const { return m_avg; }
double PriceFetcher::minPrice() const { return m_min; }
double PriceFetcher::maxPrice() const { return m_max; }
int PriceFetcher::resolution() const { return m_resolution; }
int PriceFetcher::nowIndex() const { return m_nowIndex; }
QDateTime PriceFetcher::nowUntil() const { return m_nowUntil; }
bool PriceFetcher::hasNextPrice() const { return m_hasNextPrice; }
double PriceFetcher::nextPrice() const { return m_nextPrice; }
QDateTime PriceFetcher::nextPriceStart() const { return m_nextPriceStart; }

void PriceFetcher::setResolution(int res)
{
    if (res != 15 && res != 60)
        return;
    if (m_resolution == res)
        return;
    m_resolution = res;
    buildBars();
    emit resolutionChanged();
}

void PriceFetcher::refresh()
{
    if (m_loading)
        return;
    setLoading(true);
    emit loadingChanged();

    QNetworkRequest req(QUrl(QString::fromLatin1(kLatestPricesUrl)));
    req.setHeader(QNetworkRequest::UserAgentHeader,
                 QStringLiteral("harbour-sahkonseuranta/0.1"));
    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, &PriceFetcher::onFinished);
}

void PriceFetcher::onFinished()
{
    if (!m_reply)
        return;

    QNetworkReply *reply = m_reply;
    m_reply = nullptr;
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        setErrorString(QStringLiteral("Verkkovirhe"));
        setLoading(false);
        emit loadingChanged();
        return;
    }
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        setErrorString(QStringLiteral("Virheellinen vastaus"));
        setLoading(false);
        emit loadingChanged();
        return;
    }
    QJsonArray arr = doc.object().value(QStringLiteral("prices")).toArray();
    m_prices.clear();
    for (const QJsonValue &v : arr) {
        QJsonObject o = v.toObject();
        QDateTime start = QDateTime::fromString(o.value(QStringLiteral("startDate")).toString(), Qt::ISODate);
        if (!start.isValid())
            continue;
        start.setTimeSpec(Qt::UTC);
        QDateTime end = QDateTime::fromString(o.value(QStringLiteral("endDate")).toString(), Qt::ISODate);
        if (!end.isValid())
            continue;
        end.setTimeSpec(Qt::UTC);
        QVariantMap entry;
        entry.insert(QStringLiteral("price"), o.value(QStringLiteral("price")).toDouble());
        entry.insert(QStringLiteral("start"), start.toLocalTime());
        entry.insert(QStringLiteral("end"), end.toLocalTime());
        m_prices.append(entry);
    }

    setErrorString(QString());
    setLoading(false);
    buildBars();

    emit pricesChanged();
    emit loadingChanged();
    emit errorStringChanged();
}

namespace {
// Aggregate quarter-hour entries into hourly average bars.
QVariantList aggregateHourly(const QVariantList &in)
{
    QVariantList hourly;
    for (int i = 0; i < in.size(); ++i) {
        QVariantMap entry = in.at(i).toMap();
        QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        int found = -1;
        for (int h = 0; h < hourly.size(); ++h) {
            QVariantMap m = hourly.at(h).toMap();
            QDateTime hs = m.value(QStringLiteral("start")).toDateTime();
            if (hs.date() == start.date() && hs.time().hour() == start.time().hour()) {
                found = h;
                break;
            }
        }
        if (found >= 0) {
            QVariantMap m = hourly.at(found).toMap();
            m.insert(QStringLiteral("priceSum"),
                     m.value(QStringLiteral("priceSum")).toDouble()
                     + entry.value(QStringLiteral("price")).toDouble());
            m.insert(QStringLiteral("count"), m.value(QStringLiteral("count")).toInt() + 1);
            hourly.replace(found, m);
        } else {
            QVariantMap m;
            m.insert(QStringLiteral("start"), start);
            m.insert(QStringLiteral("priceSum"), entry.value(QStringLiteral("price")).toDouble());
            m.insert(QStringLiteral("count"), 1);
            hourly.append(m);
        }
    }
    QVariantList out;
    for (int i = 0; i < hourly.size(); ++i) {
        QVariantMap m = hourly.at(i).toMap();
        QVariantMap bar;
        bar.insert(QStringLiteral("start"), m.value(QStringLiteral("start")));
        bar.insert(QStringLiteral("price"),
                   m.value(QStringLiteral("priceSum")).toDouble()
                   / m.value(QStringLiteral("count")).toDouble());
        out.append(bar);
    }
    return out;
}
}

void PriceFetcher::buildBars()
{
    m_bars.clear();
    m_allBars.clear();
    m_avg = 0.0;
    m_min = 0.0;
    m_max = 0.0;
    m_nowIndex = -1;
    m_allNowIndex = -1;

    if (m_prices.isEmpty()) {
        emit barsChanged();
        emit currentPriceChanged();
        return;
    }

    QDateTime now = QDateTime::currentDateTime();
    QDate day = now.date();

    // Everything the API returned, in ascending time order
    QVariantList sorted = m_prices;
    std::sort(sorted.begin(), sorted.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap().value(QStringLiteral("start")).toDateTime()
                < b.toMap().value(QStringLiteral("start")).toDateTime();
    });

    // The full window for the scrollable chart
    m_allBars = (m_resolution == 60) ? aggregateHourly(sorted) : sorted;

    QVariantList dayPrices;
    double sum = 0.0;
    int n = 0;
    for (int i = 0; i < sorted.size(); ++i) {
        QVariantMap entry = sorted.at(i).toMap();
        QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        if (start.date() == day) {
            dayPrices.append(entry);
            sum += entry.value(QStringLiteral("price")).toDouble();
            n++;
        }
    }

    if (n > 0) {
        m_avg = sum / n;
        m_min = dayPrices.first().toMap().value(QStringLiteral("price")).toDouble();
        m_max = m_min;
        for (const QVariant &v : dayPrices) {
            double p = v.toMap().value(QStringLiteral("price")).toDouble();
            if (p < m_min) m_min = p;
            if (p > m_max) m_max = p;
        }
    }

    if (m_resolution == 60)
        dayPrices = aggregateHourly(dayPrices);

    m_currentPrice = 0.0;
    for (int i = 0; i < m_prices.size(); ++i) {
        QVariantMap entry = m_prices.at(i).toMap();
        QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        QDateTime end = entry.value(QStringLiteral("end")).toDateTime();
        if (start <= now && now < end) {
            m_currentPrice = entry.value(QStringLiteral("price")).toDouble();
            break;
        }
    }

    for (int i = 0; i < dayPrices.size(); ++i) {
        QVariantMap entry = dayPrices.at(i).toMap();
        QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        QDateTime end = entry.value(QStringLiteral("end")).toDateTime();
        if (!end.isValid())
            end = start.addSecs(3600);
        if (start <= now && now < end) {
            m_nowIndex = i;
            break;
        }
    }

    // Index of "now" in the full window (for the scrollable chart)
    {
        const int periodMin = (m_resolution == 60) ? 60 : 15;
        for (int i = 0; i < m_allBars.size(); ++i) {
            QVariantMap entry = m_allBars.at(i).toMap();
            QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
            QDateTime end = start.addSecs(periodMin * 60);
            if (start <= now && now < end) {
                m_allNowIndex = i;
                break;
            }
        }
    }

    // Forecast: how long the ongoing price level holds and what follows it.
    m_nowUntil = QDateTime();
    m_hasNextPrice = false;
    m_nextPrice = 0.0;
    m_nextPriceStart = QDateTime();
    if (m_nowIndex >= 0 && m_nowIndex < dayPrices.size()) {
        const QVariantMap cur = dayPrices.at(m_nowIndex).toMap();
        const QDateTime start = cur.value(QStringLiteral("start")).toDateTime();
        const int periodMin = (m_resolution == 60) ? 60 : 15;
        QDateTime end = cur.value(QStringLiteral("end")).toDateTime();
        if (!end.isValid())
            end = start.addSecs(periodMin * 60);
        m_nowUntil = end;
        const double curPrice = cur.value(QStringLiteral("price")).toDouble();
        for (int i = m_nowIndex + 1; i < dayPrices.size(); ++i) {
            const QVariantMap e = dayPrices.at(i).toMap();
            const double p = e.value(QStringLiteral("price")).toDouble();
            if (qAbs(p - curPrice) > 0.0001) {
                m_nextPrice = p;
                m_nextPriceStart = e.value(QStringLiteral("start")).toDateTime();
                m_hasNextPrice = true;
                break;
            }
        }
    }

    m_bars = dayPrices;
    emit barsChanged();
    emit currentPriceChanged();
}

void PriceFetcher::setLoading(bool loading)
{
    m_loading = loading;
}

void PriceFetcher::setErrorString(const QString &err)
{
    m_error = err;
}
