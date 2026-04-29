import { test, expect } from '@playwright/test';

test.describe('Iteration 14/15 — Push & Polish (Smoke)', () => {

  test('VAPID-Public-Key-Endpoint antwortet', async ({ page }) => {
    await page.goto('/');
    const r = await page.request.get('/api/push/vapid-public-key');
    expect([200, 204]).toContain(r.status());
  });

  test('Push-Card sichtbar im Profil', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await page.goto('/Account/Profile');
    await expect(page.getByTestId('push-card')).toBeVisible();
  });

  test('Theme-Toggle Button vorhanden in der Topbar (eingeloggt)', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page.getByTestId('theme-toggle')).toBeVisible({ timeout: 15000 });
  });
});
