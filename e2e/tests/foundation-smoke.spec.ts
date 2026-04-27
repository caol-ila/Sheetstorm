import { test, expect } from '@playwright/test';

test.describe('Iteration 0 — Foundation Smoke', () => {
  test('Startseite zeigt Sheetstorm-Branding und Iterations-Status', async ({ page }) => {
    await page.goto('/');

    await expect(page).toHaveTitle(/Sheetstorm/);

    const heading = page.getByTestId('home-heading');
    await expect(heading).toBeVisible();
    await expect(heading).toHaveText('Sheetstorm');

    const status = page.getByTestId('iteration-status');
    await expect(status).toContainText('2');
    await expect(status).toContainText('Notenmanagement');
  });

  test('Counter-Seite ist nicht öffentlich (entfernt in iter-1) — anonymer Zugriff auf "/" funktioniert', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('home-anonymous')).toBeVisible();
  });
});
