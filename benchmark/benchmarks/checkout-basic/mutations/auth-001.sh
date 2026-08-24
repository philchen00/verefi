#!/usr/bin/env bash
# AUTH-001 — the route guard no longer blocks unauthenticated access.
# Expect: at least one generated test asserting REQ-AUTH-003 must fail.
#
# This mutation doubles as a measurement of the standing-checklist work:
# route-guard coverage appeared in only 1 of 6 runs in the rubric experiment,
# so a low detection rate here is a coverage finding, not just a defect.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
APP_DIR="$(resolve_app_dir "${1:-}")"

replace_nth "$APP_DIR/app.js" \
  'if (!isAuthed()) {' \
  'if (false) {' \
  1 1

echo "MUTATION_APPLIED=AUTH-001"
