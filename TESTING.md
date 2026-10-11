# Testing Guide — Sahkonseuranta

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

1. Verifies the default thresholds (2.0 and 10.0 c/kWh) and default
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

- PriceFetcher: `11 checks, 0 failures`
- Settings: `13 checks, 0 failures`
- Exit code 0 (no crash, no assertion failure)

The PriceFetcher test needs a network connection. If the API is down,
the test prints `TIMEOUT` — run it again later.

### Test runs on record

- **2026-10-11** Debian 13 (trixie), Qt 5.15.15, GCC 14:
  PriceFetcher `11 checks, 0 failures`; Settings `13 checks, 0 failures`
- **2026-10-10** First PriceFetcher run (before thresholds/settings
  existed): found three real bugs, listed in "Test history" below.

## 2. SDK build (Jolla Phone 2026, armv7hl)

The full app (QML included) must be built with the SailfishOS SDK:

```bash
sfdk build -d SailfishOS-4.6.0.15-armv7hl
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
   - [ ] PullDownMenu -> "Näytä huominen": bars visible after 14:15;
         an empty view before that is OK
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
- [ ] `sfdk check` / store validation passes

## Test history

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
