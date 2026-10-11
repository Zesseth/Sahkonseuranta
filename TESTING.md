# Testing Guide — Sahkonseuranta

This document describes how the app is tested before a Jolla Store
release: automated unit test, SDK build, emulator testing, and device
testing on a Jolla Phone.

## 1. Unit test: PriceFetcher (no SDK needed)

`src/pricefetcher.{h,cpp}` is independent of the Silica UI, so it can be
compiled and tested in any Qt5 environment (Debian, Ubuntu, Windows,
macOS).

### What the test does

`tests/pricefetcher_test.cpp`:

1. Fetches live data from
   `https://api.porssisahko.net/v2/latest-prices.json`
2. At 15 min resolution, verifies that the bars
   - are in ascending chronological order (00:00 -> 23:45)
   - span a single local day
3. Switches to 60 min resolution and verifies
   - there are exactly 24 bars
   - the first bar starts at 00:00
   - each hourly price is the average of its four quarters
4. Prints price now / average / min / max for manual inspection

### Running (e.g. Debian + qtbase5-dev, qtdeclarative5-dev)

```bash
qmake tests/tests.pro   # or see manual build below
make
./pricefetcher_test
```

Manual build without qmake (e.g. in CI):

```bash
moc src/pricefetcher.h -o moc_pricefetcher.cpp
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c src/pricefetcher.cpp -o pricefetcher.o
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c moc_pricefetcher.cpp -o moc_pf.o
g++ -std=c++17 -fPIC $(pkg-config --cflags Qt5Core Qt5Network) \
    -Isrc -c tests/pricefetcher_test.cpp -o test_main.o
g++ pricefetcher.o moc_pf.o test_main.o -o pricefetcher_test \
    $(pkg-config --libs Qt5Core Qt5Network)
./pricefetcher_test
```

### Acceptance criteria

- `bars=96` (15 min) and `bars=24` (60 min) for the local day
- Times in ascending order, first 00:00, last 23:45/23:00
- `current` is a plausible value (e.g. 0-10 c/kWh), `min <= avg <= max`
- Exit code 0 (no crash, no assertion failure)

The test needs a network connection. If the API is down, the test prints
`TIMEOUT` — run it again later.

### Test run on record (2026-10-10, Qt 5.15.15, Debian)

```
prices fetched, bars=96
  00:00  1.583 c/kWh
  00:15  1.505 c/kWh
  ...
current=4.533 avg=3.331 min=1.365 max=6.275 res=15
after res switch: bars=24  first 00:00 1.677
```

Bugs found by this test run are listed in "Test history" below.

## 2. SDK build (Jolla Phone 2026, armv7hl)

The full app (QML included) must be built with the SailfishOS SDK:

```bash
sfdk config --sailfish-sdk-map <SDK path>
sfdk build -d SailfishOS-4.6.0.15-armv7hl
```

Success criteria:

- `moc` and compilation pass without warnings
- `RPMS/noarch/` (or `RPMS/armv7hl/`) contains
  `harbour-sahkonseuranta-0.1.0-1.*.rpm`
- `rpmlint harbour-sahkonseuranta-*.rpm` reports no errors

Troubleshooting:

- `SailfishApp not found` -> verify `find_package(SailfishApp)` and run
  the build inside the sfdk build engine, not on the host
- `Sailfish.Silica` missing -> CMake only installs the `qml/` directory;
  Silica comes from the SDK image and is not bundled

## 3. Emulator testing (SailfishOS SDK)

```bash
sfdk emulator --armv7hl   # or the x86 VM
```

1. Install the RPM: `sfdk engine exec sb2 -m ... pkcon install-local <rpm>`
2. Launch the app from the launcher
3. Check:
   - [ ] Current price appears within a few seconds
   - [ ] Bar chart renders: 96 bars, ascending time order
   - [ ] "1 h" collapses the chart to 24 bars
   - [ ] "15 min" restores 96 bars
   - [ ] PullDownMenu -> "Päivitä" refreshes the data
   - [ ] PullDownMenu -> "Näytä huominen": bars visible after 14:15;
         an empty view before that is OK
   - [ ] Cover shows the current price while the app is in the
         background; tapping the cover brings the app forward
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
      (check `systemctl` / watchdog settings)
- [ ] Sailjail: the app requests only the `Internet` permission
- [ ] No leftover background process after closing via the Home key

## 5. Before a Jolla Store release

Store checklist (harbour rules):

- [ ] Name starts with `harbour-` (yes)
- [ ] No openrepo or third-party dependencies (yes)
- [ ] At least 2 screenshots (capture from the emulator)
- [ ] Description and version number in sync with `rpm/*.yaml`
- [ ] `sfdk check` / store validation passes

## Test history

- **2026-10-10** The first test run exposed three real bugs:
  1. `setLoading`/`setErrorString` were missing from the header
     (compile error)
  2. 60 min aggregation hit a `QList::replace` assertion (a map copy was
     not in the list). Fixed with index-based grouping.
  3. Bars were in reverse time order (the API returns newest first).
     Fixed with a `std::sort`.
  All fixed; the test passes.

- **2026-10-11** Re-run under WSL2 Debian (Qt 5.15.3): 9 checks,
  0 failures.
