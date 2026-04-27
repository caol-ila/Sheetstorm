import { test, expect } from '@playwright/test';

test.describe('Iteration 0 — Foundation Smoke', () => {
  test('Startseite zeigt Sheetstorm-Branding und Iterations-Status', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(/Sheetstorm/);

    const heading = page.getByTestId('home-heading');
    await expect(heading).toBeVisible();
    await expect(heading).toHaveText('Sheetstorm');

    const status = page.getByTestId('iteration-status');
    await expect(status).toContainText('0');
    await expect(status).toContainText('Foundation');
  });

  test('Counter-Seite ist erreichbar (Blazor-Routing funktioniert)', async ({ page }) => {
    await page.goto('/counter');
    await expect(page.getByRole('heading', { name: /counter/i })).toBeVisible();
  });
});
