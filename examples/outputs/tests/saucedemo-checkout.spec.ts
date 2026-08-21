import { test, expect, type Page } from '@playwright/test';

// Swag Labs instruments its UI with `data-test`, not `data-testid` — confirmed
// in discovery.md (the Test ID attribute field), which is why this uses an explicit
// locator helper instead of page.getByTestId() (defaults to `data-testid`).
function byTest(page: Page, value: string) {
  return page.locator(`[data-test="${value}"]`);
}

function requiredE2EEnv(name: 'E2E_USERNAME' | 'E2E_PASSWORD' | 'E2E_LOCKED_OUT_USERNAME' | 'E2E_INVALID_PASSWORD'): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required dedicated-test-account environment variable: ${name}`);
  return value;
}

async function login(page: Page, username: string, password: string) {
  await page.goto('/');
  await byTest(page, 'username').fill(username);
  await byTest(page, 'password').fill(password);
  await byTest(page, 'login-button').click();
}

async function loginAsValidUser(page: Page) {
  await login(page, requiredE2EEnv('E2E_USERNAME'), requiredE2EEnv('E2E_PASSWORD'));
}

test.describe('Login', () => {
  test('TC-001: successful login with a valid account', async ({ page }) => {
    await loginAsValidUser(page);

    await page.waitForURL('**/inventory.html');
    await expect(byTest(page, 'title')).toHaveText('Products');

    const cards = byTest(page, 'inventory-item');
    await expect(cards).toHaveCount(6);
    for (const card of await cards.all()) {
      await expect(card).toBeVisible();
    }
  });

  test('TC-002: locked-out account is rejected with a specific error', async ({ page }) => {
    await login(page, requiredE2EEnv('E2E_LOCKED_OUT_USERNAME'), requiredE2EEnv('E2E_PASSWORD'));

    await expect(page).toHaveURL(/\/$/);
    await expect(byTest(page, 'error')).toHaveText(
      'Epic sadface: Sorry, this user has been locked out.'
    );
  });

  test('TC-003: invalid credentials are rejected with a specific error', async ({ page }) => {
    await login(page, requiredE2EEnv('E2E_USERNAME'), requiredE2EEnv('E2E_INVALID_PASSWORD'));

    await expect(page).toHaveURL(/\/$/);
    await expect(byTest(page, 'error')).toHaveText(
      'Epic sadface: Username and password do not match any user in this service'
    );
  });
});

test.describe('Product Catalog', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsValidUser(page);
    await page.waitForURL('**/inventory.html');
  });

  test('TC-004: sorting by price (low to high) reorders the catalog', async ({ page }) => {
    const namesBeforeSort = await byTest(page, 'inventory-item-name').allTextContents();

    await byTest(page, 'product-sort-container').selectOption('lohi');

    await expect(byTest(page, 'inventory-item')).toHaveCount(6);
    const namesAfterSort = await byTest(page, 'inventory-item-name').allTextContents();
    expect(new Set(namesAfterSort)).toEqual(new Set(namesBeforeSort)); // same 6 products, no drops/dupes

    const prices = await byTest(page, 'inventory-item-price').allTextContents();
    const values = prices.map((p) => parseFloat(p.replace('$', '')));
    expect(values).toEqual([...values].sort((a, b) => a - b));
    expect(values[0]).toBe(7.99);
    expect(values[values.length - 1]).toBe(49.99);
  });

  test('TC-005: adding a product to the cart updates the badge and the button', async ({ page }) => {
    const addButton = byTest(page, 'add-to-cart-sauce-labs-backpack');
    await expect(addButton).toBeVisible();
    await addButton.click();

    await expect(byTest(page, 'shopping-cart-badge')).toHaveText('1');
    await expect(byTest(page, 'remove-sauce-labs-backpack')).toHaveText('Remove');
  });

  test('TC-006: removing a product from the cart clears the badge', async ({ page }) => {
    await byTest(page, 'add-to-cart-sauce-labs-backpack').click();
    await expect(byTest(page, 'shopping-cart-badge')).toHaveText('1');

    await byTest(page, 'remove-sauce-labs-backpack').click();

    await expect(byTest(page, 'shopping-cart-badge')).toHaveCount(0);
    await expect(byTest(page, 'add-to-cart-sauce-labs-backpack')).toHaveText('Add to cart');
  });
});

test.describe('Cart', () => {
  test('TC-007: cart page lists added items correctly', async ({ page }) => {
    await loginAsValidUser(page);
    await page.waitForURL('**/inventory.html');
    await byTest(page, 'add-to-cart-sauce-labs-backpack').click();

    await byTest(page, 'shopping-cart-link').click();

    await page.waitForURL('**/cart.html');
    await expect(byTest(page, 'inventory-item-name')).toHaveText('Sauce Labs Backpack');
    await expect(byTest(page, 'inventory-item-price')).toHaveText('$29.99');
    await expect(byTest(page, 'item-quantity')).toHaveText('1');
  });
});

test.describe('Checkout', () => {
  async function addBackpackAndGoToCheckoutStepOne(page: Page) {
    await loginAsValidUser(page);
    await page.waitForURL('**/inventory.html');
    await byTest(page, 'add-to-cart-sauce-labs-backpack').click();
    await byTest(page, 'shopping-cart-link').click();
    await page.waitForURL('**/cart.html');
    await byTest(page, 'checkout').click();
    await page.waitForURL('**/checkout-step-one.html');
  }

  test('TC-008: checkout step one requires all three fields', async ({ page }) => {
    await addBackpackAndGoToCheckoutStepOne(page);

    // All fields blank
    await byTest(page, 'continue').click();
    await expect(page).toHaveURL(/\/checkout-step-one\.html$/);
    await expect(byTest(page, 'error')).toHaveText('Error: First Name is required');

    // First Name filled, Last Name and Postal Code still blank
    await byTest(page, 'firstName').fill('Jane');
    await byTest(page, 'continue').click();
    await expect(byTest(page, 'error')).toHaveText('Error: Last Name is required');

    // First Name and Last Name filled, Postal Code still blank
    await byTest(page, 'lastName').fill('Doe');
    await byTest(page, 'continue').click();
    await expect(byTest(page, 'error')).toHaveText('Error: Postal Code is required');
  });

  test('TC-009: checkout overview shows correct item total, tax, and total', async ({ page }) => {
    await addBackpackAndGoToCheckoutStepOne(page);

    await byTest(page, 'firstName').fill('Jane');
    await byTest(page, 'lastName').fill('Doe');
    await byTest(page, 'postalCode').fill('94107');
    await byTest(page, 'continue').click();

    await page.waitForURL('**/checkout-step-two.html');
    await expect(byTest(page, 'subtotal-label')).toHaveText('Item total: $29.99');
    await expect(byTest(page, 'tax-label')).toHaveText('Tax: $2.40');
    await expect(byTest(page, 'total-label')).toHaveText('Total: $32.39');
  });

  test('TC-010: completing checkout shows a confirmation message', async ({ page }) => {
    await addBackpackAndGoToCheckoutStepOne(page);
    await byTest(page, 'firstName').fill('Jane');
    await byTest(page, 'lastName').fill('Doe');
    await byTest(page, 'postalCode').fill('94107');
    await byTest(page, 'continue').click();
    await page.waitForURL('**/checkout-step-two.html');

    await byTest(page, 'finish').click();

    await page.waitForURL('**/checkout-complete.html');
    await expect(byTest(page, 'complete-header')).toHaveText('Thank you for your order!');
    await expect(byTest(page, 'back-to-products')).toBeVisible();
  });
});

test.describe('End to End', () => {
  test('TC-011: full purchase happy path, end to end', async ({ page }) => {
    await loginAsValidUser(page);
    await page.waitForURL('**/inventory.html');
    await expect(byTest(page, 'error')).toHaveCount(0);

    await byTest(page, 'add-to-cart-sauce-labs-backpack').click();
    await byTest(page, 'shopping-cart-link').click();
    await page.waitForURL('**/cart.html');
    await expect(byTest(page, 'error')).toHaveCount(0);

    await byTest(page, 'checkout').click();
    await page.waitForURL('**/checkout-step-one.html');
    await expect(byTest(page, 'error')).toHaveCount(0);
    await byTest(page, 'firstName').fill('Jane');
    await byTest(page, 'lastName').fill('Doe');
    await byTest(page, 'postalCode').fill('94107');
    await byTest(page, 'continue').click();

    await page.waitForURL('**/checkout-step-two.html');
    await expect(byTest(page, 'error')).toHaveCount(0);
    await byTest(page, 'finish').click();

    await page.waitForURL('**/checkout-complete.html');
    await expect(byTest(page, 'error')).toHaveCount(0);
    await expect(byTest(page, 'complete-header')).toHaveText('Thank you for your order!');
  });
});
