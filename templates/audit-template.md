<!--
Formatting rules (apply when filling this template):
- Use the Markdown headings exactly as they appear here — do not add, remove, or change heading levels.
- Keep one blank line between sections.
- Every inventory row must cite the file (and line where practical) the evidence came from —
  this is a static scan, so "evidence" means it appears in source, not that it was seen live.
- Never pad the inventory with selectors you expect to exist; only what the scan actually found.
- Create this template only after confirming accessible local application source exists. No local source is a
  precondition failure, not a Bare grade.
-->

# Audit: [APP/REPO NAME]

**Run**: `[run-name]`
**Audited**: [DATE]
**Source status**: Local application source scanned at `[path]`
**Scanned**: [what was scanned, e.g. `src/**/*.tsx` — and anything deliberately excluded]
**Testability grade**: [Instrumented | Partially instrumented | Bare]
**Test ID attribute**: [the dominant attribute name actually found, e.g. `data-testid`, `data-test`, `data-cy` — or "Mixed — see Section 4" if more than one convention is genuinely in use, or "None found"]

## Section 1 — Selector Inventory

Stable selectors found in source, grouped by page/feature area, then component/file. One row per distinct selector.

### [Page or Feature Area]

| Component / File | Kind | Value | Playwright locator |
|---|---|---|---|
| `[src/components/SearchBar.tsx]` | [data-testid / data-test / data-cy / testID / aria-label / semantic role] | `[value]` | `getByTestId('[value]')` if the Kind is literally `data-testid` (or `playwright.config.ts` already sets `testIdAttribute` to match) — otherwise `page.locator('[<attribute>="[value]"]')` |

<!-- Repeat the area block above for each area with findings. -->

## Section 2 — Coverage Summary

- **Counts**: [N] `data-testid`/`testID` · [N] `aria-label` · [N] semantic elements/roles (`<button>`, `role=...`) · [N] existing `getBy*` usages in tests
- **Well-instrumented areas**: [list, or "None"]
- **Bare areas — fallback available**: [interactive UI with no test-id but real semantic markup (a role/accessible name), so `getByRole()`/`getByLabel()` resolves it — list, or "None"]
- **Bare areas — no fallback**: [interactive UI with no test-id AND no role/accessible name — nothing a locator can reliably address, especially undistinguished repeated rows — list, or "None"]

## Section 3 — Instrumentation Recommendations

Top components to instrument first, ordered by how much of the test plan they block — **no-fallback** items outrank fallback-available ones regardless of list order above, since those are the ones actually blocking automation rather than just weakening it. Write "None needed" if the app is fully instrumented.

- [`[Component/file]` — no-fallback or fallback-available — why it matters (which TC-### / flows depend on it), suggested `data-testid` values]

## Section 4 — Notes for Discover / Implement

- [Anything the next stages should know: selector naming conventions the codebase already follows, dynamically generated testids (template literals — the static value won't match the DOM literally), component-library wrappers that swallow attributes, or "None"]
