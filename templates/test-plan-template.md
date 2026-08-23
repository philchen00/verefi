<!--
Formatting rules (apply when filling this template):
- Use the Markdown headings exactly as they appear here — do not add, remove, or change heading levels.
- Keep one blank line between sections.
- If a value is genuinely unknown, write `TODO(<FIELD_NAME>): <what's needed to resolve it>` rather than guessing.
- Do not leave literal [bracketed] placeholders in the final output — replace every one.
- Do not change the approval fields to an approved value. A human reviewer must do that after reviewing this plan.
- `Review tier` is `Unclassified — pending evidence` at plan-writing time and is filled in later by `audit`/`discover` per `references/review-tiers.md`. Never guess a tier, and never write `Auto-cleared` without an evidence artifact to cite.
- Never include credential values, tokens, customer data, or real account details. Refer only to dedicated test accounts and environment-variable names.
-->

# Test Plan: [FEATURE NAME]

**Run**: `[run-name]`
**Created**: [DATE]
**Status**: Draft
**Review triage**: Pending — no evidence artifact yet; replaced with `<N> auto-cleared, <M> flagged (from <discovery.md|audit.md> on <date>)` once `/verefi:discover` or `/verefi:audit` has run
**Human approval**: Pending — replace with `Approved by <human> on <date> — reviewed <M> flagged case(s); accepted <N> auto-cleared` only after a human has reviewed every flagged test case, the target, and every data-impact note. Auto-cleared cases are read second, not skipped: recording the counts is how the reviewer accepts them.
**Input**: "[original feature description or source file path]"

## Section 1 — Test Cases

<!-- 8–15 test cases covering happy paths, edge cases, and negative scenarios. One block per test case, numbered sequentially. Delete this comment and the TC-001 example below stays as the first real block, renumbered as needed. -->

### TC-001: [Brief Title]

**Type:** Happy Path | Edge Case | Negative
**Priority:** P1 | P2 | P3 — [why this priority: e.g. "blocks the core purchase flow"]
**Data impact:** Read-only | Creates isolated test data | Changes/deletes isolated test data — [name the data/account and cleanup or rollback; require explicit human approval for anything other than read-only]
**Review tier:** Unclassified — pending evidence <!-- Filled in by audit/discover: `Auto-cleared — <why>` or `Needs review — <why>`. Auto-cleared requires evidence-verified AND not P1 AND read-only; see references/review-tiers.md. -->


**Given:** [precondition state of the system]
**When:** [the user action(s) performed]
**Then:** [the expected result(s)]

**Acceptance Criteria:**
- [ ] [measurable criterion 1]
- [ ] [measurable criterion 2]

<!-- Repeat the TC-### block above for each test case. -->

## Section 2 — Implementation Notes

- **Selector strategy:** stable test-id attribute (exact attribute name — `data-testid`, `data-test`, `data-cy`, etc. — TBD until `/verefi:discover` or `/verefi:audit` confirms it) > aria-label > role > text
- **Target safety:** local loopback only by default (`http://127.0.0.1`, `http://localhost`, or `http://[::1]`). For any other hostname, record `Approved remote host: <exact hostname>; approved by: <human>; scope: <read-only or named actions>` — do not infer this from a URL alone. Runtime must require `E2E_ALLOW_REMOTE=<exact hostname>`; never set it in generated code or CI.
- **Base URL:** `BASE_URL` at runtime; default `http://127.0.0.1:3000`. Do not hardcode a remote URL in tests or config.
- **Authentication / credentials:** `None` or dedicated non-production test account via named environment variables (for example, `E2E_USERNAME`, `E2E_PASSWORD`). Never record values.
- **Destructive actions and cleanup:** ["None — read-only" or exact approved actions, isolated test data, and cleanup/rollback plan]
- **Test files to create:** [`<testDir>/<run-name>.spec.ts`, e.g. `tests/e2e/checkout.spec.ts` — TC-001, TC-002]
- **Key fixtures or shared setup:** [any `beforeEach` / global setup needed, or "None"]

**Test Data** (if the test cases reference shared variables):

| Variable | Safe example value | Source / safety notes |
|---|---|---|
| [variable_name] | [fictional/non-sensitive value] | [fixture or environment-variable name; never a secret value] |

## Section 3 — Open Questions

_To answer: edit this file directly, replacing each bullet with your decision (or delete it if it's resolved) — or tell Claude your answer in conversation and ask it to update this file. Either way, this section should read "None" before moving on to `/verefi:implement`; then a human must set `Status` to `Approved` and complete `Human approval`._

- [What's ambiguous and needs product/eng input, or "None"]

## Section 4 — Out of Scope

- [What this test plan explicitly does NOT cover, or "None"]
