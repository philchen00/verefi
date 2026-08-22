import type { Locator, Page } from '@playwright/test';

export class CheckoutCompletePage {
  readonly confirmationHeading: Locator;
  readonly confirmationText: Locator;
  readonly backHomeButton: Locator;

  constructor(private readonly page: Page) {
    this.confirmationHeading = page.getByTestId('complete-header');
    this.confirmationText = page.getByTestId('complete-text');
    this.backHomeButton = page.getByTestId('back-to-products');
  }
}
