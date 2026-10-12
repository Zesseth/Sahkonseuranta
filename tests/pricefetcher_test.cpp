/* SPDX-License-Identifier: AGPL-3.0-or-later */
#include "pricefetcher.h"
#include <QCoreApplication>
#include <QTimer>
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
    PriceFetcher f;

    QObject::connect(&f, &PriceFetcher::pricesChanged, [&]() {
        QVariantList bars = f.bars();
        printf("bars=%d\n", bars.size());

        // The API serves a rolling ~48 h window, so early quarter hours
        // of the local day may already have rolled out. Expect exactly
        // the entries the API provides for today.
        QDate today = QDate::currentDate();
        int expected = 0;
        QDateTime earliest;
        const QVariantList prices = f.prices();
        for (int i = 0; i < prices.size(); ++i) {
            QDateTime st = prices.at(i).toMap().value("start").toDateTime();
            if (st.date() == today) {
                ++expected;
                if (!earliest.isValid() || st < earliest)
                    earliest = st;
            }
        }
        check(expected >= 90, "API provides (nearly) the full day");
        check(bars.size() == expected,
              "all quarter hours available for today are shown");

        bool ascending = true;
        QDateTime prev;
        bool first = true;
        QDateTime dayStart;
        QDateTime dayEnd;
        for (int i = 0; i < bars.size(); ++i) {
            QDateTime st = bars.at(i).toMap().value("start").toDateTime();
            if (first) {
                dayStart = st;
                check(st == earliest, "first bar matches the earliest available entry");
                first = false;
            } else {
                if (st < prev)
                    ascending = false;
            }
            prev = st;
            dayEnd = st;
        }
        check(ascending, "bars in ascending time order");
        check(dayStart.date() == dayEnd.date(), "bars span a single local day");

        check(f.currentPrice() > 0 || f.currentPrice() < 0, "current price set");
        check(f.displayPrice() == f.currentPrice(),
              "display price equals spot price at 15 min resolution");
        check(f.minPrice() <= f.avgPrice() + 0.0001, "min <= avg");
        check(f.avgPrice() <= f.maxPrice() + 0.0001, "avg <= max");
        check(f.nowUntil().isValid() && f.nowUntil() > QDateTime::currentDateTime(),
              "forecast: current period end is in the future");
        // The chart window starts at the current price period: history
        // before "now" is dropped on every refresh, so there is nothing
        // to scroll back to. One minute of slack covers a period boundary
        // crossed between fetch and check.
        {
            const QVariantList all = f.allBars();
            check(all.size() > 0, "chart window is not empty");
            check(f.allNowIndex() == 0, "allNowIndex is the first bar");
            QDateTime st = all.at(0).toMap().value("start").toDateTime();
            QDateTime now2 = QDateTime::currentDateTime();
            check(st <= now2 && now2 < st.addSecs(15 * 60 + 60),
                  "first chart bar covers the current period");
            // The stats box must describe the same prices the chart shows
            double sum = 0.0;
            int n = 0;
            double mn = 0.0, mx = 0.0;
            for (int i = 0; i < all.size(); ++i) {
                const double p = all.at(i).toMap().value("price").toDouble();
                if (n == 0 || p < mn) mn = p;
                if (n == 0 || p > mx) mx = p;
                sum += p;
                n++;
            }
            check(n > 0 && qAbs(f.avgPrice() - sum / n) < 0.005,
                  "avg matches the chart window");
            check(qAbs(f.minPrice() - mn) < 0.005, "min matches the chart window");
            check(qAbs(f.maxPrice() - mx) < 0.005, "max matches the chart window");
            // The min/max carry their moment, the average its time span
            check(!f.minTimeText().isEmpty(), "min time text set");
            check(!f.maxTimeText().isEmpty(), "max time text set");
            check(!f.windowSpanText().isEmpty(), "window span text set");
        }
        if (f.hasNextPrice()) {
            check(f.nextPriceStart().isValid() && f.nextPriceStart() >= f.nowUntil(),
                  "forecast: next price change is after the current period ends");
        }

        f.setResolution(60);
    });

    QObject::connect(&f, &PriceFetcher::resolutionChanged, [&]() {
        QVariantList bars = f.bars();
        printf("hourly bars=%d\n", bars.size());

        // Expect one bar per hour the API provides for today.
        QDate today = QDate::currentDate();
        int expectedHours = 0;
        int earliestHour = -1;
        const QVariantList prices = f.prices();
        for (int i = 0; i < prices.size(); ++i) {
            QDateTime st = prices.at(i).toMap().value("start").toDateTime();
            if (st.date() == today && st.time().minute() == 0) {
                ++expectedHours;
                if (earliestHour < 0 || st.time().hour() < earliestHour)
                    earliestHour = st.time().hour();
            }
        }
        check(bars.size() == expectedHours,
              "one hourly bar per hour available for today");
        if (bars.size() > 0) {
            QDateTime st = bars.at(0).toMap().value("start").toDateTime();
            check(st.time().hour() == earliestHour && st.time().minute() == 0,
                  "first hourly bar matches the earliest available hour");
        }
        // At 60 min resolution the displayed price is the ongoing hour's
        // average bar, whenever the current hour is found in the bars.
        if (f.nowIndex() >= 0 && f.nowIndex() < bars.size()) {
            double barPrice = bars.at(f.nowIndex()).toMap().value("price").toDouble();
            check(f.displayPrice() == barPrice,
                  "display price equals the ongoing hour bar at 60 min");
        }
        // The hourly chart window also starts at the current period.
        {
            const QVariantList all = f.allBars();
            check(all.size() > 0 && f.allNowIndex() == 0,
                  "hourly chart window starts at the current period");
            if (all.size() > 0) {
                QDateTime st = all.at(0).toMap().value("start").toDateTime();
                QDateTime now2 = QDateTime::currentDateTime();
                check(st <= now2 && now2 < st.addSecs(60 * 60 + 60),
                      "first hourly chart bar covers the current period");
            }
        }
        printf("\n%d checks, %d failures\n", g_checks, g_failures);
        exit(g_failures == 0 ? 0 : 1);
    });

    QTimer::singleShot(20000, [&]() {
        printf("TIMEOUT: no data received\n");
        exit(2);
    });

    f.refresh();
    return app.exec();
}
