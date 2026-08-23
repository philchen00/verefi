# Test Plan: Invariant Fixture (untiered, predates N6)

**Run**: `fixture-untiered`
**Created**: 2026-08-20
**Status**: Approved
**Human approval**: Approved by Fixture Tester on 2026-08-20
**Input**: "fixture for scripts/check-invariants.sh"

## Section 1 — Test Cases

### TC-001: Critical flow

**Type:** Happy Path
**Priority:** P1 — entry point for every other flow
**Data impact:** Read-only

**Given:** a precondition
**When:** an action
**Then:** an expected result

**Acceptance Criteria:**
- [ ] something measurable

### TC-002: Mutating case with no tier field

**Type:** Edge Case
**Priority:** P3 — low-cost extra coverage
**Data impact:** Creates isolated test data — cleaned up on teardown

**Given:** a precondition
**When:** an action
**Then:** an expected result

**Acceptance Criteria:**
- [ ] something measurable

## Section 2 — Implementation Notes

- **Selector strategy:** stable test-id attribute > aria-label > role > text

## Section 3 — Open Questions

None

## Section 4 — Out of Scope

- Anything not listed above
