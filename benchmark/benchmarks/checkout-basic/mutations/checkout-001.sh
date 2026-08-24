#!/usr/bin/env bash
# CHECKOUT-001 — order total omits tax (total = subtotal).
# Expect: at least one generated test asserting REQ-CHECKOUT-001 must fail.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
APP_DIR="$(resolve_app_dir "${1:-}")"

replace_nth "$APP_DIR/app.js" \
  'return Math.round((cartSubtotal() + cartTax()) * 100) / 100;' \
  'return Math.round(cartSubtotal() * 100) / 100;' \
  1 1

echo "MUTATION_APPLIED=CHECKOUT-001"
