# Sahkonseuranta

Electricity spot price tracker for SailfishOS. The app shows Finnish
electricity spot prices as a **bar chart** at 15-minute or 1-hour
resolution. Target device: Jolla Phone (2026), release channel: Jolla
Store.

The user interface is in Finnish; the codebase and documentation are in
English.

## Features (v0.1)

- Current spot price displayed prominently (c/kWh, VAT included)
- Traffic-light pricing: green = cheap (at or below the daily average, or
  negative), yellow = normal (up to 2x the daily average), red = expensive
- Switchable 15 min / 1 h resolution
- Daily bar chart with traffic-light colors; current bar highlighted,
  negative prices drawn below the zero line
- Today / tomorrow view
- Stats row: average / min / max for the day
- Cover page showing the current price
- Automatic refresh every 30 minutes
- Prices fetched from the open
  [porssisahko.net](https://porssisahko.net/api) v2 API (no key
  required, 192 quarter-hourly prices per fetch)

## Credits

The Android app [HattiWatti](https://play.google.com/store/apps/details?id=com.hattiwatti.hattiwatti)
was the original motivation for this project and inspired the
traffic-light pricing concept. This project is **not** a port or a
replica of HattiWatti, and it does not aim to follow HattiWatti's
development. Sahkonseuranta is an independent SailfishOS app with its own
scope and roadmap.

## Project layout

```
qml/harbour-sahkonseuranta.qml — application window
qml/pages/MainPage.qml          — main page (chart, price info)
qml/components/PriceGraph.qml   — bar chart component (traffic-light colors)
qml/components/TrafficLight.qml — traffic light (cheap/normal/expensive)
qml/cover/CoverPage.qml         — cover page
src/main.cpp                    — startup, priceFetcher exposed as context property
src/pricefetcher.{h,cpp}        — API fetch, JSON parsing, aggregation
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

BSD-3-Clause — see [LICENSE](LICENSE).
