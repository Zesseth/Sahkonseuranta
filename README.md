# Sähkönseuranta

Electricity spot price tracker for SailfishOS. The app shows Finnish
electricity spot prices as a **bar chart** at 15-minute or 1-hour
resolution. Target device: Jolla Phone (2026), release channel: Jolla
Store.

The user interface is in Finnish; the codebase and documentation are in
English.

## Features

- Current price shown next to a **ball** whose color tells the price
  level: green = cheap (Halpa), yellow = normal (Normaali),
  red = expensive (Kallis)
- The current **level is named in text** and a **forecast** tells when
  the level changes and into which level
- The color thresholds are **user-configurable** in the settings page
  (whole cents per kWh, VAT-included prices)
- Chart resolution (15 min / 1 h) is chosen in the settings and
  persists across sessions
- The displayed price follows the chosen resolution: the ongoing spot
  price at 15 min, the ongoing hour's average at 1 h; the clock line
  shows the start time of the ongoing price period
- Scrollable bar chart covering the current day onward (yesterday is
  dropped on every refresh; the view opens at the current period),
  colored with the same thresholds: current bar marked with a bright
  border and an axis diamond, dashed threshold lines, gray grid,
  whole-cent y axis, whole-hour x axis
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
sfdk config target=SailfishOS-4.6.0.13-armv7hl && sfdk build   # Jolla Phone (2026)
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for full environment setup and
[TESTING.md](TESTING.md) for testing procedures.

The app uses only Sailfish App / Silica / Qt5 base modules — no openrepo
dependencies — so it satisfies the Jolla Store harbour requirements.

## Versioning

The app version follows `major.minor.patch` (e.g. `1.2.3`):

- **major** — bumped when a GitHub milestone is complete. Milestone 1 is
  the first Jolla Store release: **version 1.0.0**.
- **minor** — bumped for new features.
- **patch** — bumped for bug fixes.

Every GitHub release goes to the Jolla Store immediately — releases are
not batched up waiting for more fixes.

The version is defined in **two places that must stay in sync**:

- `CMakeLists.txt` (`project(... VERSION ...)`) — feeds the version shown
  in the app's Settings page
- `rpm/harbour-sahkonseuranta.yaml` (`Version:`) — feeds the RPM package
  and the Jolla Store

The RPM `Release:` field (e.g. `Release: 29`) is a **packaging counter
only**. During development it is bumped for every emulator install so
`pkcon` accepts the same version again; users never see it. For a Jolla
Store release it is set to `1` and left there.

### Release flow (Jolla Store)

1. Complete the milestone, update `Version` in both files, set
   `Release: 1`.
2. Tag a GitHub release (`vX.Y.Z`) matching the version.
3. Build for the device: `sfdk config target=SailfishOS-4.6.0.13-armv7hl
   && sfdk build`.
4. Upload the armv7hl RPM to [Jolla Harbour](https://harbour.jolla.com).
5. After validation the Store publishes it; user devices update
   automatically.

## License

GNU Affero General Public License v3.0 or later (AGPL-3.0-or-later) —
see [LICENSE](LICENSE). Each source file carries an
`SPDX-License-Identifier: AGPL-3.0-or-later` tag. Anyone may use,
study, modify, and redistribute this software, including commercially,
but any distributed or network-served version must be released in full,
under the same license, with source code available. Closed-source or
proprietary derivatives are not permitted.
