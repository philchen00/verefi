// Known gaps / behavioral findings from discovery (see discovery.md before it's discarded):
// - [Behavioral] agent-browser's real-click delivery was unreliable during discovery (burger-menu
//   button, "Logout" link, "Add to cart") independent of app logic — a JS-dispatched click on the
//   identical element always worked. This looks like discovery-tooling flakiness, not a product
//   defect (Playwright's own .click() already does real actionability/dispatch, unlike the
//   agent-browser path that was flaky). If these interactions are intermittently flaky here too,
//   retry and confirm across more than one run before treating it as an app bug.
// - [Behavioral] The cart badge (`[data-test="shopping-cart-badge"]`) is entirely absent from the
//   DOM when the cart is empty, not just hidden — assertions below use `toHaveCount(0)`, not
//   visibility/text, to match.
// - [Behavioral] The login-page error banner and the checkout-step-one error banner share the same
//   `data-test="error"` value. Not a bug (only one is ever mounted at a time), but each page object
//   below scopes its own `errorMessage` locator rather than sharing one across pages.

import { test, expect, type Page } from '@playwright/test';
import { LoginPage } from './pageObj/LoginPage';
import { InventoryPage } from './pageObj/InventoryPage';
import { CartPage } from './pageObj/CartPage';
import { CheckoutInfoPage } from './pageObj/CheckoutInfoPage';
import { CheckoutOverviewPage } from './pageObj/CheckoutOverviewPage';
import { CheckoutCompletePage } from './pageObj/CheckoutCompletePage';

const BACKPACK_SLUG = 'sauce-labs-backpack';

function requiredE2EEnv(name: 'E2E_USERNAME' | 'E2E_PASSWORD' | 'E2E_LOCKED_USERNAME'): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required test-account environment variable: ${name}`);
  return value;
}

async function loginAsStandardUser(page: Page) {
  const loginPage = new LoginPage(page);
  await loginPage.goto();
  await loginPage.login(requiredE2EEnv('E2E_USERNAME'), requiredE2EEnv('E2E_PASSWORD'));
  await page.waitForURL('**/inventory.html');
}

async function loginAndAddBackpackToCart(page: Page) {
  await loginAsStandardUser(page);
  const inventoryPage = new InventoryPage(page);
  await inventoryPage.addToCart(BACKPACK_SLUG);
  return inventoryPage;
}

test.describe('Login', () => {
  test('TC-001: Successful login with valid standard user', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(requiredE2EEnv('E2E_USERNAME'), requiredE2EEnv('E2E_PASSWORD'));

    await page.waitForURL('**/inventory.html');
    const inventoryPage = new InventoryPage(page);
    await expect(inventoryPage.productCards.first()).toBeVisible();
    await expect(loginPage.errorMessage).toHaveCount(0);
  });

  test('TC-002: Login blocked for a locked-out user', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(requiredE2EEnv('E2E_LOCKED_USERNAME'), requiredE2EEnv('E2E_PASSWORD'));

    await expect(page).toHaveURL(/\/$/);
    await expect(loginPage.errorMessage).toContainText('Epic sadface: Sorry, this user has been locked out.');
  });

  test('TC-003: Login rejected with invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('invalid_user', 'invalid_password');

    await expect(page).toHaveURL(/\/$/);
    await expect(loginPage.errorMessage).toContainText(
      'Epic sadface: Username and password do not match any user in this service',
    );
  });

  test('TC-004a: Login rejected with empty username', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('', requiredE2EEnv('E2E_PASSWORD'));

    await expect(page).toHaveURL(/\/$/);
    await expect(loginPage.errorMessage).toContainText('Epic sadface: Username is required');
  });

  test('TC-004b: Login rejected with empty password', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login(requiredE2EEnv('E2E_USERNAME'), '');

    await expect(page).toHaveURL(/\/$/);
    await expect(loginPage.errorMessage).toContainText('Epic sadface: Password is required');
  });

  test('TC-004c: Login rejected with empty username and password', async ({ page }) => {
    const loginPage = new LoginPage(page);
    await loginPage.goto();
    await loginPage.login('', '');

    await expect(page).toHaveURL(/\/$/);
    await expect(loginPage.errorMessage).toContainText('is required');
  });
});

test.describe('Product Catalog and Sorting', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsStandardUser(page);
  });

  test('TC-005: Product list displays all catalog items after login', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);

    await expect(inventoryPage.productCards).toHaveCount(6);
    await expect(inventoryPage.productNames).toHaveCount(6);
    await expect(inventoryPage.productPrices).toHaveCount(6);
    await expect(inventoryPage.addToCartButtons).toHaveCount(6);
  });

  test('TC-006: Sort products by Name (A to Z)', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);
    await inventoryPage.sortBy('az');

    const names = await inventoryPage.getAllProductNames();
    const sorted = [...names].sort((a, b) => a.localeCompare(b));
    expect(names).toEqual(sorted);
  });

  test('TC-007: Sort products by Name (Z to A)', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);
    await inventoryPage.sortBy('za');

    const names = await inventoryPage.getAllProductNames();
    const sorted = [...names].sort((a, b) => b.localeCompare(a));
    expect(names).toEqual(sorted);
  });

  test('TC-008: Sort products by Price (low to high)', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);
    await inventoryPage.sortBy('lohi');

    const prices = await inventoryPage.getAllProductPrices();
    const sorted = [...prices].sort((a, b) => a - b);
    expect(prices).toEqual(sorted);
  });

  test('TC-009: Sort products by Price (high to low)', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);
    await inventoryPage.sortBy('hilo');

    const prices = await inventoryPage.getAllProductPrices();
    const sorted = [...prices].sort((a, b) => b - a);
    expect(prices).toEqual(sorted);
  });
});

test.describe('Cart and Checkout', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsStandardUser(page);
  });

  test('TC-010: Add a single product to the cart and verify the cart badge', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);

    const addButton = page.getByTestId(`add-to-cart-${BACKPACK_SLUG}`);
    await expect(addButton).toBeVisible();
    await expect(addButton).toBeEnabled();
    await inventoryPage.addToCart(BACKPACK_SLUG);

    await expect(inventoryPage.cartBadge).toHaveText('1');
    await expect(page.getByTestId(`remove-${BACKPACK_SLUG}`)).toBeVisible();
  });

  test('TC-011: Complete end-to-end checkout with one item', async ({ page }) => {
    await loginAndAddBackpackToCart(page);
    const inventoryPage = new InventoryPage(page);

    await inventoryPage.cartLink.click();
    await page.waitForURL('**/cart.html');
    const cartPage = new CartPage(page);
    await expect(cartPage.cartItems).toHaveCount(1);
    await cartPage.checkout();

    await page.waitForURL('**/checkout-step-one.html');
    const checkoutInfoPage = new CheckoutInfoPage(page);
    await checkoutInfoPage.fillInfo('Test', 'User', '94107');
    await checkoutInfoPage.continueToOverview();

    await page.waitForURL('**/checkout-step-two.html');
    const checkoutOverviewPage = new CheckoutOverviewPage(page);
    await checkoutOverviewPage.finish();

    await page.waitForURL('**/checkout-complete.html');
    const checkoutCompletePage = new CheckoutCompletePage(page);
    await expect(checkoutCompletePage.confirmationHeading).toContainText('Thank you for your order!');
    // Cart badge element does not exist in the DOM at all when empty (see discovery.md Section 3) —
    // assert absence via count, not visibility/text.
    await expect(page.getByTestId('shopping-cart-badge')).toHaveCount(0);
  });

  test('TC-012: Checkout blocked when required shipping info is missing', async ({ page }) => {
    await loginAndAddBackpackToCart(page);
    const inventoryPage = new InventoryPage(page);

    await inventoryPage.cartLink.click();
    await page.waitForURL('**/cart.html');
    const cartPage = new CartPage(page);
    await cartPage.checkout();

    await page.waitForURL('**/checkout-step-one.html');
    const checkoutInfoPage = new CheckoutInfoPage(page);
    await checkoutInfoPage.continueToOverview();

    await expect(page).toHaveURL(/\/checkout-step-one\.html$/);
    await expect(checkoutInfoPage.errorMessage).toContainText('Error: First Name is required');
  });

  test('TC-013: Remove a product from the cart before checkout', async ({ page }) => {
    await loginAndAddBackpackToCart(page);
    const inventoryPage = new InventoryPage(page);

    await inventoryPage.cartLink.click();
    await page.waitForURL('**/cart.html');
    const cartPage = new CartPage(page);
    await expect(cartPage.cartItems).toHaveCount(1);
    await cartPage.removeItem(BACKPACK_SLUG);

    await expect(cartPage.cartItems).toHaveCount(0);
    // Cart badge element does not exist in the DOM at all when empty (see discovery.md Section 3).
    await expect(page.getByTestId('shopping-cart-badge')).toHaveCount(0);
  });
});

test.describe('Session', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsStandardUser(page);
  });

  test('TC-014: Logout ends the session and returns to the login page', async ({ page }) => {
    const inventoryPage = new InventoryPage(page);

    await expect(inventoryPage.burgerMenuButton).toBeVisible();
    await inventoryPage.openMenu();
    await expect(inventoryPage.logoutSidebarLink).toBeVisible();
    await inventoryPage.logout();

    await expect(page).toHaveURL(/\/$/);

    await page.goto('/inventory.html');
    await expect(page).toHaveURL(/\/$/);
    const loginPage = new LoginPage(page);
    await expect(loginPage.errorMessage).toContainText(
      "Epic sadface: You can only access '/inventory.html' when you are logged in.",
    );
  });
});
