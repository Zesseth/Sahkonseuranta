# Sähkönseuranta

Electricity spot price tracker for SailfishOS. The app shows Finnish
electricity spot prices as a **bar chart** at 15-minute or 1-hour
resolution. Target device: Jolla Phone (2026), release channel: Jolla
Store.

The user interface is in Finnish; the codebase and documentation are in
English.

## Features

- Current price shown next to a **ball** whose color tells the price
  level: green = cheap, yellow = normal, red = expensive
- The color thresholds are **user-configurable** in the settings page
  (cents per kWh, VAT-included prices)
- Chart resolution (15 min / 1 h) is chosen in the settings and
  persists across sessions
- The displayed price follows the chosen resolution: the ongoing spot
  price at 15 min, the ongoing hour's average at 1 h
- Daily bar chart colored with the same thresholds; current bar
  highlighted, negative prices drawn below the zero line
- Today / tomorrow view
- Stats row: average / min / max for the day
- Cover page showing the current price
- Automatic refresh every 30 minutes
- Prices fetched from the open
  [porssisahko.net](https://porssisahko.net/api) v2 API (no key
  required, 192 quarter-hourly prices per fetch)

Planned work is tracked in the repository's
[issues](https://github.com/Zesseth/Sahkonseuranta/issues) and release
milestones.

## Credits

The Android app [HattiWatti](https://play.google.com/store/apps/details?id=com.hattiwatti.hattiwatti)
was the original motivation for this project. This project is **not**
a port or a replica of HattiWatti, and it does not aim to follow
HattiWatti's development. Sähkönseuranta is an independent SailfishOS
app with its own scope and roadmap.

## Project layout

```
qml/harbour-sahkonseuranta.qml — application window
qml/pages/MainPage.qml          — main page (ball, price, chart, stats)
qml/pages/SettingsPage.qml      — thresholds and chart resolution
qml/components/PriceBall.qml    — colored ball + plain price
qml/components/PriceGraph.qml   — bar chart component (threshold colors)
qml/cover/CoverPage.qml         — cover page
src/main.cpp                    — startup, context properties
src/pricefetcher.{h,cpp}        — API fetch, JSON parsing, aggregation
src/settings.{h,cpp}            — user settings (QSettings persistence)
icons/                          — launcher icons (86, 108, 128, 256)
rpm/harbour-sahkonseuranta.yaml — RPM packaging
```

## Building (SailfishOS SDK)

```bash
sfdk build -d SailfishOS-4.6.0.15-armv7hl   # Jolla Phone (2026)
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for full environment setup and
[TESTING.md](TESTING.md) for testing procedures.

The app uses only Sailfish App / Silica / Qt5 base modules — no openrepo
dependencies — so it satisfies the Jolla Store harbour requirements.

## License

PolyForm Noncommercial 1.0.0 — see [LICENSE](LICENSE). The source code
is open: anyone may read, study, modify, and share it for personal,
hobby, educational, and other noncommercial purposes. Commercial use,
including offering the software as a hosted or managed service, is not
permitted without a separate license from the copyright holder.
