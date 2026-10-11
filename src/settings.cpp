#include "settings.h"

#include <QSettings>

namespace {
const char *kKeyCheap = "cheapThreshold";
const char *kKeyExpensive = "expensiveThreshold";
const char *kKeyResolution = "resolution";
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
    if (m_cheap == value)
        return;
    m_cheap = value;
    if (m_expensive < m_cheap)
        m_expensive = m_cheap;
    save();
    emit cheapThresholdChanged();
    if (m_expensive == m_cheap)
        emit expensiveThresholdChanged();
}

void Settings::setExpensiveThreshold(double value)
{
    if (value < m_cheap)
        value = m_cheap;
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
    QSettings s(m_organization, m_application);
    m_cheap = s.value(QString::fromLatin1(kKeyCheap), 2.0).toDouble();
    if (m_cheap < 0.0)
        m_cheap = 0.0;
    m_expensive = s.value(QString::fromLatin1(kKeyExpensive), 10.0).toDouble();
    if (m_expensive < m_cheap)
        m_expensive = m_cheap;
    const int res = s.value(QString::fromLatin1(kKeyResolution), 15).toInt();
    if (res == 15 || res == 60)
        m_resolution = res;
}

void Settings::save()
{
    QSettings s(m_organization, m_application);
    s.setValue(QString::fromLatin1(kKeyCheap), m_cheap);
    s.setValue(QString::fromLatin1(kKeyExpensive), m_expensive);
    s.setValue(QString::fromLatin1(kKeyResolution), m_resolution);
}
