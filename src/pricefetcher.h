/* SPDX-License-Identifier: AGPL-3.0-or-later */
#ifndef PRICEFETCHER_H
#define PRICEFETCHER_H

#include <QObject>
#include <QVariantList>
#include <QDateTime>
#include <QNetworkReply>
#include <QTimer>

class QNetworkAccessManager;

class PriceFetcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY pricesChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)
    Q_PROPERTY(QVariantList prices READ prices NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList bars READ bars NOTIFY barsChanged)
    // The full window the API returned (today + tomorrow), for the
    // scrollable chart; bars covers only the selected day.
    Q_PROPERTY(QVariantList allBars READ allBars NOTIFY allBarsChanged)
    Q_PROPERTY(int allNowIndex READ allNowIndex NOTIFY allBarsChanged)
    Q_PROPERTY(double currentPrice READ currentPrice NOTIFY currentPriceChanged)
    // Price shown on the front page: the spot price at 15 min resolution,
    // or the average of the ongoing hour at 60 min resolution.
    Q_PROPERTY(double displayPrice READ displayPrice NOTIFY barsChanged)
    Q_PROPERTY(double avgPrice READ avgPrice NOTIFY statsChanged)
    Q_PROPERTY(double minPrice READ minPrice NOTIFY statsChanged)
    Q_PROPERTY(double maxPrice READ maxPrice NOTIFY statsChanged)
    Q_PROPERTY(int resolution READ resolution WRITE setResolution NOTIFY resolutionChanged)
    Q_PROPERTY(int nowIndex READ nowIndex NOTIFY barsChanged)
    // How long the current price level holds and what it changes into.
    // nowUntil is the end of the ongoing price period; nextPrice/nextPriceStart
    // describe the first following period with a different price (hasNextPrice).
    Q_PROPERTY(QDateTime nowUntil READ nowUntil NOTIFY nowPeriodChanged)
    Q_PROPERTY(bool hasNextPrice READ hasNextPrice NOTIFY nowPeriodChanged)
    Q_PROPERTY(double nextPrice READ nextPrice NOTIFY nowPeriodChanged)
    Q_PROPERTY(QDateTime nextPriceStart READ nextPriceStart NOTIFY nowPeriodChanged)

public:
    explicit PriceFetcher(QObject *parent = nullptr);

    bool loading() const;
    bool hasData() const;
    QString errorString() const;
    QVariantList prices() const;
    QVariantList bars() const;
    QVariantList allBars() const;
    int allNowIndex() const;
    double currentPrice() const;
    double displayPrice() const;
    double avgPrice() const;
    double minPrice() const;
    double maxPrice() const;
    int resolution() const;
    void setResolution(int res);
    int nowIndex() const;
    QDateTime nowUntil() const;
    bool hasNextPrice() const;
    double nextPrice() const;
    QDateTime nextPriceStart() const;

    Q_INVOKABLE void refresh();
    // Pause the 30-minute auto-refresh while the application is not
    // active (background/cover), so a suspended device is not woken up
    void setAutoRefreshEnabled(bool enabled);

signals:
    void loadingChanged();
    void pricesChanged();
    // Bars for the selected day and the full chart window; distinct
    // signals so a future emit of one can never leave the other stale
    void barsChanged();
    void allBarsChanged();
    // Day statistics
    void statsChanged();
    void currentPriceChanged();
    // The ongoing period and the next price change
    void nowPeriodChanged();
    void errorStringChanged();
    void resolutionChanged();

private slots:
    void onFinished();

private:
    void buildBars();
    // Setters emit their NOTIFY signal only when the value changes
    void setLoading(bool loading);
    void setErrorString(const QString &err);

    QNetworkAccessManager *m_nam;
    QNetworkReply *m_reply = nullptr;
    QTimer *m_refreshTimer = nullptr;
    bool m_loading = false;
    QString m_error;
    QVariantList m_prices;
    QVariantList m_bars;
    QVariantList m_allBars;
    int m_allNowIndex = -1;
    double m_currentPrice = 0.0;
    double m_avg = 0.0;
    double m_min = 0.0;
    double m_max = 0.0;
    int m_resolution = 15;
    int m_nowIndex = -1;
    QDateTime m_nowUntil;
    bool m_hasNextPrice = false;
    double m_nextPrice = 0.0;
    QDateTime m_nextPriceStart;
};

#endif // PRICEFETCHER_H
