#!/usr/bin/env bash
# CHECKOUT-002 — an invalid card number is accepted.
# Expect: at least one generated test asserting REQ-CHECKOUT-002 must fail.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
APP_DIR="$(resolve_app_dir "${1:-}")"

replace_nth "$APP_DIR/app.js" \
  'if (!/^[0-9]{16}$/.test(card)) {' \
  'if (false) {' \
  1 1

echo "MUTATION_APPLIED=CHECKOUT-002"
