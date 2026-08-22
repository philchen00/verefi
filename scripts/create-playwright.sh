#!/usr/bin/env bash
#
# Ensure a Git target repository has one root-level Playwright setup. This
# script deliberately requires an explicit opt-in before it writes files or
# installs packages/browsers.
#
# Usage: VEREFI_ALLOW_INSTALL=1 create-playwright.sh [playwright-version]
#   playwright-version  exact @playwright/test version (default: 1.62.1)
#
# Prints machine-readable lines the calling skill should act on:
#   PLAYWRIGHT_CONFIG=<path>              config to use
#   PLAYWRIGHT_SCAFFOLDED=true             only when a config was created
#   TESTDIR=<path>                         only when scaffolded
#   VEREFI_RUNTIME_GUARD_REQUIRED=true     existing config needs a guard review

set -euo pipefail

PLAYWRIGHT_VERSION="${1:-1.62.1}"
DEFAULT_BASE_URL="${VEREFI_DEV_BASE_URL:-http://127.0.0.1:3000}"

fail() {
  echo "$1" >&2
  exit 2
}

require_regular_or_missing() {
  if [ -L "$1" ]; then
    fail "VEREFI_UNSAFE_SYMLINK=$1"
  fi
}

if ! [[ "$PLAYWRIGHT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.+][A-Za-z0-9.-]+)?$ ]]; then
  fail "VEREFI_INVALID_PLAYWRIGHT_VERSION=$PLAYWRIGHT_VERSION (use an exact version)"
fi

if ! command -v git >/dev/null 2>&1 || ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  fail "VEREFI_TARGET_REPO_REQUIRED=true (run from inside the target Git repository)"
fi

REPO_ROOT="$(cd "$(git rev-parse --show-toplevel)" && pwd -P)"
cd "$REPO_ROOT"

CONFIG_CANDIDATES=(playwright.config.ts playwright.config.js playwright.config.mjs playwright.config.cjs playwright.config.mts playwright.config.cts)

# Existing config → reuse it without mutating the repository or requiring an
# install opt-in. The implementation skill must inspect its testDir and guard.
for config in "${CONFIG_CANDIDATES[@]}"; do
  require_regular_or_missing "$config"
  if [ -f "$config" ]; then
    echo "PLAYWRIGHT_CONFIG=$config"
    echo "VEREFI_RUNTIME_GUARD_REQUIRED=true"
    echo "✓ Existing Playwright config found — reusing it as-is. Inspect its testDir and remote-target guard before running tests."
    exit 0
  fi
done

if [ "${VEREFI_ALLOW_INSTALL:-}" != "1" ]; then
  echo "VEREFI_PERMISSION_REQUIRED=setup" >&2
  echo "This setup can create config files and install @playwright/test plus Chromium." >&2
  echo "Review the target repository, then re-run with VEREFI_ALLOW_INSTALL=1." >&2
  exit 2
fi

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  fail "VEREFI_NODE_AND_NPM_REQUIRED=true"
fi

for target in .gitignore package.json package-lock.json tests tests/e2e tests/e2e/pageObj; do
  require_regular_or_missing "$target"
done

if [ -e pnpm-lock.yaml ] || [ -e yarn.lock ] || [ -e bun.lock ] || [ -e bun.lockb ]; then
  fail "VEREFI_PACKAGE_MANAGER_UNSUPPORTED=true (this MVP scaffolder supports npm only; use your package manager manually)"
fi

# Only a loopback value may be baked into generated config. Remote targets are
# supplied at run time through BASE_URL and must pass the config's hostname guard.
if ! DEFAULT_BASE_URL_JSON="$(node -e '
  const raw = process.argv[1];
  try {
    const url = new URL(raw);
    const loopback = new Set(["localhost", "127.0.0.1", "::1", "[::1]"]);
    if (!loopback.has(url.hostname) || url.username || url.password) process.exit(1);
    process.stdout.write(JSON.stringify(url.toString()));
  } catch {
    process.exit(1);
  }
' "$DEFAULT_BASE_URL")"; then
  fail "VEREFI_INVALID_DEV_BASE_URL=true (VEREFI_DEV_BASE_URL must be a credential-free loopback URL)"
fi

# Keep local Verefi artifacts and Playwright output out of the target history.
if [ -f .gitignore ]; then
  for ignore_rule in .verefi/ playwright-report/ test-results/ blob-report/; do
    if ! grep -qxF "$ignore_rule" .gitignore; then
      printf '\n%s\n' "$ignore_rule" >> .gitignore
      echo "✓ Added $ignore_rule to .gitignore"
    fi
  done
else
  printf '%s\n' .verefi/ playwright-report/ test-results/ blob-report/ > .gitignore
  echo "✓ Created .gitignore for Verefi and Playwright artifacts"
fi

# Ensure a root package.json (scaffold a minimal one only for non-JS repos).
if [ ! -f package.json ]; then
  cat > package.json <<'EOF'
{
  "name": "e2e-tests",
  "private": true,
  "version": "0.1.0",
  "engines": {
    "node": ">=22"
  },
  "scripts": {
    "test:e2e": "playwright test"
  }
}
EOF
  echo "✓ Created minimal root package.json (repo had none)"
fi

# Add @playwright/test to the root dependency tree only when it is absent.
if ! node -e "require.resolve('@playwright/test/package.json', { paths: [process.cwd()] })" >/dev/null 2>&1; then
  echo "Installing @playwright/test@$PLAYWRIGHT_VERSION at repo root..."
  npm install --save-dev --save-exact "@playwright/test@$PLAYWRIGHT_VERSION"
fi

if [ "$(uname -s)" = "Linux" ]; then
  npx --no-install playwright install --with-deps chromium
else
  npx --no-install playwright install chromium
fi

# Scaffold the root config and shared test directory.
mkdir -p tests/e2e/pageObj

cat > playwright.config.ts <<EOF
import { defineConfig, devices } from '@playwright/test';

const configuredBaseURL = process.env.BASE_URL ?? $DEFAULT_BASE_URL_JSON;
const target = new URL(configuredBaseURL);
// VEREFI_GUARD_START — kept in sync between scripts/create-playwright.sh and examples/outputs/playwright.config.ts; see plugin-validation.yml's guard-drift check.
const isLoopback = new Set(['localhost', '127.0.0.1', '::1', '[::1]']).has(target.hostname);

if (target.username || target.password) {
  throw new Error('BASE_URL must not contain credentials. Pass credentials through E2E_* environment variables instead.');
}

if (!isLoopback && process.env.E2E_ALLOW_REMOTE !== target.hostname) {
  throw new Error(
    'Refusing to run against a remote target. After explicit approval, set E2E_ALLOW_REMOTE to exactly ' + target.hostname + '.',
  );
}
// VEREFI_GUARD_END

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html', { open: 'never' }]],
  use: {
    baseURL: target.toString(),
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  ],
});
EOF

echo "PLAYWRIGHT_CONFIG=playwright.config.ts"
echo "PLAYWRIGHT_SCAFFOLDED=true"
echo "TESTDIR=tests/e2e"
echo "✓ Scaffolded root Playwright setup (Chromium only for v1)"
echo "  - playwright.config.ts"
echo "  - tests/e2e/"
echo "  - tests/e2e/pageObj/"
