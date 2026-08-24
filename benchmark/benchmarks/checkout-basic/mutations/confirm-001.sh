#!/usr/bin/env bash
# CONFIRM-001 — the confirmation page omits the order id.
# Expect: at least one generated test asserting REQ-CHECKOUT-003 must fail.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
APP_DIR="$(resolve_app_dir "${1:-}")"

replace_nth "$APP_DIR/app.js" \
  "document.querySelector('[data-test=\"order-id\"]').textContent = orderId;" \
  "document.querySelector('[data-test=\"order-id\"]').textContent = '';" \
  1 1

echo "MUTATION_APPLIED=CONFIRM-001"
