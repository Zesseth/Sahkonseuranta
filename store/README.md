# Jolla Store listing materials

This folder holds the materials needed for the Jolla Store (Harbour)
listing. Keeping them in the repository means the listing stays in
sync with the app and can be reviewed like any other change.

Contents:

- `description-fi.md` - the Finnish store description (paste into the
  Harbour submission form)
- `screenshots/` - store screenshots at the emulator's native
  resolution (720x1600). Capture over SSH with the lipstick screenshot
  API (needs root on the session bus; VirtualBox's own capture is
  only half resolution - do not use it for the store):

  ```
  ssh -p 2223 root@<emulator-ip> \
    "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/100000/dbus/user_bus_socket \
     dbus-send --session --print-reply --dest=com.jolla.lipstick \
     /org/nemomobile/lipstick/screenshot \
     org.nemomobile.lipstick.saveScreenshot string:/home/defaultuser/Pictures/shot.png"
  ```

  On a real device, use the system screenshot gesture instead

What does **not** belong here:

- **The built RPM** - build artifacts are not committed. At release
  time run `sfdk build` (armv7hl for the device), attach the RPM to
  the matching GitHub Release, and upload that file to Jolla Harbour.
  The GitHub Release is the archive of "what was shipped".

## Release checklist (issue #4)

1. `sfdk check` passes on the armv7hl build
2. At least 2 screenshots in `screenshots/` (main page + settings)
3. Description text finalized in `description-fi.md`
4. `Version` in `rpm/harbour-sahkonseuranta.yaml` in sync with the
   description (first store release is 1.0.0)
5. Upload to Jolla Harbour: description, screenshots, category
   (Utilities), the armv7hl RPM, license "AGPL-3.0"
