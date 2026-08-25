#!/usr/bin/env bash
#
# Computes a stable digest of a test plan's *reviewable content* — the thing a
# human actually signed off on.
#
# Covers Section 1 (test cases, including each case's priority and data impact)
# and Section 2 (implementation notes: target, base URL, credentials,
# destructive actions). Deliberately EXCLUDES `**Review tier:**` lines, so
# re-running audit/discover and re-tiering a plan does not change the digest,
# while editing a test case, a target, or a data-impact note does.
#
# That exclusion is the point: it makes "tier computation was the only change
# since approval" a checkable fact rather than an assertion, which is what the
# retroactive-approval path in references/review-tiers.md depends on.
#
# Scope limit, stated plainly: this detects content drift. It is not a
# signature and does not bind the plan to a particular human — an agent that
# edits a plan can also recompute a digest. It is one layer alongside the rule
# that no skill may write the approval fields, and the INV-A01 before/after
# check that proves it didn't.
#
# Usage: scripts/plan-digest.sh <test-plan.md>

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: scripts/plan-digest.sh <test-plan.md>" >&2
  exit 2
fi

PLAN="$1"

if [ ! -f "$PLAN" ]; then
  echo "Plan not found: $PLAN" >&2
  exit 2
fi

# From the first test case through the end of Section 2, minus tier lines.
# Trailing whitespace is normalized so a stray space can't change the digest.
content="$(
  awk '
    /^## Section 3/ { inplan = 0 }
    /^### TC-/     { inplan = 1 }
    inplan && !/^\*\*Review tier:\*\*/ { print }
  ' "$PLAN" | sed 's/[[:space:]]*$//'
)"

if [ -z "$content" ]; then
  echo "No test-case content found in $PLAN — is this a test plan?" >&2
  exit 2
fi

if command -v sha256sum >/dev/null 2>&1; then
  printf '%s\n' "$content" | sha256sum | cut -c1-16
else
  printf '%s\n' "$content" | shasum -a 256 | cut -c1-16
fi
