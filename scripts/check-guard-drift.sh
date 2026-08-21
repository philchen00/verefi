#!/usr/bin/env bash
#
# The remote-host/credentials safety guard is duplicated between the config
# create-playwright.sh scaffolds into a fresh user project (a heredoc) and
# examples/outputs/playwright.config.ts (a real, checked-in sample of that
# same output). They can't share a single module without shipping a Verefi
# runtime dependency into every generated project, so instead both copies are
# bounded by matching `// VEREFI_GUARD_START` / `// VEREFI_GUARD_END` marker
# comments, and this script fails if the text between those markers ever
# diverges between the two files.

set -euo pipefail

extract_guard() {
  awk '/\/\/ VEREFI_GUARD_START/{flag=1; next} /\/\/ VEREFI_GUARD_END/{flag=0} flag' "$1"
}

SCRIPT_GUARD="$(extract_guard scripts/create-playwright.sh)"
EXAMPLE_GUARD="$(extract_guard examples/outputs/playwright.config.ts)"

if [ -z "$SCRIPT_GUARD" ] || [ -z "$EXAMPLE_GUARD" ]; then
  echo "VEREFI_GUARD_MARKERS_MISSING: could not find a VEREFI_GUARD_START/END block in one or both files." >&2
  exit 2
fi

if [ "$SCRIPT_GUARD" != "$EXAMPLE_GUARD" ]; then
  echo "VEREFI_GUARD_DRIFT: scripts/create-playwright.sh and examples/outputs/playwright.config.ts's guard blocks no longer match." >&2
  echo "--- scripts/create-playwright.sh ---" >&2
  echo "$SCRIPT_GUARD" >&2
  echo "--- examples/outputs/playwright.config.ts ---" >&2
  echo "$EXAMPLE_GUARD" >&2
  diff <(echo "$SCRIPT_GUARD") <(echo "$EXAMPLE_GUARD") >&2 || true
  exit 1
fi

echo "✓ Guard blocks match between scripts/create-playwright.sh and examples/outputs/playwright.config.ts"
