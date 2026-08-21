# Test Plan: Swag Labs login, catalog sort, and checkout

**Run**: `saucedemo-checkout`
**Created**: 2026-08-15
**Status**: Approved
**Human approval**: Approved by Demo Maintainer on 2026-08-15
**Input**: "examples/inputs/saucedemo-checkout-feature.md"

## Section 1 — Test Cases

### TC-001: Successful login with a valid account

**Type:** Happy Path
**Priority:** P1 — every other test case depends on being able to log in
**Data impact:** Read-only — creates only a disposable authenticated demo session

**Given:** The user is on the login page (`/`)
**When:** They supply the dedicated demo credentials named by `E2E_USERNAME` and `E2E_PASSWORD`, then click Login
**Then:** They land on the product catalog

**Acceptance Criteria:**
- [ ] URL changes to `/inventory.html`
- [ ] Page title (`[data-testid="title"]`) reads "Products"
- [ ] Six `[data-testid="inventory-item"]` elements are visible

---

### TC-002: Locked-out account is rejected with a specific error

**Type:** Negative
**Priority:** P1 — silent or generic auth failures are a common real bug class
**Data impact:** Read-only — rejected demo login only

**Given:** The user is on the login page
**When:** They supply the dedicated locked-out demo account named by `E2E_LOCKED_OUT_USERNAME` with `E2E_PASSWORD`, then click Login
**Then:** Login is rejected and the reason is shown, not just a generic failure

**Acceptance Criteria:**
- [ ] URL remains `/` (no navigation to the catalog)
- [ ] `[data-testid="error"]` reads "Epic sadface: Sorry, this user has been locked out."

---

### TC-003: Invalid credentials are rejected with a specific error

**Type:** Negative
**Priority:** P2
**Data impact:** Read-only — rejected demo login only

**Given:** The user is on the login page
**When:** They supply `E2E_USERNAME` with the intentionally invalid value named by `E2E_INVALID_PASSWORD`, then click Login
**Then:** Login is rejected with a message distinct from the locked-out case

**Acceptance Criteria:**
- [ ] URL remains `/`
- [ ] `[data-testid="error"]` reads "Epic sadface: Username and password do not match any user in this service"

---

### TC-004: Sorting by price (low to high) reorders the catalog

**Type:** Edge Case
**Priority:** P2
**Data impact:** Read-only — changes only the in-session catalog sort selection

**Given:** The user is on the catalog page with the default "Name (A to Z)" sort
**When:** They select "Price (low to high)" from `[data-testid="product-sort-container"]`
**Then:** The six products re-render in ascending price order

**Acceptance Criteria:**
- [ ] All six products are still present after sorting — no drops or duplicates, same set as before the sort
- [ ] `[data-testid="inventory-item-price"]` values are non-decreasing top to bottom
- [ ] First item is $7.99 (Sauce Labs Onesie), last is $49.99 (Sauce Labs Fleece Jacket)

---

### TC-005: Adding a product to the cart updates the badge and the button

**Type:** Happy Path
**Priority:** P1
**Data impact:** Changes disposable demo cart state; no customer or payment data

**Given:** The user is on the catalog page with an empty cart
**When:** They click `[data-testid="add-to-cart-sauce-labs-backpack"]`
**Then:** The cart badge appears and the button becomes a Remove action

**Acceptance Criteria:**
- [ ] `[data-testid="shopping-cart-badge"]` reads "1"
- [ ] The clicked button's `data-testid` changes to `remove-sauce-labs-backpack`, text "Remove"

---

### TC-006: Removing a product from the cart clears the badge

**Type:** Happy Path
**Priority:** P2
**Data impact:** Changes disposable demo cart state; no customer or payment data

**Given:** The Sauce Labs Backpack is in the cart (badge reads "1")
**When:** The user clicks `[data-testid="remove-sauce-labs-backpack"]`
**Then:** The item is removed and the cart returns to empty

**Acceptance Criteria:**
- [ ] `[data-testid="shopping-cart-badge"]` is no longer present
- [ ] The button reverts to `[data-testid="add-to-cart-sauce-labs-backpack"]`, text "Add to cart"

---

### TC-007: Cart page lists added items correctly

**Type:** Happy Path
**Priority:** P1
**Data impact:** Reads a disposable demo cart created within the same test session

**Given:** The Sauce Labs Backpack has been added to the cart
**When:** The user opens `[data-testid="shopping-cart-link"]`
**Then:** The cart page shows the item with correct name, price, and quantity

**Acceptance Criteria:**
- [ ] URL changes to `/cart.html`
- [ ] `[data-testid="inventory-item-name"]` reads "Sauce Labs Backpack"
- [ ] `[data-testid="inventory-item-price"]` reads "$29.99"
- [ ] `[data-testid="item-quantity"]` reads "1"

---

### TC-008: Checkout step one requires all three fields

**Type:** Negative
**Priority:** P2
**Data impact:** Read-only — validation values stay within the disposable demo session

**Given:** The user is on `/checkout-step-one.html` with an item in the cart
**When:** They click `[data-testid="continue"]` with one or more of First Name, Last Name, and Postal Code blank
**Then:** Checkout is blocked with a field-specific validation error naming the first blank field encountered

**Acceptance Criteria:**
- [ ] All fields blank: URL remains `/checkout-step-one.html`, `[data-testid="error"]` reads "Error: First Name is required"
- [ ] First Name filled, Last Name and Postal Code blank: `[data-testid="error"]` reads "Error: Last Name is required"
- [ ] First Name and Last Name filled, Postal Code blank: `[data-testid="error"]` reads "Error: Postal Code is required"

---

### TC-009: Checkout overview shows correct item total, tax, and total

**Type:** Happy Path
**Priority:** P1 — price math is exactly the kind of thing a fixed example test should pin down
**Data impact:** Changes disposable demo cart and checkout-session state; no payment data

**Given:** The Sauce Labs Backpack ($29.99) is the only item in the cart, and checkout step one is complete
**When:** The checkout overview (`/checkout-step-two.html`) loads
**Then:** The summary shows the item, an 8% tax line, and a total that is the sum of both

**Acceptance Criteria:**
- [ ] `[data-testid="subtotal-label"]` reads "Item total: $29.99"
- [ ] `[data-testid="tax-label"]` reads "Tax: $2.40"
- [ ] `[data-testid="total-label"]` reads "Total: $32.39"

---

### TC-010: Completing checkout shows a confirmation message

**Type:** Happy Path
**Priority:** P1
**Data impact:** Creates a disposable demo order state only; no payment, customer, or fulfillment data

**Given:** The user is on the checkout overview page
**When:** They click `[data-testid="finish"]`
**Then:** The order completes and a confirmation is shown

**Acceptance Criteria:**
- [ ] URL changes to `/checkout-complete.html`
- [ ] `[data-testid="complete-header"]` reads "Thank you for your order!"
- [ ] `[data-testid="back-to-products"]` button is visible

---

### TC-011: Full purchase happy path, end to end

**Type:** Happy Path
**Priority:** P1 — the scenario that actually matters to a real user
**Data impact:** Creates a disposable demo order state only; start with a fresh session and leave no account-specific data behind

**Given:** The user starts logged out
**When:** They log in, add the Sauce Labs Backpack to the cart, go to the cart, proceed through all three checkout steps with valid info, and finish
**Then:** They land on the confirmation page having never seen an error

**Acceptance Criteria:**
- [ ] No `[data-testid="error"]` appears after any of the five transitions: catalog, cart, checkout step one, checkout step two, confirmation
- [ ] Confirmation page is reached (`/checkout-complete.html`)
- [ ] `[data-testid="complete-header"]` reads "Thank you for your order!"

---

## Section 2 — Implementation Notes

- **Selector strategy:** `data-testid` per `references/playwright.instructions.md`'s default priority — unconfirmed against the live app at plan-writing time. *(See `discovery.md`: this assumption turned out to be wrong — the app uses `data-test`, not `data-testid`.)*
- **Target safety:** Approved remote host: `www.saucedemo.com`; approved by: Demo Maintainer; scope: the public Swag Labs demo login, catalog, cart, and checkout flows only. Runtime requires `E2E_ALLOW_REMOTE=www.saucedemo.com`; do not run against production or customer accounts.
- **Base URL:** `BASE_URL` at runtime; the approved demo value is `https://www.saucedemo.com`. Do not hardcode a remote URL in generated tests or config.
- **Authentication / credentials:** dedicated public-demo account identifiers and values are supplied only through `E2E_USERNAME`, `E2E_PASSWORD`, `E2E_LOCKED_OUT_USERNAME`, and `E2E_INVALID_PASSWORD`. Their values are intentionally not recorded here.
- **Destructive actions and cleanup:** TC-005 through TC-011 change only disposable cart/order state in the public demo. No payment, customer, or fulfillment data is used; begin each test with a fresh demo session and leave no account-specific data behind.
- **Test files to create:** `tests/e2e/saucedemo-checkout.spec.ts` — all test cases (current `implement` convention is one spec file per run)
- **Key fixtures or shared setup:** A `login(page, username, password)` helper used by every test case except TC-001–TC-003, which exercise login itself.

**Test Data** (if the test cases reference shared variables):

| Variable | Source | Safety notes |
|---|---|---|
| valid_username | `E2E_USERNAME` | Dedicated public-demo account; value is not written to plans, reports, or source control |
| valid_password | `E2E_PASSWORD` | Dedicated public-demo secret; value is never recorded |
| locked_out_username | `E2E_LOCKED_OUT_USERNAME` | Dedicated demo negative-path account; value is never recorded |
| invalid_password | `E2E_INVALID_PASSWORD` | Intentionally invalid demo input; value is never recorded |

## Section 3 — Open Questions

None

## Section 4 — Out of Scope

- Other vendor-provided demo account states — deliberately varied variants for exploring bug classes, not part of this feature's core flow
- "Generate PDF order" on the confirmation page
- The hamburger menu's "Reset App State" and "About" links
- Cross-browser testing beyond Chromium, and mobile/responsive layout
