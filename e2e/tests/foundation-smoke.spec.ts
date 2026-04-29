import { test, expect } from '@playwright/test';

test.describe('Iteration 0 — Foundation Smoke', () => {
  test('Anonyme Startseite zeigt Sheetstorm-Branding', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(/Sheetstorm/);
    await expect(page.getByRole('heading', { name: 'Sheetstorm', level: 1 })).toBeVisible();
    await expect(page.getByTestId('iteration-status')).toContainText('Sheetstorm');
  });

  test('Anonyme Startseite zeigt Login/Register-CTAs', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('home-login-cta')).toBeVisible();
    await expect(page.getByTestId('home-register-cta')).toBeVisible();
  });
});
