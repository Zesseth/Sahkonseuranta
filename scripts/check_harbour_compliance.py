#!/usr/bin/env python3
# SPDX-License-Identifier: AGPL-3.0-or-later
"""Static Jolla Store (Harbour) compliance check.

Verifies against the OFFICIAL sdk-harbour-rpmvalidator config files that:
  1. every QML import used under qml/ is on the allowed_qmlimports list
  2. every runtime Requires in rpm/*.spec / rpm/*.yaml is on the
     allowed_requires list
  3. no files are installed outside the Harbour-allowed locations
     (/usr/bin/<name>, /usr/share/<name>, .desktop, icons) -- this is the
     guard that keeps the /usr/share/lipstick/eventswidgets/ mistake from
     recurring.

Usage: check_harbour_compliance.py [validator-repo-dir]
Without an argument the configs are fetched from GitHub master.
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = "harbour-sahkonseuranta"

QML_CONF_URL = ("https://raw.githubusercontent.com/sailfishos/"
                "sdk-harbour-rpmvalidator/master/allowed_qmlimports.conf")
REQ_CONF_URL = ("https://raw.githubusercontent.com/sailfishos/"
                "sdk-harbour-rpmvalidator/master/allowed_requires.conf")


def load_conf(path, url):
    if os.path.isfile(path):
        with open(path) as f:
            lines = f.read().splitlines()
    else:
        try:
            out = subprocess.run(["curl", "-fsSL", url],
                                 capture_output=True, text=True, check=True)
            lines = out.stdout.splitlines()
        except Exception as e:
            print(f"FAIL: could not load {os.path.basename(path)}: {e}")
            sys.exit(1)
    return {ln.strip() for ln in lines
            if ln.strip() and not ln.lstrip().startswith("#")}


def main():
    validator_dir = sys.argv[1] if len(sys.argv) > 1 else None
    if validator_dir:
        qml_allowed = load_conf(os.path.join(validator_dir,
                                             "allowed_qmlimports.conf"), QML_CONF_URL)
        req_allowed = load_conf(os.path.join(validator_dir,
                                             "allowed_requires.conf"), REQ_CONF_URL)
    else:
        qml_allowed = load_conf("", QML_CONF_URL)
        req_allowed = load_conf("", REQ_CONF_URL)

    failures = []

    # --- 1. QML imports -----------------------------------------------------
    print("== QML imports vs allowed_qmlimports.conf ==")
    used = set()
    for dirpath, _dirs, files in os.walk(os.path.join(ROOT, "qml")):
        for fn in files:
            if not fn.endswith(".qml"):
                continue
            with open(os.path.join(dirpath, fn)) as f:
                for line in f:
                    m = re.match(r"\s*import\s+(\S+)(?:\s+(\S+))?", line)
                    if m:
                        used.add(f"{m.group(1)} {m.group(2) or ''}".strip())
    for imp in sorted(used):
        if imp.startswith('"'):  # local directory import
            continue
        if imp in qml_allowed:
            print(f"ok:   {imp}")
        else:
            print(f"FAIL: QML import not allowed by Harbour: {imp}")
            failures.append(imp)

    # --- 2. Runtime Requires -------------------------------------------------
    print("== Requires vs allowed_requires.conf ==")
    reqs = set()
    spec = open(os.path.join(ROOT, "rpm", f"{APP}.spec")).read()
    for m in re.finditer(r"^Requires:\s*(.+)$", spec, re.M):
        reqs.add(m.group(1).strip())
    import yaml
    y = yaml.safe_load(open(os.path.join(ROOT, "rpm", f"{APP}.yaml")))
    for r in y.get("Requires", []) or []:
        reqs.add(str(r).strip())
    for req in sorted(reqs):
        name = req.split()[0]  # strip version constraint
        if name in req_allowed or f"qml({name})" in req_allowed:
            print(f"ok:   {req}")
        else:
            print(f"FAIL: Requires not on Harbour allowed list: {req}")
            failures.append(req)

    # --- 3. Install paths ----------------------------------------------------
    print("== install paths ==")
    cmake = open(os.path.join(ROOT, "CMakeLists.txt")).read()
    # every install(... DESTINATION x) must be an allowed location
    for m in re.finditer(r"install\([^)]*?DESTINATION\s+(\S+)", cmake, re.S):
        dest = m.group(1).rstrip(")")
        allowed = dest in ("bin", f"share/{APP}", "share/applications") \
            or dest.startswith("share/icons")
        if allowed:
            print(f"ok:   DESTINATION {dest}")
        else:
            print(f"FAIL: CMake DESTINATION outside allowed locations: {dest}")
            failures.append(dest)
    files_sec = spec.split("%files", 1)[1] if "%files" in spec else ""
    files_sec = files_sec.split("%changelog", 1)[0]  # stop at changelog
    allowed_prefixes = (f"%{{_bindir}}/{APP}", f"%{{_datadir}}/{APP}",
                        f"%{{_datadir}}/applications/{APP}.desktop",
                        "%{_datadir}/icons/hicolor/")
    for line in files_sec.splitlines():
        line = line.strip()
        if not line or line.startswith(("%", "#")):
            continue
        if line.startswith(allowed_prefixes):
            print(f"ok:   %files {line}")
        else:
            print(f"FAIL: %files entry outside allowed locations: {line}")
            failures.append(line)

    if failures:
        print("RESULT: HARBOUR COMPLIANCE CHECK FAILED")
        sys.exit(1)
    print("RESULT: all static Harbour compliance checks passed")


if __name__ == "__main__":
    main()
