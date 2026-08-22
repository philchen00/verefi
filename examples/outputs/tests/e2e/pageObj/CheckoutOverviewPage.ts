import type { Locator, Page } from '@playwright/test';

export class CheckoutOverviewPage {
  readonly cancelButton: Locator;
  readonly finishButton: Locator;

  constructor(private readonly page: Page) {
    this.cancelButton = page.getByTestId('cancel');
    this.finishButton = page.getByTestId('finish');
  }

  async finish() {
    await this.finishButton.click();
  }
}
