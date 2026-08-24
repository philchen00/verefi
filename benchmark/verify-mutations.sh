#!/usr/bin/env bash
#
# Verifies every benchmark mutation still applies cleanly to its application.
#
# Cheap (no model calls, no browser) and worth running in CI, because the
# failure it prevents is expensive and misleading: if the app drifts away from
# a mutation's anchor, that mutation silently patches nothing, every generated
# test passes, and the scorecard reports "defect not detected" — blaming Verefi
# for a harness bug.
#
# This does not verify that a mutation is OBSERVABLE in the browser, only that
# it applies and changes the source. Observability was confirmed by hand when
# each mutation was written; a future runner should confirm it per run by
# checking the generated suite actually fails.

set -euo pipefail

BENCH_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0
CHECKED=0

for manifest in "$BENCH_ROOT"/benchmarks/*/benchmark.yaml; do
  case_dir="$(dirname "$manifest")"
  case_id="$(basename "$case_dir")"
  app_dir="$case_dir/app"

  if [ ! -d "$app_dir" ]; then
    echo "[FAIL] $case_id: no app/ directory"
    FAILED=1
    continue
  fi

  echo "$case_id"

  for mutation in "$case_dir"/mutations/*.sh; do
    name="$(basename "$mutation" .sh)"
    [ "$name" = "lib" ] && continue
    CHECKED=$((CHECKED + 1))

    scratch="$(mktemp -d)"
    cp -R "$app_dir/." "$scratch/"

    if ! output="$("$mutation" "$scratch" 2>&1)"; then
      echo "  [FAIL] $name did not apply:"
      printf '%s\n' "$output" | sed 's/^/         /'
      FAILED=1
      rm -rf "$scratch"
      continue
    fi

    if diff -rq "$app_dir" "$scratch" >/dev/null 2>&1; then
      echo "  [FAIL] $name reported success but changed nothing"
      FAILED=1
    else
      echo "  [ok]   $name"
    fi

    rm -rf "$scratch"
  done
done

echo
if [ "$FAILED" -eq 0 ]; then
  echo "All $CHECKED mutation(s) apply cleanly."
  exit 0
fi
echo "Mutation verification FAILED."
exit 1
