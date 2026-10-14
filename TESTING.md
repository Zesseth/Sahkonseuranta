# Testing Guide — Sähkönseuranta

This document describes how the app is tested before a Jolla Store
release: automated unit tests, SDK build, emulator testing, and device
testing on a Jolla Phone.

## 1. Unit tests (no SDK needed)

`src/pricefetcher.{h,cpp}` and `src/settings.{h,cpp}` are independent of
the Silica UI, so they can be compiled and tested in any Qt5 environment
(Debian, Ubuntu, Windows, macOS).

### PriceFetcher test (`tests/pricefetcher_test.cpp`)

1. Fetches live data from
   `https://api.porssisahko.net/v2/latest-prices.json`
2. At 15 min resolution, verifies that the bars
   - are in ascending chronological order (00:00 -> 23:45)
   - span a single local day
   - the displayed price equals the current spot price
3. Switches to 60 min resolution and verifies
   - there are exactly 24 bars
   - the first bar starts at 00:00
   - the displayed price equals the ongoing hour's average bar
4. Prints price now / average / min / max for manual inspection

### Settings test (`tests/settings_test.cpp`)

1. Verifies the default thresholds (5.0 and 10.0 c/kWh) and default
   resolution (15 min)
2. Verifies that the expensive threshold is clamped to the cheap
   threshold and that negative values are rejected
3. Verifies that only 15 and 60 minute resolutions are accepted
4. Verifies persistence: a fresh instance reads back saved values
   (the test uses its own QSettings scope, not the real app config)

### Running (e.g. Debian + qtbase5-dev)

```bash
cd tests
qmake tests.pro -o Makefile && make && ./pricefetcher_test
qmake settings_test.pro -o Makefile.settings_test && make -f Makefile.settings_test && ./settings_test
```

### Acceptance criteria

- PriceFetcher: `16 checks, 0 failures`
- Settings: `17 checks, 0 failures`
- Exit code 0 (no crash, no assertion failure)

The PriceFetcher test needs a network connection. If the API is down,
the test prints `TIMEOUT` — run it again later.

### Test runs on record

- **2026-10-11** SDK build + store validation on WSL2 Debian, SailfishOS
  SDK 3.13.5 (Docker build engine), target SailfishOS-4.6.0.13-armv7hl:
  `sfdk build` produces `RPMS/harbour-sahkonseuranta-0.1.0-1.armv7hl.rpm`
  and `sfdk check` reports "Validation succeeded". First-ever successful
  app build; required fixing the build system (CMake pkg-config lookup
  for SailfishApp, missing desktop/icon installs, spectacle yaml
  `Builder`/`PkgConfigBR`/`Requires` setup, X-Nemo-Application-Type,
  172x172 icon, spec %changelog). Remaining rpmlint warnings:
  unstripped binary (keeps symbols for device debugging) and unknown
  unstripped binary (keeps symbols for device debugging). The license
  tag AGPL-3.0-or-later is a standard SPDX identifier.
- **2026-10-11** Debian 13 (trixie), Qt 5.15.15, GCC 14:
  PriceFetcher `11 checks, 0 failures`; Settings `13 checks, 0 failures`
- **2026-10-11** Static checks on the same host: all QML files pass
  `qmllint` (syntax), `shellcheck` clean on `scripts/protect-main.sh`,
  `desktop-file-validate` passes, RPM YAML parses, translation XML is
  well-formed, no secrets in source. Found and fixed one real defect:
  the 86/108/128 px launcher icons were actually 256 px images; they
  are now correctly sized (resized from the 256 px master).
- **2026-10-10** First PriceFetcher run (before thresholds/settings
  existed): found three real bugs, listed in "Test history" below.

## 2. SDK build (Jolla Phone 2026, armv7hl)

The full app (QML included) must be built with the SailfishOS SDK:

```bash
sfdk config target=SailfishOS-4.6.0.13-armv7hl && sfdk build
```

Success criteria:

- `moc` and compilation pass without warnings
- `RPMS/noarch/` (or `RPMS/armv7hl/`) contains
  `harbour-sahkonseuranta-0.1.0-1.*.rpm`
- `rpmlint harbour-sahkonseuranta-*.rpm` reports no errors

## 3. Emulator testing (SailfishOS SDK)

```bash
sfdk emulator --armv7hl   # or the x86 VM
```

1. Install the RPM:
   `sfdk engine exec sb2 -m ... pkcon install-local <rpm>`
2. Launch the app from the launcher
3. Check:
   - [ ] Current price appears within a few seconds
   - [ ] The ball next to the price is green/yellow/red according to
         the configured thresholds
   - [ ] Bar chart renders with threshold colors, ascending time order
   - [ ] PullDownMenu -> "Asetukset" opens the settings page
   - [ ] Changing the green/red thresholds immediately recolors the
         ball and the chart bars
   - [ ] Setting resolution to "1 tunti" collapses the chart to 24
         bars; "15 min" restores 96 bars
   - [ ] The settings persist after restarting the app
   - [ ] With 1 h resolution, the displayed price is the ongoing
         hour's average (not the quarter-hour spot price)
   - [ ] PullDownMenu -> "Päivitä" refreshes the data
   - [ ] The chart shows the full ~48 h window the API returns and
         scrolls sideways; tomorrow's bars are reachable by scrolling
   - [ ] Cover shows the ball and the current price while the app is in
         the background
   - [ ] Airplane mode: "Päivitä" shows an error instead of crashing

## 4. Device testing (Jolla Phone 2026)

```bash
sfdk device           # or scp + pkcon install-local
```

Additionally on hardware:

- [ ] Launcher icon renders correctly (86x86)
- [ ] Chart is readable in direct sunlight (Ambience colors)
- [ ] Mobile data: fetching survives a slow network
- [ ] Memory stays stable across the 30-minute auto-refresh cycle
- [ ] Sailjail: the app requests only the `Internet` permission
- [ ] Settings survive a device reboot (QSettings is written inside
      the sandboxed config directory)
- [ ] No leftover background process after closing via the Home key

## 5. Before a Jolla Store release

Store checklist (harbour rules):

- [ ] Name starts with `harbour-` (yes)
- [ ] No openrepo or third-party dependencies (yes)
- [ ] At least 2 screenshots (capture from the emulator)
- [ ] Description and version number in sync with `rpm/*.yaml`
- [ ] RPM `Release:` set to `1` and `Version` bumped per the README
      versioning scheme
- [ ] `sfdk check` / store validation passes

## 6. Events View widget (companion RPM)

The Events View widget is loaded by lipstick-jolla-home 5.x
(`EventsWidgetsModel`); Sailfish OS 4.6 has no third-party widget
loader at all, so the 4.6 emulator can only verify that the
companion RPM installs cleanly - functional widget testing needs a
SFOS 5.x emulator or a SFOS 5.x device (Jolla Phone 2026).

Build and install:

```bash
cd widget && sfdk build   # noarch RPM
rpm -U harbour-sahkonseuranta-1.0.0-11.i486.rpm \
       harbour-sahkonseuranta-widget-1.0.0-1.noarch.rpm
```

- [x] Descriptor is valid JSON and installs to
      `/usr/share/lipstick/eventswidgets/harbour-sahkonseuranta.json`
      (verified on the SailfishOS-5.1.0.11 emulator, 2026-10-14)
- [x] The Store RPM (main app) passes `sfdk check` with the widget
      QML inside `/usr/share/harbour-sahkonseuranta/qml/eventsview/`
- [x] Settings → Events view lists "Sähkönseuranta" with the
      app icon (emulator, 2026-10-14)
- [x] The widget appears on the Events View: ball, price, level name
      and the level-change forecast match the app front page
      (verified against the live API on the emulator; also the
      compact layout with the level on the price row)
- [x] The widget uses the app's thresholds: changing them in the app
      and reopening the Events View recolors the widget (threshold 5 →
      4 verified end to end on the emulator)
- [ ] 15 min vs 1 h resolution follows the app setting
- [x] The price updates within seconds after each quarter-hour
      boundary while the Events View is shown (price 2,72 → 4,016
      observed across the 19:15 boundary with the view open)
- [x] Leaving the Events View stops the polling (no fetches while the
      home screen or an app is in the foreground; zero API
      connections across the 19:30 boundary with the view closed)
- [x] Airplane mode: the widget shows "Ei yhteyttä" instead of
      crashing Lipstick (network cut on the emulator; Lipstick
      stayed alive, and with stale data present the forecast line is
      replaced by "Ei yhteyttä" so a stale price is labeled)
- [ ] Lipstick survives enabling/disabling the widget in settings and
      uninstalling the companion RPM
- [x] The app runs under sailjail with only the Internet permission;
      its settings persist through the sandbox
      (`~/.config/fi.zesseth/sahkonseuranta/settings.ini`) and the
      widget reads them

## Test history

- **2026-10-14** Events View widget functional testing on the
  SailfishOS-5.1.0.11 SDK emulator (VirtualBox, WSL2 host, SDK 3.13.5):
  - Fresh SFOS 5.1 emulator installed via `sfdk emulator install`
    (a 5.x emulator image became available; the 4.6 emulator still
    cannot run third-party widgets). App + companion RPM installed;
    the widget loads inside Lipstick without a single QML/JS error.
  - Live-data verification: the widget fetched from
    api.porssisahko.net inside the Lipstick process (established
    HTTPS connection observed), rendered the correct level color
    cross-checked against the live API, updated across the
    quarter-hour boundary, and stopped all polling while the Events
    View was closed (zero connections across a boundary).
  - Two real defects found and fixed:
    1. The widget's settings fallback assumed `/home/nemo`; SFOS 5.x
       uses `/home/defaultuser`, and the `/proc/self/environ` read
       fails on the emulator, so the widget ignored the app's
       thresholds. The widget now tries `$HOME`, then
       `/home/defaultuser`, then `/home/nemo`, reading both the
       sandboxed settings file and the legacy QSettings file.
    2. The app's QSettings file (`~/.config/fi.zesseth/sahkonseuranta.conf`)
       is NOT whitelisted by sailjail (only the `sahkonseuranta`
       directory is), so user settings silently vanished in the
       sandbox. Settings now persist at
       `~/.config/fi.zesseth/sahkonseuranta/settings.ini` inside the
       whitelisted directory; unit tests updated accordingly
       (Settings 17 checks, 0 failures). Threshold change verified
       end to end: app UI → settings.ini → widget recolor.
  - Layout per user feedback: the level moved onto the price row and
    the ball enlarged (less vertical space for notifications).
  - Airplane mode (network cut on the emulator): Lipstick stayed
    alive. Improvement made: a failed fetch with stale data now
    replaces the forecast line with "Ei yhteyttä" instead of
    silently showing an old price as current.
  - Store validation re-run after every change: `sfdk check`
    "Validation succeeded" (0 errors).
- **2026-10-14** Second Events View widget review round (branch
  vibe/events-view-widget-2828ea, host build, SDK 3.13.5):
  - Unit tests re-run against the live API: PriceFetcher
    26 checks, 0 failures; Settings 17 checks, 0 failures.
  - Security/efficiency review of the widget found one defect,
    now fixed: a non-numeric `price` value in the API response is
    skipped like an invalid date, so `NaN` can never reach the
    Lipstick UI (the app's C++ side already degraded it to 0.0).
  - After the fix: `sfdk build` OK and `sfdk check` reports
    **Validation succeeded** (0 errors); the Store RPM ships the
    fixed `qml/eventsview/PriceWidget.qml` (sha256-verified).
  - Companion RPM: rpmlint 0 errors (known AGPL tag warning only);
    `sfdk check` on the companion fails on the
    `/usr/share/lipstick/` path, confirming the Store/companion
    split is required.
  - `qmllint` was not runnable on this host (the host wrapper
    points to a missing binary); the QML change is covered by the
    rebuild above.
- **2026-10-14** Events View widget review round (branch
  vibe/events-view-widget-2828ea, WSL2 Debian, SDK 3.13.5):
  - Unit tests re-run against the live API: PriceFetcher
    26 checks, 0 failures; Settings 17 checks, 0 failures.
  - `qmllint` (Ubuntu 22.04 host, Qt 5.15) clean on every QML
    file including `qml/eventsview/PriceWidget.qml`.
  - `sfdk build` OK for SailfishOS-4.6.0.13-armv7hl,
    SailfishOS-4.6.0.13-i486 and SailfishOS-5.1.0.11-i486; the
    RPM ships `qml/eventsview/PriceWidget.qml` under
    `/usr/share/harbour-sahkonseuranta/` (md5-verified against
    the source).
  - `sfdk check` (harbour validator): **Validation succeeded**
    on a release-style build (tagged, Version 1.0.0). Dev
    builds only fail the "version must contain digits and
    periods" rule because sfdk appends a +branch.sha suffix.
  - The companion RPM builds noarch via `sfdk build` in
    `widget/` and contains exactly
    `/usr/share/lipstick/eventswidgets/harbour-sahkonseuranta.json`;
    Requires `harbour-sahkonseuranta >= 1.0.0`; rpmlint: 0
    errors (known AGPL tag warning only).
  - Research findings baked into the code: SFOS 4.6
    lipstick-jolla-home has **no third-party Events View widget
    loader** (`EventsWidgetsModel` exists only in 5.x), the
    active gate is now `visible && eventsViewVisible` with a
    safe fallback, the `/proc/self/environ` HOME match is
    anchored, and the descriptor carries `available_path`.
  - Still open: functional widget verification on a SFOS 5.x
    device (checklist in section 6). The 4.6 emulator cannot
    show third-party widgets and no 5.x emulator image was
    available in this environment.
- **2026-10-11** Re-ran the full unit test suite under WSL2 Debian
  after the price-ball/settings rework: PriceFetcher 11 checks, 0
  failures (including new displayPrice checks); Settings 13 checks,
  0 failures.
- **2026-10-10** The first PriceFetcher test run exposed three real
  bugs: 1) `setLoading`/`setErrorString` were missing from the header
  (compile error); 2) 60 min aggregation hit a `QList::replace`
  assertion (a map copy was not in the list), fixed with index-based
  grouping; 3) bars were in reverse time order (the API returns newest
  first), fixed with a `std::sort`.
