import type { Locator, Page } from '@playwright/test';

export class InventoryPage {
  readonly productCards: Locator;
  readonly productNames: Locator;
  readonly productPrices: Locator;
  readonly addToCartButtons: Locator;
  readonly sortDropdown: Locator;
  readonly cartBadge: Locator;
  readonly cartLink: Locator;
  readonly allItemsSidebarLink: Locator;
  readonly logoutSidebarLink: Locator;
  // Fallback locator (no data-test attribute — see discovery.md Section 2 Gap TC-014):
  // role-based, confirmed to resolve to exactly one element live, but lower-confidence
  // than a real test-id since it depends on the accessible name staying "Open Menu".
  readonly burgerMenuButton: Locator;

  constructor(private readonly page: Page) {
    this.productCards = page.locator('.inventory_item');
    this.productNames = page.getByTestId('inventory-item-name');
    this.productPrices = page.getByTestId('inventory-item-price');
    this.addToCartButtons = page.getByTestId(/^add-to-cart-/);
    this.sortDropdown = page.getByTestId('product-sort-container');
    this.cartBadge = page.getByTestId('shopping-cart-badge');
    this.cartLink = page.getByTestId('shopping-cart-link');
    this.allItemsSidebarLink = page.getByTestId('inventory-sidebar-link');
    this.logoutSidebarLink = page.getByTestId('logout-sidebar-link');
    this.burgerMenuButton = page.getByRole('button', { name: 'Open Menu' });
  }

  async goto() {
    await this.page.goto('/inventory.html');
  }

  async addToCart(productSlug: string) {
    const button = this.page.getByTestId(`add-to-cart-${productSlug}`);
    await button.click();
  }

  async removeFromCart(productSlug: string) {
    const button = this.page.getByTestId(`remove-${productSlug}`);
    await button.click();
  }

  async sortBy(value: 'az' | 'za' | 'lohi' | 'hilo') {
    await this.sortDropdown.selectOption({ value });
  }

  async getAllProductNames(): Promise<string[]> {
    return this.productNames.allTextContents();
  }

  async getAllProductPrices(): Promise<number[]> {
    const texts = await this.productPrices.allTextContents();
    return texts.map((text) => Number.parseFloat(text.replace('$', '')));
  }

  async openMenu() {
    await this.burgerMenuButton.click();
  }

  async logout() {
    await this.logoutSidebarLink.click();
  }
}
