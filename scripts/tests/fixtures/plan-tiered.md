# Test Plan: Invariant Fixture (tiered)

**Run**: `fixture-tiered`
**Created**: 2026-08-23
**Status**: Approved
**Review triage**: 2 auto-cleared, 1 flagged (from discovery.md on 2026-08-23) — see each test case's Review tier
**Human approval**: Approved by Fixture Tester on 2026-08-23 — reviewed 1 flagged case(s); accepted 2 auto-cleared
**Input**: "fixture for scripts/check-invariants.sh"

## Section 1 — Test Cases

### TC-001: Critical flow that must be read by a human

**Type:** Happy Path
**Priority:** P1 — entry point for every other flow
**Data impact:** Read-only
**Review tier:** Needs review — P1

**Given:** a precondition
**When:** an action
**Then:** an expected result

**Acceptance Criteria:**
- [ ] something measurable

### TC-002: Verified low-priority read-only case

**Type:** Negative
**Priority:** P2 — guardrail
**Data impact:** Read-only
**Review tier:** Auto-cleared — all selectors live-verified (discovery.md §1), P2, read-only

**Given:** a precondition
**When:** an action
**Then:** an expected result

**Acceptance Criteria:**
- [ ] something measurable

### TC-003: Another verified low-priority read-only case

**Type:** Edge Case
**Priority:** P3 — low-cost extra coverage
**Data impact:** Read-only
**Review tier:** Auto-cleared — all selectors live-verified (discovery.md §1), P3, read-only

**Given:** a precondition
**When:** an action
**Then:** an expected result

**Acceptance Criteria:**
- [ ] something measurable

## Section 2 — Implementation Notes

- **Selector strategy:** stable test-id attribute > aria-label > role > text
- **Base URL:** `BASE_URL` at runtime; default `http://127.0.0.1:3000`

## Section 3 — Open Questions

None

## Section 4 — Out of Scope

- Anything not listed above
