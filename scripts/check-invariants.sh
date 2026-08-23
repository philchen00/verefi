#!/usr/bin/env bash
#
# Structural invariant checks for Verefi's own generated artifacts.
#
# Verefi is a skill: its "code" is markdown interpreted by an LLM, so the same
# instructions legitimately produce different concrete output run to run. That
# makes a golden-file diff the wrong tool — it flags different-but-equally-valid
# wording as a regression, which is the false-positive signal that trains people
# to ignore the check.
#
# These invariants are the opposite: properties that must hold for ANY correct
# run, regardless of wording, ordering, or which valid selector was chosen. They
# are the mechanical layer of the evaluation strategy in
# feedback/testclaudeskill-feature-draft.md; LLM-as-judge grading of the
# genuinely subjective parts is left to `claude plugin eval` (still early access
# on this account as of 2026-08-23), deliberately not reimplemented here.
#
# Usage:
#   scripts/check-invariants.sh --plan <test-plan.md> [--spec <file.spec.ts>] [--pageobj-dir <dir>]
#
# Exit codes: 0 all applicable invariants hold; 1 at least one failed; 2 usage error.

set -euo pipefail

PLAN=""
SPEC=""
PAGEOBJ_DIR=""
APPROVAL_BASELINE=""

usage() {
  cat >&2 <<'EOF'
Usage: scripts/check-invariants.sh --plan <test-plan.md> [options]

  --plan                test-plan.md to check (required)
  --spec                generated Playwright spec file to cross-check against the plan
  --pageobj-dir         directory of generated page-object classes
  --approval-baseline   copy of the same plan taken BEFORE a skill stage ran;
                        asserts no skill altered the human approval fields

Checks that need an artifact you did not pass are reported as SKIP, not PASS.
EOF
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --plan) PLAN="${2:-}"; shift 2 || usage ;;
    --spec) SPEC="${2:-}"; shift 2 || usage ;;
    --pageobj-dir) PAGEOBJ_DIR="${2:-}"; shift 2 || usage ;;
    --approval-baseline) APPROVAL_BASELINE="${2:-}"; shift 2 || usage ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

[ -n "$PLAN" ] || usage
[ -f "$PLAN" ] || { echo "Plan not found: $PLAN" >&2; exit 2; }

FAILED=0
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() { printf '[PASS] %-9s %s\n' "$1" "$2"; PASS_COUNT=$((PASS_COUNT + 1)); }
skip() { printf '[SKIP] %-9s %s\n' "$1" "$2"; SKIP_COUNT=$((SKIP_COUNT + 1)); }
fail() {
  printf '[FAIL] %-9s %s\n' "$1" "$2"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAILED=1
}

# ---------------------------------------------------------------------------
# Extract one record per test case: id, priority, read-only?, tier kind,
# tier-line count, has-reason?
# ---------------------------------------------------------------------------
extract_cases() {
  awk '
    function emit() {
      if (id == "") return
      printf "%s\t%s\t%s\t%s\t%d\t%s\n", id, pri, ro, tier, tiercount, reason
    }
    /^### TC-/ {
      emit()
      id = $0; sub(/^### /, "", id); sub(/:.*$/, "", id)
      pri = "none"; ro = "unknown"; tier = "none"; tiercount = 0; reason = "no"
      next
    }
    /^\*\*Priority:\*\*/ {
      if (match($0, /P[123]/)) pri = substr($0, RSTART, RLENGTH)
      next
    }
    /^\*\*Data impact:\*\*/ {
      rest = $0; sub(/^\*\*Data impact:\*\* */, "", rest)
      ro = (rest ~ /^Read-only/) ? "yes" : "no"
      next
    }
    /^\*\*Review tier:\*\*/ {
      tiercount++
      rest = $0; sub(/^\*\*Review tier:\*\* */, "", rest)
      if (rest ~ /^Auto-cleared/) tier = "auto"
      else if (rest ~ /^Needs review/) tier = "needs"
      else if (rest ~ /^Unclassified/) tier = "unclassified"
      else tier = "unknown"
      # A reason is required for a real classification: an em-dash followed by text.
      if (rest ~ /—[[:space:]]*[^[:space:]]/) reason = "yes"
      next
    }
    END { emit() }
  ' "$1"
}

CASES="$(extract_cases "$PLAN")"
TOTAL_CASES=$(printf '%s' "$CASES" | grep -c . || true)

if [ "$TOTAL_CASES" -eq 0 ]; then
  echo "No '### TC-' blocks found in $PLAN — is this a test plan?" >&2
  exit 2
fi

echo "Plan: $PLAN ($TOTAL_CASES test cases)"
echo

# ---------------------------------------------------------------------------
# Plan structure
# ---------------------------------------------------------------------------
missing_priority=$(printf '%s\n' "$CASES" | awk -F'\t' '$2 == "none" { print $1 }' | paste -sd, -)
if [ -z "$missing_priority" ]; then
  pass "INV-P00" "every test case declares a priority ($TOTAL_CASES/$TOTAL_CASES)"
else
  fail "INV-P00" "test case(s) with no P1/P2/P3 priority: $missing_priority"
fi

# ---------------------------------------------------------------------------
# Review tiers (N6). Skipped wholesale on an untiered plan — tiering is not
# retroactively required, and implement's Step 0 falls back to the full-plan
# gate for plans that predate it.
# ---------------------------------------------------------------------------
TIERED_CASES=$(printf '%s\n' "$CASES" | awk -F'\t' '$5 > 0' | grep -c . || true)

if [ "$TIERED_CASES" -eq 0 ]; then
  skip "INV-T01" "plan carries no Review tier fields (untiered plan — tier checks not applicable)"
  skip "INV-T02" "plan is not tiered"
  skip "INV-T03" "plan is not tiered"
  skip "INV-T04" "plan is not tiered"
  skip "INV-T05" "plan is not tiered"
  skip "INV-T06" "plan is not tiered"
else
  # INV-T01 — exactly one tier line per case. Zero means a case slipped through
  # classification; more than one means an edit added a tier without replacing.
  bad_count=$(printf '%s\n' "$CASES" | awk -F'\t' '$5 != 1 { printf "%s(%d) ", $1, $5 }')
  if [ -z "$bad_count" ]; then
    pass "INV-T01" "every test case carries exactly one Review tier line ($TOTAL_CASES/$TOTAL_CASES)"
  else
    fail "INV-T01" "test case(s) without exactly one Review tier line: $bad_count"
  fi

  # INV-T02 — no Auto-cleared case is P1.
  bad_p1=$(printf '%s\n' "$CASES" | awk -F'\t' '$4 == "auto" && $2 == "P1" { print $1 }' | paste -sd, -)
  if [ -z "$bad_p1" ]; then
    pass "INV-T02" "no Auto-cleared case is P1"
  else
    fail "INV-T02" "P1 case(s) marked Auto-cleared: $bad_p1"
  fi

  # INV-T03 — no Auto-cleared case mutates state. This is the condition that
  # protects the pre-existing rule requiring explicit human approval for any
  # non-read-only data impact.
  bad_ro=$(printf '%s\n' "$CASES" | awk -F'\t' '$4 == "auto" && $3 != "yes" { print $1 }' | paste -sd, -)
  if [ -z "$bad_ro" ]; then
    pass "INV-T03" "no Auto-cleared case has a non-read-only data impact"
  else
    fail "INV-T03" "non-read-only case(s) marked Auto-cleared: $bad_ro"
  fi

  # INV-T04 — every classification states a reason, so triage is auditable
  # rather than asserted.
  bad_reason=$(printf '%s\n' "$CASES" | awk -F'\t' '($4 == "auto" || $4 == "needs") && $6 != "yes" { print $1 }' | paste -sd, -)
  if [ -z "$bad_reason" ]; then
    pass "INV-T04" "every tier classification states a reason"
  else
    fail "INV-T04" "tier(s) with no stated reason: $bad_reason"
  fi

  # INV-T05 — header triage counts match the per-case tally.
  auto_n=$(printf '%s\n' "$CASES" | awk -F'\t' '$4 == "auto"' | grep -c . || true)
  needs_n=$(printf '%s\n' "$CASES" | awk -F'\t' '$4 == "needs"' | grep -c . || true)
  triage_line=$(grep -m1 '^\*\*Review triage\*\*:' "$PLAN" || true)
  if [ -z "$triage_line" ]; then
    fail "INV-T05" "plan has tier fields but no '**Review triage**:' header line"
  elif printf '%s' "$triage_line" | grep -q 'Pending'; then
    if [ "$auto_n" -eq 0 ] && [ "$needs_n" -eq 0 ]; then
      pass "INV-T05" "triage header is Pending and no case is classified yet"
    else
      fail "INV-T05" "triage header still says Pending but $auto_n case(s) are classified"
    fi
  else
    claimed_auto=$(printf '%s' "$triage_line" | grep -oE '[0-9]+ auto-cleared' | grep -oE '[0-9]+' | head -1 || true)
    claimed_needs=$(printf '%s' "$triage_line" | grep -oE '[0-9]+ flagged' | grep -oE '[0-9]+' | head -1 || true)
    if [ "${claimed_auto:-x}" = "$auto_n" ] && [ "${claimed_needs:-x}" = "$needs_n" ]; then
      pass "INV-T05" "triage header counts match the per-case tally ($auto_n auto-cleared, $needs_n flagged)"
    else
      fail "INV-T05" "triage header claims ${claimed_auto:-?} auto-cleared/${claimed_needs:-?} flagged; cases tally $auto_n/$needs_n"
    fi
  fi

  # INV-T06 — an approved, tiered plan with flagged cases must carry an
  # approval that acknowledges them, OR declare its triage retroactive with a
  # computation date after the approval date (an approval predating tiering
  # covered the whole plan at full scrutiny, which is strictly more review).
  status_approved=$(grep -cE '^\*\*Status\*\*: *Approved' "$PLAN" || true)
  if [ "$status_approved" -eq 0 ]; then
    skip "INV-T06" "plan is not marked Approved"
  elif [ "$needs_n" -eq 0 ]; then
    pass "INV-T06" "approved plan has no flagged cases to acknowledge"
  else
    approval_line=$(grep -m1 '^\*\*Human approval\*\*:' "$PLAN" || true)
    if printf '%s' "$approval_line" | grep -qE 'reviewed [0-9]+ flagged'; then
      ack_n=$(printf '%s' "$approval_line" | grep -oE 'reviewed [0-9]+ flagged' | grep -oE '[0-9]+' | head -1)
      if [ "$ack_n" = "$needs_n" ]; then
        pass "INV-T06" "approval acknowledges all $needs_n flagged case(s)"
      else
        fail "INV-T06" "approval claims $ack_n flagged reviewed; plan marks $needs_n"
      fi
    else
      approval_date=$(printf '%s' "$approval_line" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
      retro_date=$(printf '%s' "$triage_line" | grep -oiE 'retroactively on [0-9]{4}-[0-9]{2}-[0-9]{2}' | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)
      if [ -n "$retro_date" ] && [ -n "$approval_date" ] && [[ "$retro_date" > "$approval_date" ]]; then
        pass "INV-T06" "approval predates a retroactive triage ($approval_date < $retro_date) — full-plan approval stands"
      else
        fail "INV-T06" "approved plan has $needs_n flagged case(s) but the approval neither acknowledges them nor declares a later retroactive triage"
      fi
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Approved-plan hygiene
# ---------------------------------------------------------------------------
status_approved=$(grep -cE '^\*\*Status\*\*: *Approved' "$PLAN" || true)
if [ "$status_approved" -eq 0 ]; then
  skip "INV-P01" "plan is not marked Approved"
  skip "INV-P02" "plan is not marked Approved"
else
  todo_n=$(grep -c 'TODO(' "$PLAN" || true)
  if [ "$todo_n" -eq 0 ]; then
    pass "INV-P01" "approved plan has no unresolved TODO(...) markers"
  else
    fail "INV-P01" "approved plan still has $todo_n TODO(...) marker(s)"
  fi

  open_q=$(awk '/^## Section 3 — Open Questions/{f=1; next} /^## /{f=0} f' "$PLAN" | grep -v '^_' | grep -v '^$' | head -5)
  if printf '%s' "$open_q" | grep -qx 'None'; then
    pass "INV-P02" "approved plan's Open Questions section is None"
  else
    fail "INV-P02" "approved plan's Open Questions section is not None"
  fi
fi

# ---------------------------------------------------------------------------
# Generated spec cross-checks
# ---------------------------------------------------------------------------
if [ -z "$SPEC" ]; then
  skip "INV-S01" "no --spec supplied"
  skip "INV-S02" "no --spec supplied"
  skip "INV-S03" "no --spec supplied"
elif [ ! -f "$SPEC" ]; then
  fail "INV-S01" "spec not found: $SPEC"
else
  plan_ids=$(printf '%s\n' "$CASES" | cut -f1 | sort -u)
  # One plan case may legitimately split into several tests (TC-004a/b/c), so
  # compare on the numeric id, never on test count.
  spec_ids=$(grep -oE "TC-[0-9]+" "$SPEC" | sort -u || true)

  untitled=$(grep -oE "^[[:space:]]*test\((['\"])[^'\"]*" "$SPEC" | grep -vE "TC-[0-9]+" | head -5 || true)
  if [ -z "$untitled" ]; then
    pass "INV-S01" "every test title carries a TC id"
  else
    fail "INV-S01" "test(s) with no TC id in the title: $(printf '%s' "$untitled" | tr '\n' ' ')"
  fi

  uncovered=$(comm -23 <(printf '%s\n' "$plan_ids") <(printf '%s\n' "$spec_ids") | paste -sd, -)
  if [ -z "$uncovered" ]; then
    pass "INV-S02" "every plan test case appears in the spec"
  else
    fail "INV-S02" "plan case(s) with no test in the spec: $uncovered"
  fi

  invented=$(comm -13 <(printf '%s\n' "$plan_ids") <(printf '%s\n' "$spec_ids") | paste -sd, -)
  if [ -z "$invented" ]; then
    pass "INV-S03" "every spec test traces back to a plan test case"
  else
    fail "INV-S03" "spec test(s) referencing a TC id not in the plan: $invented"
  fi

  # INV-S04 — test.fail() is explicitly rejected by implement Step 1c: default
  # reporters roll expected-failures into the "passed" count, which is the exact
  # false-comfort outcome the known-bug rule exists to prevent.
  if grep -qE '(^|[^.[:alnum:]])test\.fail\(' "$SPEC"; then
    fail "INV-S04" "spec uses test.fail(), which hides a known-bug failure in the passed count"
  else
    pass "INV-S04" "spec does not use test.fail()"
  fi
fi

# ---------------------------------------------------------------------------
# Approval-field integrity across a skill stage.
#
# This is the one invariant that cannot be checked statically, and the reason
# the harness needs a before/after pair at all: an agent that fills in the human
# approval field produces a plan whose counts are CORRECT and which therefore
# satisfies every static check above. "Accurate" is not the property that field
# carries — "a person asserted this" is, and only a diff across the stage can
# tell the difference. Discovered the hard way: an agent did exactly this while
# implementing the tiering feature, and only a human reading the line caught it.
# ---------------------------------------------------------------------------
approval_fields() {
  grep -E '^\*\*(Status|Human approval)\*\*:' "$1" || true
}

if [ -z "$APPROVAL_BASELINE" ]; then
  skip "INV-A01" "no --approval-baseline supplied (cannot verify no skill wrote the approval)"
elif [ ! -f "$APPROVAL_BASELINE" ]; then
  fail "INV-A01" "approval baseline not found: $APPROVAL_BASELINE"
elif [ "$(approval_fields "$APPROVAL_BASELINE")" = "$(approval_fields "$PLAN")" ]; then
  pass "INV-A01" "human approval fields are byte-identical to the baseline"
else
  fail "INV-A01" "a skill stage altered the human approval fields — only a human may write these"
  diff <(approval_fields "$APPROVAL_BASELINE") <(approval_fields "$PLAN") | sed 's/^/           /' || true
fi

if [ -z "$PAGEOBJ_DIR" ]; then
  skip "INV-S05" "no --pageobj-dir supplied"
elif [ ! -d "$PAGEOBJ_DIR" ]; then
  fail "INV-S05" "page-object directory not found: $PAGEOBJ_DIR"
else
  # A page object named *.spec.ts is picked up by Playwright's default testMatch
  # as an empty test file.
  bad_po=$(find "$PAGEOBJ_DIR" -type f \( -name '*.spec.ts' -o -name '*.test.ts' \) | paste -sd, -)
  if [ -z "$bad_po" ]; then
    pass "INV-S05" "no page-object file is named like a test file"
  else
    fail "INV-S05" "page-object file(s) the test runner would collect as tests: $bad_po"
  fi
fi

echo
echo "$PASS_COUNT passed, $FAIL_COUNT failed, $SKIP_COUNT skipped"
exit "$FAILED"
