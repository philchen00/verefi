# Test Plan: Saucedemo Login, Product Browsing/Sorting, and Checkout

**Run**: `saucedemo-checkout`
**Created**: 2026-08-21
**Status**: Approved
**Review triage**: 9 auto-cleared, 5 flagged (from discovery.md on 2026-08-21) — see each test case's Review tier. **Applied retroactively on 2026-08-23**, after this plan was approved, to illustrate the tier format on a real plan; the approval below predates tiering and therefore covers all 14 cases at full scrutiny.
**Human approval**: Approved by Phil Chen on 2026-08-21
**Input**: "Users can log in, browse and sort products, and check out https://www.saucedemo.com"

## Section 1 — Test Cases

### TC-001: Successful login with valid standard user

**Type:** Happy Path
**Priority:** P1 — login is the entry point for every other flow in this plan
**Data impact:** Read-only — no account state is mutated by logging in
**Review tier:** Needs review — P1. Selectors are live-verified (discovery.md §1), but the plan itself calls this the entry point for every other flow, so a human confirms the assertions are the right ones.

**Given:** The user is on the Saucedemo login page and has a valid standard test account
**When:** The user enters a valid username and password and submits the login form
**Then:** The user is redirected to the products/inventory page and sees the product list

**Acceptance Criteria:**
- [ ] URL changes to the inventory/products page after submit
- [ ] The product grid is visible with at least one product
- [ ] No error message is displayed

### TC-002: Login blocked for a locked-out user

**Type:** Negative
**Priority:** P2 — verifies account-lockout messaging works, a common support-ticket source
**Data impact:** Read-only
**Review tier:** Auto-cleared — selectors and the exact error text live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the login page and has credentials for an account known to be locked out
**When:** The user enters the locked-out username and correct password and submits
**Then:** Login is rejected and a locked-out error message is shown; the user remains on the login page

**Acceptance Criteria:**
- [ ] URL remains on the login page
- [ ] An error message mentioning the account being locked out is visible

### TC-003: Login rejected with invalid credentials

**Type:** Negative
**Priority:** P2 — core negative-auth guardrail
**Data impact:** Read-only
**Review tier:** Auto-cleared — selectors and the exact error text live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the login page
**When:** The user enters a username/password combination that does not match any account
**Then:** Login is rejected and a generic invalid-credentials error is shown

**Acceptance Criteria:**
- [ ] URL remains on the login page
- [ ] An error message indicating invalid username/password is visible

### TC-004: Login rejected with empty username and/or password

**Type:** Negative
**Priority:** P3 — basic client-side validation check
**Data impact:** Read-only
**Review tier:** Auto-cleared — both blank-field error texts live-verified (discovery.md §1), P3, read-only

**Given:** The user is on the login page
**When:** The user submits the login form with the username field, the password field, or both left blank
**Then:** Login is rejected and a field-required error is shown

**Acceptance Criteria:**
- [ ] URL remains on the login page
- [ ] An error message indicating the missing required field(s) is visible

### TC-005: Product list displays all catalog items after login

**Type:** Happy Path
**Priority:** P1 — core browse flow
**Data impact:** Read-only
**Review tier:** Needs review — P1. Selectors live-verified, but discovery.md §1 notes product name/price share one `data-test` value across all 6 cards, so the per-card scoping strategy is worth a human look.

**Given:** The user is logged in with a valid standard account
**When:** The products page loads
**Then:** All catalog products are displayed, each with a name, price, image, and "Add to cart" action

**Acceptance Criteria:**
- [ ] The number of rendered product cards matches the known catalog size
- [ ] Each product card shows a name, a price, and an add-to-cart control

### TC-006: Sort products by Name (A to Z)

**Type:** Happy Path
**Priority:** P2 — validates the sort control, part of the requested "sort products" flow
**Data impact:** Read-only
**Review tier:** Auto-cleared — sort dropdown and its `az` option value live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the products page with the default sort applied
**When:** The user selects the "Name (A to Z)" sort option
**Then:** Products are re-ordered alphabetically ascending by name

**Acceptance Criteria:**
- [ ] Rendered product names are in strict ascending alphabetical order after sorting

### TC-007: Sort products by Name (Z to A)

**Type:** Happy Path
**Priority:** P2
**Data impact:** Read-only
**Review tier:** Auto-cleared — sort dropdown and its `za` option value live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the products page
**When:** The user selects the "Name (Z to A)" sort option
**Then:** Products are re-ordered alphabetically descending by name

**Acceptance Criteria:**
- [ ] Rendered product names are in strict descending alphabetical order after sorting

### TC-008: Sort products by Price (low to high)

**Type:** Happy Path
**Priority:** P2
**Data impact:** Read-only
**Review tier:** Auto-cleared — sort dropdown and its `lohi` option value live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the products page
**When:** The user selects the "Price (low to high)" sort option
**Then:** Products are re-ordered by ascending price

**Acceptance Criteria:**
- [ ] Rendered product prices are in non-decreasing numeric order after sorting

### TC-009: Sort products by Price (high to low)

**Type:** Happy Path
**Priority:** P2
**Data impact:** Read-only
**Review tier:** Auto-cleared — sort dropdown and its `hilo` option value live-verified (discovery.md §1), P2, read-only

**Given:** The user is on the products page
**When:** The user selects the "Price (high to low)" sort option
**Then:** Products are re-ordered by descending price

**Acceptance Criteria:**
- [ ] Rendered product prices are in non-increasing numeric order after sorting

### TC-010: Add a single product to the cart and verify the cart badge

**Type:** Happy Path
**Priority:** P1 — prerequisite for checkout
**Data impact:** Creates isolated test data — adds an item to the in-session cart (client-side/session-scoped on this demo site, not a real backend order); cleanup is implicit on session/browser-context teardown, no explicit rollback action exists on the site
**Review tier:** Needs review — P1 **and** creates test data. Either alone would flag it. Also worth the reviewer's attention: discovery.md §3 records that the cart badge is absent from the DOM (not merely hidden) when empty.

**Given:** The user is logged in and viewing the product list
**When:** The user clicks "Add to cart" on one product
**Then:** The cart badge count increments to 1 and the button state changes to "Remove"

**Acceptance Criteria:**
- [ ] Cart icon badge shows "1"
- [ ] The product's action button now reads "Remove"

### TC-011: Complete end-to-end checkout with one item

**Type:** Happy Path
**Priority:** P1 — the primary purchase flow named in the request
**Data impact:** Creates isolated test data — this demo site simulates checkout entirely client-side; no real payment is processed and no server-side order record persists beyond the session, so no cleanup/rollback action is required
**Review tier:** Needs review — P1 **and** creates test data. The full purchase path against an approved remote host is exactly the case a human should read even though every selector in it is live-verified.

**Given:** The user is logged in and has added one product to the cart
**When:** The user opens the cart, proceeds to checkout, enters shipping information (first name, last name, postal code) using fictional test values, continues through the order overview, and finishes the order
**Then:** The order completes and a confirmation message is shown

**Acceptance Criteria:**
- [ ] Confirmation page displays a "Thank you" / order-complete message
- [ ] Cart badge is cleared (0 or hidden) after order completion

### TC-012: Checkout blocked when required shipping info is missing

**Type:** Negative
**Priority:** P2 — checkout form validation guardrail
**Data impact:** Read-only — form is never successfully submitted
**Review tier:** Auto-cleared — checkout-step-one fields and error banner live-verified (discovery.md §1), P2, read-only

**Given:** The user is logged in, has an item in the cart, and is on the checkout information step
**When:** The user leaves one or more of first name, last name, or postal code blank and clicks continue
**Then:** Checkout is blocked and a field-required error is shown; the user remains on the checkout information step

**Acceptance Criteria:**
- [ ] URL remains on the checkout information step
- [ ] An error message identifying the missing required field is visible

### TC-013: Remove a product from the cart before checkout

**Type:** Edge Case
**Priority:** P3 — validates cart mutation outside the main happy path
**Data impact:** Creates isolated test data — adds then removes an item within the same session; no persistent state remains after removal
**Review tier:** Needs review — creates isolated test data. P3 and fully live-verified, so evidence and priority would both have cleared it; the data-impact condition is what flags it, keeping the template's "explicit human approval for anything other than read-only" rule intact.

**Given:** The user is logged in and has added a product to the cart
**When:** The user opens the cart and removes the item
**Then:** The item is no longer listed in the cart and the cart badge reflects zero items

**Acceptance Criteria:**
- [ ] Cart badge shows "0" or is hidden after removal
- [ ] The removed product no longer appears in the cart list

### TC-014: Logout ends the session and returns to the login page

**Type:** Edge Case
**Priority:** P3 — session-boundary check, not explicitly requested but low-cost coverage of the login/logout pair
**Data impact:** Read-only
**Review tier:** Auto-cleared — P3, read-only, and every element live-verified including the burger-menu button, whose role/name fallback (`getByRole('button', { name: 'Open Menu' })`) was confirmed live to resolve to exactly one element (discovery.md §1–2). A confirmed fallback counts as verified — lower-confidence than a test-id, not unverified.

**Given:** The user is logged in and on the products page
**When:** The user opens the side menu and selects logout
**Then:** The session ends and the user is returned to the login page

**Acceptance Criteria:**
- [ ] URL returns to the login page
- [ ] Attempting to navigate directly back to the products page without re-authenticating redirects to login

## Section 2 — Implementation Notes

- **Selector strategy:** stable test-id attribute (exact attribute name — `data-testid`, `data-test`, `data-cy`, etc. — TBD until `/verefi:discover` confirms it; Saucedemo is publicly known to use `data-test` on most interactive elements, but this must be verified against the live DOM, not assumed) > aria-label > role > text
- **Target safety:** Approved remote host: `www.saucedemo.com`; approved by: Phil Chen (repo owner, automated E2E validation of the Verefi pipeline itself); scope: read-only login/browse/sort flows plus the client-side-only checkout flow (TC-010–TC-013), using only this site's own published demo credentials (`standard_user`/`secret_sauce`, `locked_out_user`). No real payment is processed and no server-side order persists on this practice site. `E2E_ALLOW_REMOTE=www.saucedemo.com` must be supplied at runtime (never committed to code or CI config).
- **Base URL:** `BASE_URL` at runtime; default for local dev would be `http://127.0.0.1:3000`, but this plan targets the remote demo site, so `BASE_URL` should be set to `https://www.saucedemo.com` only once the remote-host approval above is completed.
- **Authentication / credentials:** Dedicated non-production test account via named environment variables — `E2E_USERNAME`, `E2E_PASSWORD` (for the standard-user happy-path cases) and `E2E_LOCKED_USERNAME` for TC-002. These environment variables are populated with this public demo site's own published demo accounts (`standard_user` / `secret_sauce` for `E2E_USERNAME`/`E2E_PASSWORD`, `locked_out_user` for `E2E_LOCKED_USERNAME`) — these are not real secrets, they are documented on saucedemo.com's own login page, but must still be supplied only via environment variables at runtime, never hardcoded in test code.
- **Destructive actions and cleanup:** None — all cart/checkout actions in this plan operate on this demo site's client-side/session-scoped state only; no real backend order, payment, or persistent account data is created. No cleanup or rollback action exists or is needed.
- **Test files to create:** `tests/e2e/saucedemo-checkout.spec.ts` (all test cases, organized into `test.describe` blocks by feature area) plus `tests/e2e/pageObj/*.ts` (one page-object class per page/view)
- **Key fixtures or shared setup:** A shared login helper that performs TC-001's login flow using `E2E_USERNAME`/`E2E_PASSWORD` and lands on the products page, reused as a `beforeEach` precondition for TC-005–TC-014.

**Test Data** (if the test cases reference shared variables):

| Variable | Safe example value | Source / safety notes |
|---|---|---|
| E2E_USERNAME | (not stored here) | Environment variable pointing to a dedicated non-production standard test account |
| E2E_PASSWORD | (not stored here) | Environment variable; never logged or printed |
| E2E_LOCKED_USERNAME | (not stored here) | Environment variable for the locked-out-account negative case (TC-002) |
| checkout_first_name | "Test" | Fictional value, safe to hardcode in test code |
| checkout_last_name | "User" | Fictional value, safe to hardcode in test code |
| checkout_postal_code | "94107" | Fictional value, safe to hardcode in test code |

## Section 3 — Open Questions

None

## Section 4 — Out of Scope

- Multi-item cart scenarios (adding/removing more than one product at once) beyond the single-item flows in TC-010/TC-011/TC-013
- Visual/UI regression testing (e.g. the intentionally-broken `visual_user`/`problem_user` demo accounts)
- Performance or load testing (e.g. the `performance_glitch_user` demo account)
- Payment processing correctness — this demo site does not implement real payment processing, so no payment-validation cases are included
- Cross-browser or mobile-viewport coverage
- Accessibility (a11y) auditing
