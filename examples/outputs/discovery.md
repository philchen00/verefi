# Discovery: Saucedemo Login, Product Browsing/Sorting, and Checkout

**Run**: `saucedemo-checkout`
**Verified**: 2026-08-21
**Base URL**: `https://www.saucedemo.com`
**Target safety**: Approved non-production remote host `www.saucedemo.com`
**Remote/destructive approval**: Confirmed by Phil Chen (repo owner) on 2026-08-21 — hostname `www.saucedemo.com` named explicitly, stated as an approved non-production target (Sauce Labs' public demo site, no real backend/payment), scope stated as read-only exploration of login, product browsing/sorting, and the client-side-only cart/checkout flow (TC-001–TC-014), no destructive or real-money actions. No destructive action was performed or required — all cart/checkout actions are client-side/session-scoped only, confirmed live (order completion shows a static confirmation message with no persistent server-side order, and the cart clears on session teardown).
**Roles/Personas covered**: N/A — single role (`standard_user`, authenticated). `locked_out_user` was exercised only for the TC-002 negative-login case; it never reaches an authenticated state, so it isn't a distinct authenticated persona to explore further.
**Test ID attribute**: `data-test` — confirmed live via DOM attribute sampling on the login page (7 elements matched `data-test`, 0 matched any other `data-*test*`/`data-cy`/`data-qa` pattern). This is **not** Playwright's default `data-testid`; see Section 4.

## Section 1 — Verified Selectors

### Login Page — `/`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-001–004 | Username input | `page.locator('[data-test="username"]')` | — |
| TC-001–004 | Password input | `page.locator('[data-test="password"]')` | — |
| TC-001–004 | Login button | `page.locator('[data-test="login-button"]')` | — |
| TC-002 | Error message | `page.locator('[data-test="error"]')` | Confirmed text: `Epic sadface: Sorry, this user has been locked out.` |
| TC-003 | Error message | `page.locator('[data-test="error"]')` | Confirmed text: `Epic sadface: Username and password do not match any user in this service` |
| TC-004 | Error message (username blank) | `page.locator('[data-test="error"]')` | Confirmed text: `Epic sadface: Username is required` |
| TC-004 | Error message (password blank) | `page.locator('[data-test="error"]')` | Confirmed text: `Epic sadface: Password is required` (shown when username is filled but password is blank) |
| — | Error dismiss ("X") button | `page.locator('[data-test="error-button"]')` | Not referenced by a test case; discovered alongside the error banner |

### Products/Inventory Page — `/inventory.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-001 | Post-login URL | assert `page.url()` | Confirmed redirect target: `https://www.saucedemo.com/inventory.html` |
| TC-005 | Product card container | `page.locator('.inventory_item')` | Confirmed count: 6. No unique `data-test` on the wrapper itself (shared value `inventory-item` on every card) — use `.inventory_item` class or scope by child text for per-row assertions |
| TC-005 | Product name | `page.locator('[data-test="inventory-item-name"]')` | Shared `data-test` across all 6 cards; scope to one card via `.inventory_item` ancestor + `.filter({ hasText: ... })` when targeting a specific product |
| TC-005 | Product price | `page.locator('[data-test="inventory-item-price"]')` | Same shared-value caveat as name above. Confirmed catalog prices: Backpack $29.99, Bike Light $9.99, Bolt T-Shirt $15.99, Fleece Jacket $49.99, Onesie $7.99, Test.allTheThings() T-Shirt (Red) $15.99 |
| TC-005, TC-010 | Add to cart button (per product) | `page.locator('[data-test="add-to-cart-sauce-labs-backpack"]')` | Verified pattern: `add-to-cart-<name-slug>` (lowercase, spaces→hyphens). Confirmed for "Sauce Labs Backpack" only; same slugification is expected to hold for the other 5 products but was not independently re-verified for each |
| TC-010 | Remove button (post-add, same slot as Add to cart) | `page.locator('[data-test="remove-sauce-labs-backpack"]')` | Replaces the Add to cart button in place once the item is in the cart; confirmed text becomes "Remove" |
| TC-010 | Cart icon badge | `page.locator('[data-test="shopping-cart-badge"]')` | Confirmed text "1" after one add. **Element does not exist in the DOM at all when the cart is empty** — see Section 3 |
| TC-006–009 | Sort dropdown | `page.locator('[data-test="product-sort-container"]')` | Native `<select>`. Option **values** (not label text) confirmed: `az`=Name(A-Z), `za`=Name(Z-A), `lohi`=Price(low-high), `hilo`=Price(high-low) — see Section 4 |
| TC-010, TC-013 | Shopping cart link (navigates to cart page) | `page.locator('[data-test="shopping-cart-link"]')` | — |
| TC-014 | Burger/side-menu open button | `page.locator('#react-burger-menu-btn')` | **No `data-test` attribute.** Confirmed accessible role/name fallback resolves to exactly one element: `page.getByRole('button', { name: 'Open Menu' })`. See Section 2 (Gap) and Section 3 (click-reliability caution) |
| TC-014 | "All Items" sidebar link | `page.locator('[data-test="inventory-sidebar-link"]')` | Only present/interactable once side menu is open |
| TC-014 | Logout sidebar link | `page.locator('[data-test="logout-sidebar-link"]')` | Only present/interactable once side menu is open. Confirmed logout redirects to `/` |
| — | "About" sidebar link | `page.locator('[data-test="about-sidebar-link"]')` | Not referenced by a test case |
| — | "Reset App State" sidebar link | `page.locator('[data-test="reset-sidebar-link"]')` | Not referenced by a test case |
| TC-014 | Direct nav to `/inventory.html` while unauthenticated | assert `page.url()` + `[data-test="error"]` | Confirmed: redirects to `/` with error text `Epic sadface: You can only access '/inventory.html' when you are logged in.` |

### Cart Page — `/cart.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-011, TC-013 | Cart item row | `page.locator('.cart_item')` | Confirmed count 0 after removal |
| TC-013 | Cart item title link | `page.locator('[data-test="item-4-title-link"]')` | Uses a **numeric catalog ID**, not a name slug (`4` = Sauce Labs Backpack) — a different ID scheme from the Add to cart button's name-slug pattern; do not assume the two are interchangeable |
| TC-013 | Remove button (cart page) | `page.locator('[data-test="remove-sauce-labs-backpack"]')` | Same name-slug `data-test` value as the inventory-page Remove button |
| TC-011 | "Continue Shopping" button | `page.locator('[data-test="continue-shopping"]')` | — |
| TC-011 | "Checkout" button | `page.locator('[data-test="checkout"]')` | Navigates to `/checkout-step-one.html` |

### Checkout: Your Information — `/checkout-step-one.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-011, TC-012 | First Name input | `page.locator('[data-test="firstName"]')` | — |
| TC-011, TC-012 | Last Name input | `page.locator('[data-test="lastName"]')` | — |
| TC-011, TC-012 | Zip/Postal Code input | `page.locator('[data-test="postalCode"]')` | — |
| TC-011, TC-012 | Cancel button | `page.locator('[data-test="cancel"]')` | — |
| TC-011, TC-012 | Continue button | `page.locator('[data-test="continue"]')` | — |
| TC-012 | Error message (missing required field) | `page.locator('[data-test="error"]')` | Confirmed text with all fields blank: `Error: First Name is required`. **Same `data-test` value as the login-page error** — see Section 3 |

### Checkout: Overview — `/checkout-step-two.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-011 | Cancel button | `page.locator('[data-test="cancel"]')` | Same `data-test` value reused from step-one; unambiguous in practice since only one step is ever mounted at a time, but scope by URL/step context if writing a shared helper |
| TC-011 | Finish button | `page.locator('[data-test="finish"]')` | Navigates to `/checkout-complete.html` |

### Checkout: Complete — `/checkout-complete.html`

| Test Case(s) | Element | Selector | Notes |
|---|---|---|---|
| TC-011 | Confirmation heading | `page.locator('[data-test="complete-header"]')` | Confirmed text: `Thank you for your order!` |
| TC-011 | Confirmation body text | `page.locator('[data-test="complete-text"]')` | Confirmed text: `Your order has been dispatched, and will arrive just as fast as the pony can get there!` |
| TC-011 | "Back Home" button | `page.locator('[data-test="back-to-products"]')` | Returns to `/inventory.html` |
| TC-011 | Cart badge cleared | `page.locator('[data-test="shopping-cart-badge"]')` | Confirmed absent from DOM (count 0) after order completion — assert on count/absence, not visibility/text |

## Section 2 — Gaps

- TC-014 — App missing — fallback available: the burger/side-menu open button (`#react-burger-menu-btn`) has no `data-test` attribute. Confirmed accessible-role fallback `getByRole('button', { name: 'Open Menu' })` resolves to exactly one element live. Usable directly by `implement`, but flag it with a fragility comment since it's a role/name locator, not a durable test-id.

## Section 3 — Behavioral Findings

- **Automated real-clicks were unreliable against several buttons in this discovery session, independent of the app's actual logic.** Across this run, `agent-browser`'s click (tried via CSS selector, ARIA role/name, and snapshot-ref locators) reported success ("✓ Done") but produced no observable state change on: the burger-menu button (3/3 attempts, including after a full session restart), the "Logout" sidebar link (1/1 attempt), and the "Add to cart" button (3/3 attempts, including a hover+click retry and after a session restart). In every one of these cases, a JS-dispatched `element.click()` on the *identical* element succeeded immediately and produced the expected app behavior (menu opened, logout redirected, cart badge incremented). By contrast, the plain "Login" submit button responded correctly to a real click both before and after the session restart. Since the JS-click path always worked and the underlying app handlers are clearly intact, this looks like click-delivery flakiness in the automation path used during discovery, not a genuine product defect — but it's worth a heads-up: if `implement`'s generated Playwright suite (or `execute`'s runs) sees intermittent failures where a `.click()` on `Add to cart`, the burger-menu button, or a sidebar link doesn't produce the expected state change, don't immediately conclude the site is broken — first retry, check for an explicit visibility/stability wait before the click, and confirm with more than one run before treating it as an `App bug`.
- **The cart badge element (`[data-test="shopping-cart-badge"]`) is entirely absent from the DOM when the cart is empty — not just hidden.** Tests asserting "badge shows 0 or is hidden" (TC-011, TC-013) should assert `toHaveCount(0)` / absence, not visibility or text content of an element that may not exist at all.
- **The login-page error banner and the checkout-step-one error banner share the exact same `data-test="error"]` selector.** They're really two different form components reusing the same test-id convention. Not a bug, but a trap for a shared helper that queries `[data-test="error"]` globally without scoping to the current page — it will match whichever error is currently mounted, which is fine in practice (only one is ever mounted at a time) but worth calling out explicitly.

## Section 4 — Notes for Implementation

- **Test ID attribute: `data-test`** — not Playwright's default `data-testid`. `playwright.config.ts` must set `use.testIdAttribute: 'data-test'` before any `getByTestId()` call will match anything, **or** use `page.locator('[data-test="value"]')` directly instead of `getByTestId()`.
- Sort dropdown is a native `<select>` — use `selectOption({ value: 'az' | 'za' | 'lohi' | 'hilo' })` with the short value codes confirmed in Section 1, not the visible label text (`selectOption({ label: '...' })` also works if matching the visible text is preferred, but the value codes are the more stable contract).
- Multi-step checkout flow is strictly sequential and each step's elements do not exist until the prior step's action completes: `cart.html` → (Checkout) → `checkout-step-one.html` → (Continue, with all 3 fields valid) → `checkout-step-two.html` → (Finish) → `checkout-complete.html`. A shared `beforeEach` login helper does not by itself guarantee a cart item exists — TC-011/TC-012 need an explicit "add to cart" step before checkout is reachable in a meaningful state.
- Authentication credentials (`standard_user`/`secret_sauce`, `locked_out_user`/`secret_sauce`) are published directly on Saucedemo's own login page (not treated as secrets by the target site itself) and were verified against the live page text during this run. The actual generated test code sources them via `E2E_USERNAME`/`E2E_PASSWORD`/`E2E_LOCKED_USERNAME` env vars per the test plan's Implementation Notes, never hardcoded, for consistency with the plan's stated safety posture.
- Approved host confirmed reachable: `https://www.saucedemo.com`. No destructive or real-money action was taken or required during discovery — order completion and cart mutations are entirely client-side/session-scoped, confirmed live (no network persistence observed; state resets on session teardown).
