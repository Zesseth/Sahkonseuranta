#include "settings.h"
#include <QCoreApplication>
#include <QSettings>
#include <cstdio>
#include <cstdlib>

namespace {
int g_checks = 0;
int g_failures = 0;

void check(bool ok, const char *what)
{
    ++g_checks;
    if (!ok) {
        ++g_failures;
        printf("FAIL: %s\n", what);
    } else {
        printf("ok  : %s\n", what);
    }
}
}

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    // Test-scoped QSettings so the real app configuration is untouched.
    const QString org = QStringLiteral("sahkonseuranta-test");
    const QString appl = QStringLiteral("settings-test");
    QSettings(org, appl).clear();

    Settings s(nullptr, org, appl);
    check(s.cheapThreshold() == 2.0, "default cheap threshold is 2.0");
    check(s.expensiveThreshold() == 10.0, "default expensive threshold is 10.0");
    check(s.resolution() == 15, "default resolution is 15 min");

    s.setCheapThreshold(4.5);
    check(s.cheapThreshold() == 4.5, "cheap threshold set to 4.5");
    check(s.expensiveThreshold() == 10.0, "expensive threshold unchanged");

    s.setExpensiveThreshold(1.0);
    check(s.expensiveThreshold() == 4.5, "expensive threshold clamped to cheap");

    s.setCheapThreshold(-1.0);
    check(s.cheapThreshold() == 0.0, "negative cheap threshold clamps to 0");

    s.setResolution(30);
    check(s.resolution() == 15, "invalid resolution 30 rejected");
    s.setResolution(60);
    check(s.resolution() == 60, "resolution 60 accepted");
    s.setResolution(0);
    check(s.resolution() == 60, "invalid resolution 0 rejected");

    // A fresh instance must read back the persisted values.
    Settings s2(nullptr, org, appl);
    check(s2.cheapThreshold() == 0.0, "cheap threshold persisted");
    check(s2.expensiveThreshold() == 4.5, "expensive threshold persisted");
    check(s2.resolution() == 60, "resolution persisted");

    QSettings(org, appl).clear();

    printf("\n%d checks, %d failures\n", g_checks, g_failures);
    return g_failures == 0 ? 0 : 1;
}
