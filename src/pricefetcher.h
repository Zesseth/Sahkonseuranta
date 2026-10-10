#ifndef PRICEFETCHER_H
#define PRICEFETCHER_H

#include <QObject>
#include <QVariantList>
#include <QDateTime>
#include <QNetworkReply>

class QNetworkAccessManager;

class PriceFetcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool hasData READ hasData NOTIFY pricesChanged)
    Q_PROPERTY(QString errorString READ errorString NOTIFY errorStringChanged)
    Q_PROPERTY(QVariantList prices READ prices NOTIFY pricesChanged)
    Q_PROPERTY(QVariantList bars READ bars NOTIFY barsChanged)
    Q_PROPERTY(double currentPrice READ currentPrice NOTIFY currentPriceChanged)
    Q_PROPERTY(double avgPrice READ avgPrice NOTIFY currentPriceChanged)
    Q_PROPERTY(double minPrice READ minPrice NOTIFY currentPriceChanged)
    Q_PROPERTY(double maxPrice READ maxPrice NOTIFY currentPriceChanged)
    Q_PROPERTY(int resolution READ resolution WRITE setResolution NOTIFY resolutionChanged)
    Q_PROPERTY(int nowIndex READ nowIndex NOTIFY barsChanged)

public:
    explicit PriceFetcher(QObject *parent = nullptr);

    bool loading() const;
    bool hasData() const;
    QString errorString() const;
    QVariantList prices() const;
    QVariantList bars() const;
    double currentPrice() const;
    double avgPrice() const;
    double minPrice() const;
    double maxPrice() const;
    int resolution() const;
    void setResolution(int res);
    int nowIndex() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void showToday();
    Q_INVOKABLE void showTomorrow();

signals:
    void loadingChanged();
    void pricesChanged();
    void barsChanged();
    void currentPriceChanged();
    void errorStringChanged();
    void resolutionChanged();

private slots:
    void onFinished();

private:
    void buildBars();
    void setLoading(bool loading);
    void setErrorString(const QString &err);

    QNetworkAccessManager *m_nam;
    QNetworkReply *m_reply = nullptr;
    bool m_loading = false;
    QString m_error;
    QVariantList m_prices;
    QVariantList m_bars;
    double m_currentPrice = 0.0;
    double m_avg = 0.0;
    double m_min = 0.0;
    double m_max = 0.0;
    int m_resolution = 15;
    int m_dayOffset = 0;
    int m_nowIndex = -1;
};

#endif
