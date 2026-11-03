#!/bin/sh
# SPDX-License-Identifier: AGPL-3.0-or-later
# Thin wrapper around the Python compliance checker.
# Usage: scripts/check-harbour-compliance.sh [validator-repo-dir]
exec python3 "$(dirname "$0")/check_harbour_compliance.py" "$@"
