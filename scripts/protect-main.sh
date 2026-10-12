#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Protects the main branch of Zesseth/Sahkonseuranta.
#
# Branch protection is only available for PUBLIC repositories on the
# GitHub Free plan. This repository is currently private, so run this
# script right after making it public:
#
#   bash scripts/protect-main.sh
#
# The applied policy:
#   - all changes to main go through pull requests
#     (no direct pushes, not even by admins)
#   - no approving reviews are required, so a solo maintainer can
#     merge their own PRs; set required_approving_review_count to 1
#     once additional reviewers exist
#   - stale reviews are dismissed on new pushes
#   - conversations must be resolved before merging
#   - force pushes and branch deletions are blocked

set -euo pipefail

gh api -X PUT repos/Zesseth/Sahkonseuranta/branches/main/protection --input - << 'JSON'
{
  "required_status_checks": null,
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false,
    "required_approving_review_count": 0
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "block_creations": false,
  "lock_branch": false
}
JSON

echo "main branch protection enabled."
