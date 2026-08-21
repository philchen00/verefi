<!--
Formatting rules (apply when filling this template):
- Use the Markdown headings exactly as they appear here — do not add, remove, or change heading levels.
- Keep one blank line between sections.
- Only record selectors you actually verified with agent-browser — never guess a value to fill a row.
- If a test case's element genuinely could not be found, put it under Section 2 (Gaps), not Section 1.
- Never copy a selector, string, or value from a PRD/spec's example code straight into Section 1 —
  verify it against the live app first. If it doesn't match, that's a Section 2 gap, not a Section 1 row.
- Never write `getByTestId('value')` unless the header's Test ID attribute is literally `data-testid` —
  Playwright's `getByTestId()` only matches that one attribute by default. For any other attribute name,
  the Selector column must read `page.locator('[<attribute>="value"]')` instead.
-->

# Discovery: Swag Labs login, catalog sort, and checkout

**Run**: `saucedemo-checkout`
**Verified**: 2026-08-15
**Base URL**: `https://www.saucedemo.com`
**Target safety**: Approved non-production remote host `www.saucedemo.com`
**Remote/destructive approval**: Demo Maintainer, 2026-08-15 — approved the public Swag Labs demo login, catalog, cart, and checkout flows only. TC-005 through TC-011 use disposable demo cart/order state; no customer, payment, or fulfillment data is in scope.
**Runtime credentials**: supplied only through `E2E_USERNAME`, `E2E_PASSWORD`, `E2E_LOCKED_OUT_USERNAME`, and `E2E_INVALID_PASSWORD`; values were not recorded in this artifact.
**Roles/Personas covered**: N/A — single role. Dedicated valid and locked-out demo account states were exercised for negative paths, not distinct personas; both use the same login form.
**Test ID attribute**: `data-test` — **not** Playwright's default `data-testid`. Every Section 1 selector is written as `page.locator('[data-test="..."]')`; `getByTestId()` matches nothing here unless `playwright.config.ts` sets `use: { testIdAttribute: 'data-test' }`. See Section 4.

## Section 1 — Verified Selectors

### Login — `/`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-001, TC-002, TC-003 | Username input | `locator('[data-test="username"]')` | — |
| TC-001, TC-002, TC-003 | Password input | `locator('[data-test="password"]')` | — |
| TC-001, TC-002, TC-003 | Login submit | `locator('[data-test="login-button"]')` | `<input type="submit">`, not a `<button>` |
| TC-002, TC-003 | Error message | `locator('[data-test="error"]')` | Confirmed both exact strings with dedicated demo account states, not assumed |

### Product Catalog — `/inventory.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-001 | Page title | `locator('[data-test="title"]')` | Reads "Products" |
| TC-001 | Product card | `locator('[data-test="inventory-item"]')` | 6 present |
| TC-004 | Sort dropdown | `locator('[data-test="product-sort-container"]')` | `<select>`; value `"lohi"` = Price low→high |
| TC-004 | Item price (per card) | `locator('[data-test="inventory-item-price"]')` | Confirmed re-sort produces `$7.99 → $49.99` ascending |
| TC-005, TC-006 | Add-to-cart button | `locator('[data-test="add-to-cart-sauce-labs-backpack"]')` | One `data-test` per product, slugified from the name — not a generic `add-to-cart` selector |
| TC-005, TC-006 | Remove-from-cart button | `locator('[data-test="remove-sauce-labs-backpack"]')` | Replaces the add-to-cart button in place after adding (same DOM position, `data-test` and label both change) |
| TC-005 | Cart badge | `locator('[data-test="shopping-cart-badge"]')` | Element does not exist at all when cart is empty — do not assert on its text being `"0"`, assert on absence |
| TC-007 | Cart link | `locator('[data-test="shopping-cart-link"]')` | — |

### Cart — `/cart.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-007 | Item name | `locator('[data-test="inventory-item-name"]')` | — |
| TC-007 | Item price | `locator('[data-test="inventory-item-price"]')` | — |
| TC-007 | Item quantity | `locator('[data-test="item-quantity"]')` | — |
| TC-007 | Checkout button | `locator('[data-test="checkout"]')` | — |

### Checkout Step One — `/checkout-step-one.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-008, TC-011 | First name input | `locator('[data-test="firstName"]')` | — |
| TC-008, TC-011 | Last name input | `locator('[data-test="lastName"]')` | — |
| TC-008, TC-011 | Postal code input | `locator('[data-test="postalCode"]')` | — |
| TC-008, TC-011 | Continue button | `locator('[data-test="continue"]')` | `<input type="submit">`, not a `<button>` |
| TC-008 | Validation error | `locator('[data-test="error"]')` | Same `data-test` as the login error — confirmed exact string by leaving First Name blank and submitting: `"Error: First Name is required"` |

### Checkout Step Two (Overview) — `/checkout-step-two.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-009, TC-011 | Item subtotal | `locator('[data-test="subtotal-label"]')` | Confirmed text: `"Item total: $29.99"` |
| TC-009, TC-011 | Tax | `locator('[data-test="tax-label"]')` | Confirmed text: `"Tax: $2.40"` (8% of $29.99, rounded) — not assumed, read directly off the live page |
| TC-009, TC-011 | Total | `locator('[data-test="total-label"]')` | Confirmed text: `"Total: $32.39"` |
| TC-010, TC-011 | Finish button | `locator('[data-test="finish"]')` | — |

### Checkout Complete — `/checkout-complete.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-010, TC-011 | Confirmation heading | `locator('[data-test="complete-header"]')` | Confirmed exact text: `"Thank you for your order!"` |
| TC-010, TC-011 | Back-to-products button | `locator('[data-test="back-to-products"]')` | — |

## Section 2 — Gaps

- TC-004 through TC-011, all rows — **Plan wrong** — `test-plan.md`'s Implementation Notes assumed `data-testid` (this pipeline's default selector strategy per `references/playwright.instructions.md`). The live app instruments every element with **`data-test`** instead. Every selector above uses `page.locator('[data-test="..."]')`, not `page.getByTestId(...)` (which defaults to reading `data-testid`). This would have silently produced 0 working selectors if `implement` had trusted the plan's default assumption instead of this file.

## Section 3 — Behavioral Findings

- None — the app behaved exactly as its own UI implies at every step (error messages are specific and accurate, the cart badge and button state stay in sync, checkout math is correct, nothing failed silently). Worth recording as a *finding* even when empty, since other apps tested with this pipeline have surfaced real hidden behavioral surprises here — not every app has them, and it's worth confirming that explicitly rather than leaving Section 3 blank by default.

## Section 4 — Notes for Implementation

- **Use `page.locator('[data-test="..."]')` throughout, not `page.getByTestId()`** — or set `use: { testIdAttribute: 'data-test' }` in `playwright.config.ts` so `getByTestId()` can be used idiomatically instead. Either works; this example uses explicit locators to keep the selector visible in the test code.
- **Guarded run:** set `BASE_URL=https://www.saucedemo.com` and, only after the recorded human approval, `E2E_ALLOW_REMOTE=www.saucedemo.com`. Provide account data through the named `E2E_*` variables only; never record their values in discovery output.
- Login is a single-step form submit (pressing the Login button, not Enter-to-submit) — no multi-step flow or auto-opening modal to account for, unlike some apps this pipeline has been run against.
- The cart badge element is **absent from the DOM**, not present-with-value-`"0"`, when the cart is empty — assert `toHaveCount(0)`, not `not.toBeVisible()` (which would also pass on a hidden-but-present element) or text content, for the empty state. Same applies to `[data-test="error"]`: it doesn't exist in the DOM at all until an error actually occurs.
- Checkout step one's "Error" element (`[data-test="error"]`) is reused for every field's validation message (First Name, then Last Name, then Postal Code, checked in that order) — only the first blank field's error shows at a time.
