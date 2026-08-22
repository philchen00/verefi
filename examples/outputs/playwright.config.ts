import { defineConfig } from '@playwright/test';

const configuredBaseURL = process.env.BASE_URL ?? 'http://127.0.0.1:3000';
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
  use: {
    baseURL: target.toString(),
    testIdAttribute: 'data-test',
  },
  retries: process.env.CI ? 2 : 0,
  reporter: 'list',
});
