#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QString>

// User-adjustable settings persisted via QSettings. Thresholds are in
// cents per kWh; the traffic-light ball and chart bars are colored by
// comparing the price against them.
class Settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double cheapThreshold READ cheapThreshold WRITE setCheapThreshold NOTIFY cheapThresholdChanged)
    Q_PROPERTY(double expensiveThreshold READ expensiveThreshold WRITE setExpensiveThreshold NOTIFY expensiveThresholdChanged)
    Q_PROPERTY(int resolution READ resolution WRITE setResolution NOTIFY resolutionChanged)

public:
    explicit Settings(QObject *parent = nullptr,
                       const QString &organization = QStringLiteral("fi.zesseth"),
                       const QString &application = QStringLiteral("sahkonseuranta"));

    double cheapThreshold() const;
    void setCheapThreshold(double value);
    double expensiveThreshold() const;
    void setExpensiveThreshold(double value);
    int resolution() const;
    void setResolution(int res);

signals:
    void cheapThresholdChanged();
    void expensiveThresholdChanged();
    void resolutionChanged();

private:
    void load();
    void save();

    QString m_organization;
    QString m_application;
    double m_cheap = 2.0;      // c/kWh, green at or below this
    double m_expensive = 10.0; // c/kWh, red at or above this
    int m_resolution = 15;     // minutes, 15 or 60
};

#endif // SETTINGS_H
