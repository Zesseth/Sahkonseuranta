/* SPDX-License-Identifier: AGPL-3.0-or-later */
#include "settings.h"

#include <QDir>
#include <QSettings>
#include <QStandardPaths>

namespace {
const char *kKeyCheap = "cheapThreshold";
const char *kKeyExpensive = "expensiveThreshold";
const char *kKeyResolution = "resolution";
// The green threshold must always be strictly below the red one.
// Thresholds are whole cents.
const double kMinThresholdGap = 1.0;
}

// The Sailfish sandbox (sailjail) whitelists ${HOME}/.config/<org>/<app>
// as a directory but not the QSettings default file <org>/<app>.conf,
// so the settings are stored inside the whitelisted directory instead.
QString Settings::settingsFilePath(const QString &organization,
                                   const QString &application)
{
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QDir dir(configDir + QLatin1Char('/') + organization
             + QLatin1Char('/') + application);
    dir.mkpath(QStringLiteral("."));
    return dir.filePath(QStringLiteral("settings.ini"));
}

Settings::Settings(QObject *parent, const QString &organization, const QString &application)
    : QObject(parent)
    , m_organization(organization)
    , m_application(application)
{
    load();
}

double Settings::cheapThreshold() const
{
    return m_cheap;
}

double Settings::expensiveThreshold() const
{
    return m_expensive;
}

int Settings::resolution() const
{
    return m_resolution;
}

void Settings::setCheapThreshold(double value)
{
    if (value < 0.0)
        value = 0.0;
    value = qRound(value);
    if (m_cheap == value)
        return;
    m_cheap = value;
    if (m_expensive < m_cheap + kMinThresholdGap)
        m_expensive = m_cheap + kMinThresholdGap;
    save();
    emit cheapThresholdChanged();
    if (m_expensive == m_cheap + kMinThresholdGap)
        emit expensiveThresholdChanged();
}

void Settings::setExpensiveThreshold(double value)
{
    value = qRound(value);
    if (value < m_cheap + kMinThresholdGap)
        value = m_cheap + kMinThresholdGap;
    if (m_expensive == value)
        return;
    m_expensive = value;
    save();
    emit expensiveThresholdChanged();
}

void Settings::setResolution(int res)
{
    if (res != 15 && res != 60)
        return;
    if (m_resolution == res)
        return;
    m_resolution = res;
    save();
    emit resolutionChanged();
}

void Settings::load()
{
    QSettings s(settingsFilePath(m_organization, m_application), QSettings::IniFormat);
    m_cheap = s.value(QString::fromLatin1(kKeyCheap), 5.0).toDouble();
    if (m_cheap < 0.0)
        m_cheap = 0.0;
    m_cheap = qRound(m_cheap);
    m_expensive = s.value(QString::fromLatin1(kKeyExpensive), 10.0).toDouble();
    if (m_expensive < m_cheap + kMinThresholdGap)
        m_expensive = m_cheap + kMinThresholdGap;
    else
        m_expensive = qRound(m_expensive);
    const int res = s.value(QString::fromLatin1(kKeyResolution), 15).toInt();
    if (res == 15 || res == 60)
        m_resolution = res;
}

void Settings::save()
{
    QSettings s(settingsFilePath(m_organization, m_application), QSettings::IniFormat);
    s.setValue(QString::fromLatin1(kKeyCheap), m_cheap);
    s.setValue(QString::fromLatin1(kKeyExpensive), m_expensive);
    s.setValue(QString::fromLatin1(kKeyResolution), m_resolution);
}
