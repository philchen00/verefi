import type { Locator, Page } from '@playwright/test';

export class CartPage {
  readonly cartItems: Locator;
  readonly continueShoppingButton: Locator;
  readonly checkoutButton: Locator;

  constructor(private readonly page: Page) {
    this.cartItems = page.locator('.cart_item');
    this.continueShoppingButton = page.getByTestId('continue-shopping');
    this.checkoutButton = page.getByTestId('checkout');
  }

  async removeItem(productSlug: string) {
    await this.page.getByTestId(`remove-${productSlug}`).click();
  }

  async checkout() {
    await this.checkoutButton.click();
  }
}
