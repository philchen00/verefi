#!/usr/bin/env bash
#
# Shared helper for checkout-basic mutation scripts.
#
# The single most important property here is FAILING LOUDLY. A mutation whose
# anchor no longer matches would silently patch nothing, the generated tests
# would all pass, and the scorecard would report "defect not detected" — blaming
# Verefi for a harness bug. That is precisely the kind of false signal this
# whole benchmark exists to catch, so an unmatched anchor is a hard error
# (exit 3), never a warning.

set -euo pipefail

# replace_nth <file> <literal-anchor> <replacement> <nth> <expected-matching-lines>
#
# Literal matching throughout — no regex — so anchors can contain regex
# metacharacters without escaping.
replace_nth() {
  local file="$1" anchor="$2" replacement="$3" nth="$4" expected="$5"
  local count tmp

  if [ ! -f "$file" ]; then
    echo "MUTATION_TARGET_MISSING: $file" >&2
    exit 3
  fi

  count="$(grep -F -c -- "$anchor" "$file" || true)"
  if [ "$count" -ne "$expected" ]; then
    echo "MUTATION_ANCHOR_ERROR: expected $expected line(s) matching the anchor in $file, found $count." >&2
    echo "  The application changed but the mutation was not updated. Refusing to" >&2
    echo "  produce a run that would look like an undetected defect." >&2
    echo "  anchor: $anchor" >&2
    exit 3
  fi

  tmp="$(mktemp)"
  awk -v anchor="$anchor" -v replacement="$replacement" -v nth="$nth" '
    {
      if (!done) {
        pos = index($0, anchor)
        if (pos > 0) {
          hit++
          if (hit == nth) {
            $0 = substr($0, 1, pos - 1) replacement substr($0, pos + length(anchor))
            done = 1
          }
        }
      }
      print
    }
    END {
      if (!done) { exit 4 }
    }
  ' "$file" > "$tmp" || {
    rm -f "$tmp"
    echo "MUTATION_APPLY_ERROR: anchor matched $count line(s) but occurrence $nth was not replaced in $file" >&2
    exit 3
  }

  mv "$tmp" "$file"
}

# Resolve the app directory: $1 if given, else ../app next to the script.
resolve_app_dir() {
  local given="${1:-}"
  if [ -n "$given" ]; then
    printf '%s\n' "$given"
  else
    printf '%s\n' "$(cd "$(dirname "${BASH_SOURCE[1]}")/../app" && pwd)"
  fi
}
