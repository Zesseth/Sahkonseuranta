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

        check(bars.size() == 96, "96 bars at 15 min resolution");

        bool ascending = true;
        QDateTime prev;
        bool first = true;
        QDateTime dayStart;
        QDateTime dayEnd;
        for (int i = 0; i < bars.size(); ++i) {
            QDateTime st = bars.at(i).toMap().value("start").toDateTime();
            if (first) {
                dayStart = st;
                check(st.time().hour() == 0 && st.time().minute() == 0,
                      "first bar starts at 00:00");
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

        f.setResolution(60);
    });

    QObject::connect(&f, &PriceFetcher::resolutionChanged, [&]() {
        QVariantList bars = f.bars();
        printf("hourly bars=%d\n", bars.size());
        check(bars.size() == 24, "24 bars at 60 min resolution");
        if (bars.size() > 0) {
            QDateTime st = bars.at(0).toMap().value("start").toDateTime();
            check(st.time().hour() == 0 && st.time().minute() == 0,
                  "first hourly bar starts at 00:00");
        }
        // At 60 min resolution the displayed price is the ongoing hour's
        // average bar, whenever the current hour is found in the bars.
        if (f.nowIndex() >= 0 && f.nowIndex() < bars.size()) {
            double barPrice = bars.at(f.nowIndex()).toMap().value("price").toDouble();
            check(f.displayPrice() == barPrice,
                  "display price equals the ongoing hour bar at 60 min");
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
