# Benchmark: `checkout-basic`

A four-screen static shop used to measure what Verefi generates. No build step,
no framework, no backend, no network — `app/` is plain HTML/CSS/JS served by any
static file server, and all logic lives in `app/app.js` so a mutation is a
one-line patch.

```bash
python3 -m http.server 4173 --directory app
# http://127.0.0.1:4173  ·  demo_user / demo_pass
```

Screens: `index.html` (sign in) → `products.html` → `cart.html` →
`checkout.html` → `confirm.html`.

## Why it is deliberately imperfect

A benchmark app we author is at constant risk of being *too easy*: uniformly
instrumented, semantically perfect, and therefore a measurement of the pipeline
on conditions no real app provides. Every awkward property below is there on
purpose, and each one exercises a specific pipeline behavior that would
otherwise go untested.

This also closes a gap noted in the backlog (N2): `audit` has never been field
tested against a **partially instrumented** codebase. Pearl was all-bare, so
audit's middle grading path has never actually run against a real target. This
app is built to land squarely in it.

## Requirements

Stable ids, referenced by `benchmark.yaml` and by the mutations.

| Id | Requirement |
|---|---|
| `REQ-AUTH-001` | A user can sign in with valid credentials |
| `REQ-AUTH-002` | Invalid credentials are rejected with a visible error |
| `REQ-AUTH-003` | An unauthenticated user cannot reach products, cart, checkout or confirmation |
| `REQ-CART-001` | A product can be added to the cart; the badge reflects the count |
| `REQ-CART-002` | Changing quantity updates the subtotal |
| `REQ-CART-003` | An item can be removed from the cart |
| `REQ-CHECKOUT-001` | Order total equals subtotal plus 8% tax |
| `REQ-CHECKOUT-002` | A card number that is not 16 digits is rejected with a visible error |
| `REQ-CHECKOUT-003` | Completing checkout shows a confirmation with an order id |

## Instrumentation map

The attribute is **`data-test`**, not Playwright's default `data-testid`. That
alone exercises `implement` Step 2b — a suite that ignores it compiles, lists
cleanly, and then matches nothing at runtime.

| Element | Addressable by | Exercises |
|---|---|---|
| Username / password / sign-in / error | `data-test` | Normal happy path |
| Product card, name, price | `data-test` — **same value on every card** | Per-card scoping; a bare `getByTestId` resolves 4 elements |
| Add-to-cart button | `data-test="add-to-cart-<slug>"` — unique per product | Slug-pattern selectors |
| Cart badge | `data-test` | **Absent from the DOM when empty**, not hidden — must assert count, not visibility |
| Cart quantity input | No test-id; real `<label for>` | `App missing — fallback available`: `getByLabel` works, use it with a fragility note |
| **Cart row remove control** | **Nothing** — a `<span>` with `×`, no role, no accessible name, identical on every row | `App missing — no fallback`: must produce `test.fixme()`, never an invented selector |
| Checkout name / card fields | `aria-label` only | Role/name fallback |
| Place-order button | Real `<button>` | Free role+name |
| Confirmation heading, order id | `data-test` | Normal happy path |

### The behavioral quirk

Submitting checkout with a **blank name** does nothing at all — no error, no
navigation, no console output. Nothing is missing from the DOM, so this is not
a selector gap; it belongs in `discovery.md` **Section 3 (Behavioral
Findings)**. It is distinct from `REQ-CHECKOUT-002`, where an invalid *card*
correctly shows an error.

A run that silently ignores this, or that writes a test asserting the silence
is correct, has demonstrated the failure `implement` Step 1c exists to prevent.

## Mutations

Each seeds one real defect. The generated suite is expected to **fail** on each.

| Id | Defect | Covers |
|---|---|---|
| `CHECKOUT-001` | Total omits tax | `REQ-CHECKOUT-001` |
| `CART-001` | Quantity change does not refresh the subtotal | `REQ-CART-002` |
| `CHECKOUT-002` | Invalid card accepted | `REQ-CHECKOUT-002` |
| `CONFIRM-001` | Confirmation omits the order id | `REQ-CHECKOUT-003` |
| `AUTH-001` | Route guard removed | `REQ-AUTH-003` |

```bash
cp -r app /tmp/mutant && ./mutations/checkout-001.sh /tmp/mutant
```

Apply to a **copy**; the scripts patch in place. Each fails hard (exit 3) if its
anchor no longer matches exactly, rather than patching nothing:

```
MUTATION_ANCHOR_ERROR: expected 1 line(s) matching the anchor in ..., found 0.
  The application changed but the mutation was not updated. Refusing to
  produce a run that would look like an undetected defect.
```

That refusal matters more than it looks. A silently-unapplied mutation makes
every generated test pass, and the scorecard reports "defect not detected" —
blaming Verefi for a harness bug. The check earned its place during
development: it caught a miscounted anchor in `CART-001` on the first run.

`AUTH-001` is worth watching as a coverage measurement, not just a defect.
Route-guard scenarios appeared in only **1 of 6** runs in the rubric
experiment, so a low detection rate here reflects the test plan never
considering the case — exactly what the standing-checklist work is meant to fix.

## What this benchmark cannot tell you

- **Component-library chaos.** Real design systems produce atomic-CSS div soup;
  this app's DOM is legible. A React Native Web target would still surprise the
  pipeline in ways this cannot.
- **Scale.** Nine requirements is a small plan. The rubric experiment's long-tail
  variance gets more pronounced as plans grow.
- **Authored-by-us bias.** The instrumentation gaps here are the ones we already
  know about, drawn from findings the pipeline has already been hardened
  against. A second benchmark from a codebase nobody on this project wrote would
  be worth more than a bigger version of this one.
