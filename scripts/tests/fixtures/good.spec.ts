// Fixture spec for scripts/check-invariants.sh — matches plan-tiered.md.
// TC-003 legitimately splits into two tests (TC-003a/b) to show that the
// invariant compares test-case ids, never test counts.
import { test, expect } from '@playwright/test';

test.describe('Fixture', () => {
  test('TC-001: critical flow that must be read by a human', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('result')).toBeVisible();
  });

  test('TC-002: verified low-priority read-only case', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('error')).toHaveText('nope');
  });

  test('TC-003a: another verified case, first half', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('list')).toHaveCount(1);
  });

  test('TC-003b: another verified case, second half', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('list')).toHaveCount(1);
  });
});
