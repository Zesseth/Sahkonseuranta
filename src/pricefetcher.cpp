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
// Abort a request that has not finished within this time so a hung
// connection cannot leave the app stuck in the loading state
const int kRequestTimeoutMs = 20 * 1000;
// The spot price changes at each quarter-hour boundary; fetch a few
// seconds after it so the app always has the new period's price
const int kBoundaryOffsetMs = 5 * 1000;

QString weekdayAbbr(const QDate &d)
{
    static const char *const names[] = { "Su", "Ma", "Ti", "Ke", "To", "Pe", "La" };
    return QString::fromLatin1(names[d.dayOfWeek() - 1]);
}

// "HH:mm", with the weekday abbreviation appended when the moment is
// not the nearest future occurrence of that clock time
QString timeText(const QDateTime &t)
{
    QString s = t.toString(QStringLiteral("HH:mm"));
    const QDate today = QDate::currentDate();
    const QDate d = t.date();
    if (d == today)
        return s;
    // Today's occurrence of the same clock time has already passed, so
    // the plain time unambiguously means the coming one
    if (d == today.addDays(1) && t.time() < QTime::currentTime())
        return s;
    return s + QStringLiteral(" ") + weekdayAbbr(d);
}

// Display text for a moment in the chart window: "klo HH:mm", with the
// weekday abbreviation following the time when a reader could place
// the moment on the wrong day ("klo 13:00 Ti", "klo 00:45 Ke")
QString formatMomentText(const QDateTime &t)
{
    if (!t.isValid())
        return QString();
    return QStringLiteral("klo ") + timeText(t);
}
// Safety clamps so a clock jump can never leave the refresh timer
// without a valid interval (and thus without ever fetching)
const int kMinRefreshMs = 10 * 1000;
const int kMaxRefreshMs = 15 * 60 * 1000 + kBoundaryOffsetMs;
}

PriceFetcher::PriceFetcher(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
    m_refreshTimer = new QTimer(this);
    m_refreshTimer->setSingleShot(true);
    connect(m_refreshTimer, &QTimer::timeout, this, &PriceFetcher::refresh);
    scheduleNextRefresh();
}

void PriceFetcher::setAutoRefreshEnabled(bool enabled)
{
    m_autoRefresh = enabled;
    if (!enabled) {
        m_refreshTimer->stop();
        return;
    }
    // Fetch as soon as the app activates, then realign the auto-refresh
    // to the quarter-hour boundaries from there
    refresh();
}

void PriceFetcher::scheduleNextRefresh()
{
    // Align the next fetch to just after the next quarter-hour
    // boundary, when the spot price changes; every refresh re-runs this
    // so the schedule never drifts behind, and the clamps guarantee a
    // valid interval even if the clock jumps
    const QTime t = QDateTime::currentDateTime().time();
    const int msIntoQuarter = (t.minute() % 15) * 60 * 1000
            + t.second() * 1000 + t.msec();
    const int interval = qBound(kMinRefreshMs,
                                15 * 60 * 1000 - msIntoQuarter + kBoundaryOffsetMs,
                                kMaxRefreshMs);
    m_refreshTimer->start(interval);
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
QString PriceFetcher::minTimeText() const { return formatMomentText(m_minTime); }
QString PriceFetcher::maxTimeText() const { return formatMomentText(m_maxTime); }
QString PriceFetcher::windowSpanText() const
{
    if (m_allBars.isEmpty())
        return QString();
    const QDateTime first = m_allBars.first().toMap().value(QStringLiteral("start")).toDateTime();
    const QDateTime lastStart = m_allBars.last().toMap().value(QStringLiteral("start")).toDateTime();
    const int periodMin = (m_resolution == 60) ? 60 : 15;
    const QDateTime lastEnd = lastStart.addSecs(periodMin * 60);
    return QStringLiteral("klo ") + timeText(first)
            + QStringLiteral(" \u2013 ") + timeText(lastEnd);
}
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
    // Schedule the next fetch up front so even a failing or timing-out
    // request leaves the next quarter-boundary attempt in place
    if (m_autoRefresh)
        scheduleNextRefresh();

    // A refresh supersedes an in-flight request instead of being
    // silently ignored, so a manual "Päivitä" always starts a fetch
    if (m_reply) {
        disconnect(m_reply, nullptr, this, nullptr);
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
        setLoading(false);
    }

    setLoading(true);

    QNetworkRequest req(QUrl(QString::fromLatin1(kLatestPricesUrl)));
    req.setHeader(QNetworkRequest::UserAgentHeader,
                 QStringLiteral("harbour-sahkonseuranta/1.0"));
    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, &PriceFetcher::onFinished);

    // Time the request out on a stalled connection; abort() triggers
    // the connected finished() handler, which runs the normal error path
    QNetworkReply *reply = m_reply;
    QTimer::singleShot(kRequestTimeoutMs, this, [this, reply]() {
        if (m_reply == reply)
            reply->abort();
    });
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
        return;
    }
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) {
        setErrorString(QStringLiteral("Virheellinen vastaus"));
        setLoading(false);
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
}

namespace {
// Aggregate quarter-hour entries into hourly average bars. The input
// is in ascending time order, so consecutive entries sharing the same
// calendar hour are grouped in a single O(n) pass.
QVariantList aggregateHourly(const QVariantList &in)
{
    QVariantList out;
    QDateTime hourStart;
    double sum = 0.0;
    int count = 0;
    for (int i = 0; i < in.size(); ++i) {
        const QVariantMap entry = in.at(i).toMap();
        const QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        const double price = entry.value(QStringLiteral("price")).toDouble();
        if (count > 0 && hourStart.date() == start.date()
                && hourStart.time().hour() == start.time().hour()) {
            sum += price;
            count++;
        } else {
            if (count > 0) {
                QVariantMap bar;
                bar.insert(QStringLiteral("start"), hourStart);
                bar.insert(QStringLiteral("price"), sum / count);
                out.append(bar);
            }
            hourStart = start;
            sum = price;
            count = 1;
        }
    }
    if (count > 0) {
        QVariantMap bar;
        bar.insert(QStringLiteral("start"), hourStart);
        bar.insert(QStringLiteral("price"), sum / count);
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
        emit allBarsChanged();
        emit statsChanged();
        emit currentPriceChanged();
        emit nowPeriodChanged();
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
    for (int i = 0; i < sorted.size(); ++i) {
        QVariantMap entry = sorted.at(i).toMap();
        QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
        if (start.date() == day)
            dayPrices.append(entry);
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

    // The chart window starts at the current price period: history
    // before "now" is dropped on every refresh, so the first bar is
    // always the ongoing one and there is nothing to scroll back to.
    {
        const int periodMin = (m_resolution == 60) ? 60 : 15;
        for (int i = 0; i < m_allBars.size(); ++i) {
            QVariantMap entry = m_allBars.at(i).toMap();
            QDateTime start = entry.value(QStringLiteral("start")).toDateTime();
            QDateTime end = start.addSecs(periodMin * 60);
            if (start <= now && now < end) {
                if (i > 0)
                    m_allBars = m_allBars.mid(i);
                m_allNowIndex = m_allBars.isEmpty() ? -1 : 0;
                break;
            }
        }
    }

    // Statistics over the chart window so the numbers always match what
    // the graph shows: every value can be found in the chart
    {
        double sum = 0.0;
        int n = 0;
        for (int i = 0; i < m_allBars.size(); ++i) {
            const QVariantMap entry = m_allBars.at(i).toMap();
            const double p = entry.value(QStringLiteral("price")).toDouble();
            if (n == 0 || p < m_min) {
                m_min = p;
                m_minTime = entry.value(QStringLiteral("start")).toDateTime();
            }
            if (n == 0 || p > m_max) {
                m_max = p;
                m_maxTime = entry.value(QStringLiteral("start")).toDateTime();
            }
            sum += p;
            n++;
        }
        if (n > 0) {
            m_avg = sum / n;
        } else {
            m_avg = 0.0;
            m_min = 0.0;
            m_max = 0.0;
            m_minTime = QDateTime();
            m_maxTime = QDateTime();
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
    emit allBarsChanged();
    emit statsChanged();
    emit currentPriceChanged();
    emit nowPeriodChanged();
}

void PriceFetcher::setLoading(bool loading)
{
    if (m_loading == loading)
        return;
    m_loading = loading;
    emit loadingChanged();
}

void PriceFetcher::setErrorString(const QString &err)
{
    if (m_error == err)
        return;
    m_error = err;
    emit errorStringChanged();
}
