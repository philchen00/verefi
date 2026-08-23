#!/usr/bin/env bash
#
# Self-test for scripts/check-invariants.sh.
#
# A checker that only ever runs green is indistinguishable from one that checks
# nothing — the same false-comfort failure the invariants themselves exist to
# prevent. So every negative case here asserts the SPECIFIC invariant id that
# must fail, not merely a non-zero exit: a test that passes for the wrong reason
# is worse than no test.
#
# Fixtures are mutated in a scratch dir; the committed fixtures are never
# modified. Each mutation is chosen to fail exactly one invariant where
# possible, so a failure names its own cause.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$REPO_ROOT/scripts/check-invariants.sh"
FIXTURES="$REPO_ROOT/scripts/tests/fixtures"

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT

TESTS_RUN=0
TESTS_FAILED=0

ok()   { printf '  ok   %s\n' "$1"; }
notok() { printf '  NOT OK  %s\n     %s\n' "$1" "$2"; TESTS_FAILED=$((TESTS_FAILED + 1)); }

# Replace the Nth occurrence of a line matching a pattern.
nth_replace() {
  local file="$1" pattern="$2" replacement="$3" n="$4"
  awk -v pat="$pattern" -v rep="$replacement" -v target="$n" '
    $0 ~ pat { count++; if (count == target) { print rep; next } }
    { print }
  ' "$file"
}

expect_pass() {
  local name="$1"; shift
  TESTS_RUN=$((TESTS_RUN + 1))
  local out status
  set +e
  out="$("$CHECKER" "$@" 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    ok "$name"
  else
    notok "$name" "expected exit 0, got $status: $(printf '%s' "$out" | grep '^\[FAIL\]' | tr '\n' ' ')"
  fi
}

expect_fail() {
  local name="$1" invariant="$2"; shift 2
  TESTS_RUN=$((TESTS_RUN + 1))
  local out status
  set +e
  out="$("$CHECKER" "$@" 2>&1)"
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    notok "$name" "expected $invariant to fail, but everything passed"
  elif printf '%s' "$out" | grep -q "^\[FAIL\] $invariant"; then
    ok "$name"
  else
    notok "$name" "expected $invariant to fail; actual failures: $(printf '%s' "$out" | grep '^\[FAIL\]' | sed 's/^\[FAIL\] *//' | cut -d' ' -f1 | tr '\n' ' ')"
  fi
}

echo "Positive cases"
expect_pass "well-formed tiered plan passes" --plan "$FIXTURES/plan-tiered.md"
expect_pass "untiered plan passes (tier checks skip)" --plan "$FIXTURES/plan-untiered.md"
expect_pass "tiered plan + matching spec passes" \
  --plan "$FIXTURES/plan-tiered.md" --spec "$FIXTURES/good.spec.ts"

echo
echo "Review-tier invariants (N6)"

# INV-T01 — a duplicated tier line means an edit added a classification without
# replacing the old one.
awk '/^\*\*Review tier:\*\* Auto-cleared/ && !seen { print; print; seen = 1; next } { print }' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/dup-tier.md"
expect_fail "duplicate tier line on one case" "INV-T01" --plan "$SCRATCH/dup-tier.md"

# INV-T02 — a P1 case may never be auto-cleared, however good its evidence.
sed 's/^\*\*Priority:\*\* P2 — guardrail/**Priority:** P1 — guardrail/' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/auto-p1.md"
expect_fail "P1 case marked Auto-cleared" "INV-T02" --plan "$SCRATCH/auto-p1.md"

# INV-T03 — the condition protecting the pre-existing non-read-only approval
# rule. This is the case the original two-axis design would have let through.
nth_replace "$FIXTURES/plan-tiered.md" '^[*][*]Data impact:[*][*] Read-only' \
  '**Data impact:** Creates isolated test data — cleaned up on teardown' 3 \
  > "$SCRATCH/auto-mutating.md"
expect_fail "mutating case marked Auto-cleared" "INV-T03" --plan "$SCRATCH/auto-mutating.md"

# INV-T04 — a classification with no stated reason is an assertion, not an audit
# trail.
nth_replace "$FIXTURES/plan-tiered.md" '^[*][*]Review tier:[*][*] Auto-cleared' \
  '**Review tier:** Auto-cleared' 1 > "$SCRATCH/no-reason.md"
expect_fail "tier with no stated reason" "INV-T04" --plan "$SCRATCH/no-reason.md"

# INV-T05 — header counts drifting from the per-case tally.
sed 's/^\*\*Review triage\*\*: 2 auto-cleared/**Review triage**: 3 auto-cleared/' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/count-mismatch.md"
expect_fail "triage header count mismatch" "INV-T05" --plan "$SCRATCH/count-mismatch.md"

echo
echo "Approval-gate invariants"

# INV-T06 — an approved, tiered plan with flagged cases whose approval does not
# acknowledge them. This is the shape an agent produces when it formats the
# approval field to match a new template.
sed 's/^\*\*Human approval\*\*: .*/**Human approval**: Approved by Fixture Tester on 2026-08-23/' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/unacknowledged.md"
expect_fail "flagged cases unacknowledged by the approval" "INV-T06" --plan "$SCRATCH/unacknowledged.md"

# INV-T06 — approval count contradicting the plan's own tiers.
sed 's/reviewed 1 flagged case(s)/reviewed 5 flagged case(s)/' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/wrong-ack-count.md"
expect_fail "approval acknowledges the wrong number of flagged cases" "INV-T06" \
  --plan "$SCRATCH/wrong-ack-count.md"

# INV-T06 positive — an approval that predates a retroactive triage is stronger,
# not weaker: it covered every case at full scrutiny.
sed -e 's/^\*\*Human approval\*\*: .*/**Human approval**: Approved by Fixture Tester on 2026-08-21/' \
    -e 's/^\*\*Review triage\*\*: \(.*\)$/**Review triage**: \1. Applied retroactively on 2026-08-23./' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/retroactive-ok.md"
expect_pass "approval predating a retroactive triage is accepted" --plan "$SCRATCH/retroactive-ok.md"

# INV-T06 — "retroactive" claimed with a computation date BEFORE the approval
# date is not retroactive at all; the tiers existed when the human approved and
# should have been acknowledged.
sed -e 's/^\*\*Human approval\*\*: .*/**Human approval**: Approved by Fixture Tester on 2026-08-23/' \
    -e 's/^\*\*Review triage\*\*: \(.*\)$/**Review triage**: \1. Applied retroactively on 2026-08-21./' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/retroactive-bad-order.md"
expect_fail "retroactive claim with a pre-approval date is rejected" "INV-T06" \
  --plan "$SCRATCH/retroactive-bad-order.md"

echo
echo "Approval-field integrity across a stage"

expect_pass "unchanged approval fields pass" \
  --plan "$FIXTURES/plan-tiered.md" --approval-baseline "$FIXTURES/plan-tiered.md"

# The exact regression this check exists for: a stage rewrites the human
# approval line to add triage counts. The counts are CORRECT, so every static
# invariant still passes — only the before/after diff catches it.
expect_fail "a stage adding counts to the approval line is caught" "INV-A01" \
  --plan "$FIXTURES/plan-tiered.md" --approval-baseline "$SCRATCH/unacknowledged.md"

# Sanity: that same tampered plan passes every static check, which is why
# INV-A01 cannot be replaced by one.
expect_pass "the tampered plan passes all static checks (why INV-A01 is needed)" \
  --plan "$FIXTURES/plan-tiered.md"

echo
echo "Approved-plan hygiene"

sed 's/^- \*\*Selector strategy:\*\*.*/- **Selector strategy:** TODO(SELECTOR): confirm with discover/' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/todo.md"
expect_fail "approved plan with an unresolved TODO" "INV-P01" --plan "$SCRATCH/todo.md"

awk '/^## Section 3 — Open Questions/{print; print ""; print "- Which account should the checkout case use?"; skip=1; next}
     skip && /^None$/ {skip=0; next}
     {print}' "$FIXTURES/plan-tiered.md" > "$SCRATCH/open-questions.md"
expect_fail "approved plan with unresolved Open Questions" "INV-P02" --plan "$SCRATCH/open-questions.md"

sed 's/^\*\*Priority:\*\* P3 — low-cost extra coverage//' \
  "$FIXTURES/plan-tiered.md" > "$SCRATCH/no-priority.md"
expect_fail "test case with no declared priority" "INV-P00" --plan "$SCRATCH/no-priority.md"

echo
echo "Generated-spec invariants"

sed 's/TC-002: verified low-priority read-only case/verified low-priority read-only case/' \
  "$FIXTURES/good.spec.ts" > "$SCRATCH/no-tc-id.spec.ts"
expect_fail "test title with no TC id" "INV-S01" \
  --plan "$FIXTURES/plan-tiered.md" --spec "$SCRATCH/no-tc-id.spec.ts"

grep -v 'TC-002' "$FIXTURES/good.spec.ts" | grep -v "getByTestId('error')" > "$SCRATCH/uncovered.spec.ts"
expect_fail "plan case with no test in the spec" "INV-S02" \
  --plan "$FIXTURES/plan-tiered.md" --spec "$SCRATCH/uncovered.spec.ts"

sed 's/TC-003a/TC-099a/' "$FIXTURES/good.spec.ts" > "$SCRATCH/invented.spec.ts"
expect_fail "spec test referencing a TC id not in the plan" "INV-S03" \
  --plan "$FIXTURES/plan-tiered.md" --spec "$SCRATCH/invented.spec.ts"

sed "s/  test('TC-001/  test.fail();\n  test('TC-001/" "$FIXTURES/good.spec.ts" > "$SCRATCH/testfail.spec.ts"
expect_fail "spec using test.fail() to hide a known-bug failure" "INV-S04" \
  --plan "$FIXTURES/plan-tiered.md" --spec "$SCRATCH/testfail.spec.ts"

mkdir -p "$SCRATCH/pageObj-bad" "$SCRATCH/pageObj-good"
cp "$FIXTURES/good.spec.ts" "$SCRATCH/pageObj-bad/LoginPage.spec.ts"
printf 'export class LoginPage {}\n' > "$SCRATCH/pageObj-good/LoginPage.ts"
expect_pass "well-named page objects pass" \
  --plan "$FIXTURES/plan-tiered.md" --pageobj-dir "$SCRATCH/pageObj-good"
expect_fail "page object named like a test file" "INV-S05" \
  --plan "$FIXTURES/plan-tiered.md" --pageobj-dir "$SCRATCH/pageObj-bad"

echo
if [ "$TESTS_FAILED" -eq 0 ]; then
  echo "All $TESTS_RUN invariant self-tests passed."
  exit 0
fi
echo "$TESTS_FAILED of $TESTS_RUN invariant self-tests FAILED."
exit 1
