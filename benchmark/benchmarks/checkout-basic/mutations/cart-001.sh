#!/usr/bin/env bash
# CART-001 — changing quantity persists but never refreshes the subtotal.
# Expect: at least one generated test asserting REQ-CART-002 must fail.
set -euo pipefail
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
APP_DIR="$(resolve_app_dir "${1:-}")"

# Persist the new quantity, then return before the re-render. Anchored on a
# line that appears exactly once, so this does not depend on the ordering of
# renderCart() call sites.
replace_nth "$APP_DIR/app.js" \
  'current[slug] = next;' \
  'current[slug] = next; writeCart(current); return;' \
  1 1

echo "MUTATION_APPLIED=CART-001"
