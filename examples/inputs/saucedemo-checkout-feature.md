# Feature input: Swag Labs login, catalog, and checkout

There's no PRD for this one — [Swag Labs](https://www.saucedemo.com/) is a
real, publicly deployed practice site (Sauce Labs' own demo app, built
specifically to be automated against), not a product we wrote a spec for.
This is the kind of free-text feature description `/verefi:testplan`
also accepts directly on the command line — written from what the app
actually does, confirmed by driving it in a real browser rather than
guessed.

## What the app does

Swag Labs is a small e-commerce demo: log in, browse a product catalog,
add items to a cart, and check out.

- **Login** (`/`) — username + password. Use dedicated demo account states
  supplied at runtime through `E2E_USERNAME`, `E2E_PASSWORD`, and
  `E2E_LOCKED_USERNAME`; do not record their values in this feature
  description. A locked-out account, an intentionally invalid credential
  pair, or a blank required field each show a distinct, specific error
  message and keep the user on the login page. A side-menu logout ends the
  session and returns to the login page.
- **Product catalog** (`/inventory.html`) — six products, each with a
  name, description, price, and an "Add to cart" button that becomes
  "Remove" once added. A sort dropdown reorders the list by name (A–Z,
  Z–A) or price (low–high, high–low).
- **Cart** (`/cart.html`) — lists items added from the catalog with
  quantity and price; "Remove" takes an item back out; "Checkout" begins
  the purchase flow.
- **Checkout** is three steps:
  1. `/checkout-step-one.html` — first name, last name, zip/postal code.
     All three are required; leaving any blank blocks continuing and shows
     a specific validation error.
  2. `/checkout-step-two.html` — order summary: item(s), a fixed payment
     method and shipping method, an item subtotal, 8% tax, and a total.
  3. `/checkout-complete.html` — a confirmation message and a "Back Home"
     link; the cart is emptied.

## Scope for this test plan

Cover login (including its error paths), all four sort orders, the
add/remove-from-cart cycle, checkout's required-field validation, logout,
and the full purchase happy path end-to-end.
