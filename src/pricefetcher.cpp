#include "pricefetcher.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrl>
#include <QTimer>

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
double PriceFetcher::currentPrice() const { return m_currentPrice; }
double PriceFetcher::avgPrice() const { return m_avg; }
double PriceFetcher::minPrice() const { return m_min; }
double PriceFetcher::maxPrice() const { return m_max; }
int PriceFetcher::resolution() const { return m_resolution; }

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

void PriceFetcher::showToday()
{
    m_dayOffset = 0;
    buildBars();
}

void PriceFetcher::showTomorrow()
{
    m_dayOffset = 1;
    buildBars();
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

void PriceFetcher::buildBars()
{
    m_bars.clear();
    m_avg = 0.0;
    m_min = 0.0;
    m_max = 0.0;

    if (m_prices.isEmpty()) {
        emit barsChanged();
        emit currentPriceChanged();
        return;
    }

    QDateTime now = QDateTime::currentDateTime();
    QDate day = now.date().addDays(m_dayOffset);

    QVariantList dayPrices;
    double sum = 0.0;
    int n = 0;
    for (int i = 0; i < m_prices.size(); ++i) {
        QVariantMap entry = m_prices.at(i).toMap();
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

    if (m_resolution == 60) {
        QVariantList hourly;
        for (const QVariant &v : dayPrices) {
            QVariantMap entry = v.toMap();
            QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
            QVariantMap existing;
            for (const QVariant &h : hourly) {
                QVariantMap m = h.toMap();
                if (m.value(QStringLiteral("start")).toDateTime().time().hour() == start.time().hour()
                        && m.value(QStringLiteral("start")).toDateTime().date() == start.date()) {
                    existing = m;
                    break;
                }
            }
            if (!existing.isEmpty()) {
                double ps = existing.value(QStringLiteral("priceSum")).toDouble()
                        + entry.value(QStringLiteral("price")).toDouble();
                existing.insert(QStringLiteral("priceSum"), ps);
                existing.insert(QStringLiteral("count"), existing.value(QStringLiteral("count")).toInt() + 1);
                hourly.replace(hourly.indexOf(existing), existing);
            } else {
                QVariantMap m;
                m.insert(QStringLiteral("start"), start);
                m.insert(QStringLiteral("priceSum"), entry.value(QStringLiteral("price")).toDouble());
                m.insert(QStringLiteral("count"), 1);
                hourly.append(m);
            }
        }
        dayPrices.clear();
        for (const QVariant &v : hourly) {
            QVariantMap m = v.toMap();
            QVariantMap bar;
            bar.insert(QStringLiteral("start"), m.value(QStringLiteral("start")));
            bar.insert(QStringLiteral("price"), m.value(QStringLiteral("priceSum")).toDouble() / m.value(QStringLiteral("count")).toDouble());
            dayPrices.append(bar);
        }
    }

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
