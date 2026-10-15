# Events View widget (SailfishOS)

This directory ships the **Events View widget** for Sähkönseuranta on
SailfishOS (verified against Sailfish OS 5.x, target device Jolla Phone 2026).

## How it works

Lipstick (the SailfishOS home screen) loads third-party Events View
widgets from JSON descriptors installed under:

    /usr/share/lipstick/eventswidgets/

Each descriptor points to a QML file that Lipstick loads **inside its own
process**. Because of that the widget is fully self-contained:

- it fetches the spot prices itself from the porssisahko.net v2 API
  (same endpoint and parsing rules as the app's `PriceFetcher`),
- it reads the user's thresholds and chart resolution from the same
  QSettings file the app writes (`~/.config/fi.zesseth/sahkonseuranta.conf`),
- it shares the price-level logic (`Levels.js`) and the ball component
  (`PriceBall.qml`) with the app through a relative QML import,
- it only does work while it is actually on screen: the Events View
  keeps enabled widgets instantiated and `visible` the whole time, so
  the widget additionally requires the loader-provided
  `eventsViewVisible` context property to hold. The fetch is
  re-aligned to just after each quarter-hour boundary, and all timers
  and in-flight requests are stopped when the Events View is left.

## Requirements

- **Sailfish OS 5.x or later.** Third-party Events View widgets are
  loaded by `EventsWidgetsModel` in lipstick-jolla-home 5.0 and
  later. Sailfish OS 4.6 has no such loader: there the companion
  RPM installs, but nothing ever loads the widget. The main app is
  of course unaffected on every release.
- The main app (`harbour-sahkonseuranta` >= 1.0.0) must be installed;
  the companion RPM declares this dependency.

## Layout

- `qml/eventsview/PriceWidget.qml` (in the main app tree) — the widget
  itself. Installed by the main RPM under
  `/usr/share/harbour-sahkonseuranta/qml/eventsview/`, which is an
  allowed location for the Jolla Store.
- `harbour-sahkonseuranta.json` — the Lipstick registration
  descriptor (`title`, `icon`, `order`, `path`, `available_path`,
  `default_enabled`), matching the descriptor format of the built-in
  weather and calendar widgets.
- `rpm/harbour-sahkonseuranta-widget.yaml` — spectacle spec for
  the separate companion RPM that installs the JSON under
  `/usr/share/lipstick/eventswidgets/`.

## Why two packages

The Jolla Harbour RPM validator only allows files in the application's
own directories (`/usr/share/<appname>/`, `/usr/bin/<appname>`, the
`.desktop` file and icons). A file under `/usr/share/lipstick/` fails
validation with "Installation not allowed in this location", so the
registration JSON **cannot ship inside the Jolla Store RPM**.

The split therefore keeps the main Store package clean:

- **Store RPM** (`harbour-sahkonseuranta`): ships the widget QML inside
  the app's own data directory. Harmless on its own, ready for the day
  Jolla provides an official registration path.
- **Companion RPM** (`harbour-sahkonseuranta-widget`, OpenRepos/Chum):
  installs just the registration JSON and requires the main app.

## Enabling the widget

Install the main app, then install the companion RPM:

    pkcon install-local harbour-sahkonseuranta-widget-1.1.0-1.noarch.rpm

The widget appears in **Settings → Events view** and is enabled by
default (`default_enabled: true`). Uninstalling the main app while
keeping the companion leaves the widget entry pointing at a missing
QML file; the `available_path` field lets the settings page detect
that.

## Building the companion RPM

```bash
cd widget
sfdk build          # produces RPMS/.../harbour-sahkonseuranta-widget-1.1.0-1.noarch.rpm
```

## Limitations

- The registration mechanism is not an official Harbour API; it is the
  reverse-engineered Lipstick mechanism documented by the community
  (Sailfish OS Forum, "API to make/show widgets on the Events screen?",
  Aug 2026, and Pauligrinder's documentation PR to
  docs.sailfishos.org). It can change between Sailfish OS releases.
- The widget QML runs in the Lipstick process and must stay light; all
  heavy logic remains in the app.
