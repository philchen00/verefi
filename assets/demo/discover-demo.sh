#!/usr/bin/env bash
# Scripted transcript used to record assets/discover-demo.gif via vhs
# (assets/demo/discover-demo.tape). Not a live invocation of Claude Code — a
# representative walkthrough of install + the pipeline's real output shape,
# built from examples/outputs/ (test-plan.md, discovery.md, the generated
# spec, and coverage-report.md's "11 passed (5.4s)"), itself from an actual
# live run against https://www.saucedemo.com. Every selector, count, and gap
# below is real, not invented for the recording.
#
# Two distinct prompts on purpose: the green ➜ is a real shell command you'd
# type yourself (clone the plugin, then launch Claude from the target app).
# Verefi has no CLI of its own — everything after that runs as slash commands
# *inside* the already-running Claude Code session, shown with a different
# prompt (❯) to make that split honest instead of implying a `verefi` binary.
set -e

type_line() {
  local text="$1"
  for ((i = 0; i < ${#text}; i++)); do
    printf '%s' "${text:$i:1}"
    sleep 0.012
  done
  printf '\n'
}

shell_prompt() {
  printf '\033[1;32m➜\033[0m '
}

claude_prompt() {
  printf '\033[1;36m❯\033[0m '
}

clear

shell_prompt
type_line 'git clone https://github.com/philchen00/verefi.git /path/to/verefi'
sleep 0.3
cat <<'EOF'
Cloning into '/path/to/verefi'...
remote: Enumerating objects: 63, done.
Receiving objects: 100% (63/63), 412.88 KiB | 9.16 MiB/s, done.
EOF
sleep 0.6

shell_prompt
type_line 'cd /path/to/your-app'
sleep 0.6

shell_prompt
# This recording collapses README.md's Quick Start into one launch for a short
# GIF. It is NOT the recommended flow: real usage reviews test-plan.md first
# (see README's steps 1-2), then restarts with these vars only for step 3
# onward, once www.saucedemo.com — or your own target — is confirmed safe to
# test. Do not copy this single-command pattern as-is for your own app.
type_line 'VEREFI_ALLOW_INSTALL=1 BASE_URL=https://www.saucedemo.com E2E_ALLOW_REMOTE=www.saucedemo.com claude --plugin-dir /path/to/verefi'
sleep 0.6

clear
cat <<'EOF'
───────────────────────────────────────────────────────────────────
 Claude Code  ·  plugin loaded: verefi (v0.1.1)
 Skills: testplan · audit · discover · implement · execute
───────────────────────────────────────────────────────────────────

EOF
sleep 0.6

claude_prompt
type_line '/verefi:testplan "Users can log in, browse and sort products, and check out https://www.saucedemo.com" --name saucedemo-checkout'
sleep 0.4
cat <<'EOF'

✓ Wrote .verefi/saucedemo-checkout/test-plan.md (11 test cases)
  (No local checkout of the target app's source here, so audit is not run —
   see discover below instead.)

  Stop and review the test plan before continuing.
EOF
sleep 1.2

echo
claude_prompt
type_line '/verefi:discover --name saucedemo-checkout --url https://www.saucedemo.com'
sleep 0.4
cat <<'EOF'

Step 0 — preconditions: base URL reachable ✓  dedicated demo login ✓
Step 2 — exploring https://www.saucedemo.com ...

  agent-browser open https://www.saucedemo.com
  agent-browser snapshot -i
  ✓ login        [data-test="username"] [data-test="password"] [data-test="login-button"]
  ✓ catalog      6x [data-test="inventory-item"]  sort: [data-test="product-sort-container"]
  ✓ cart         [data-test="shopping-cart-badge"] [data-test="add-to-cart-sauce-labs-backpack"]
  ✓ checkout     [data-test="firstName"] [data-test="continue"] [data-test="finish"]
  ✓ confirmation [data-test="complete-header"]

  ⚠ Gap: test-plan.md assumed data-testid (this pipeline's default) —
    the live app actually uses data-test. Recorded, not silently guessed.

✓ Wrote .verefi/saucedemo-checkout/discovery.md
  27/27 test-plan elements verified against the live app
  1 gap · 0 behavioral findings
EOF
sleep 1.6

echo
claude_prompt
type_line '/verefi:implement --name saucedemo-checkout'
sleep 0.4
cat <<'EOF'

✓ No root Playwright setup found — scaffolded playwright.config.ts + package.json
  BASE_URL is set; www.saucedemo.com is explicitly approved for this demo
  Selector trust: discovery.md (live-verified) — nothing fabricated

✓ Wrote tests/e2e/saucedemo-checkout.spec.ts (11 tests)
  Login · Product Catalog · Cart · Checkout · End to End

  Committed suite — review it like any other PR.
EOF
sleep 1.6

echo
claude_prompt
type_line '/verefi:execute --name saucedemo-checkout'
sleep 0.4
cat <<'EOF'

Running tests/e2e/saucedemo-checkout.spec.ts ...

  ✓ TC-001 successful login with a valid account
  ✓ TC-002 locked-out account is rejected with a specific error
  ✓ TC-003 invalid credentials are rejected with a specific error
  ✓ TC-004 sorting by price (low to high) reorders the catalog
  ✓ TC-005 adding a product to the cart updates the badge and the button
  ✓ TC-006 removing a product from the cart clears the badge
  ✓ TC-007 cart page lists added items correctly
  ✓ TC-008 checkout step one requires all three fields
  ✓ TC-009 checkout overview shows correct item total, tax, and total
  ✓ TC-010 completing checkout shows a confirmation message
  ✓ TC-011 full purchase happy path, end to end

✓ 11 passed (5.4s)
EOF
sleep 2.0
