import { test, expect } from '@playwright/test';

test.describe('Iteration 7 — UX & Demo', () => {

  test('Anonyme Startseite zeigt Hero + Demo-CTA + Feature-Cards', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Sheetstorm', level: 1 })).toBeVisible();
    await expect(page.getByTestId('home-register-cta')).toBeVisible();
    await expect(page.getByTestId('home-login-cta')).toBeVisible();
    await expect(page.getByTestId('home-demo-cta')).toBeVisible();
  });

  test('Demo-Seite erklärt Rollen + verlinkt auf vorbereitete Logins', async ({ page }) => {
    await page.goto('/demo');
    await expect(page.getByTestId('demo-heading')).toBeVisible();
    await expect(page.getByTestId('demo-role-musician')).toBeVisible();
    await expect(page.getByTestId('demo-role-conductor')).toBeVisible();
    await expect(page.getByTestId('demo-role-admin')).toBeVisible();

    // Klick auf "Als Maria einloggen" füllt Email-Feld vor
    await page.getByTestId('demo-login-musician').click();
    await expect(page).toHaveURL(/email=maria@demo.local/);
    await expect(page.getByTestId('login-email')).toHaveValue('maria@demo.local');
  });

  test('Login-Page hat Demo-Quick-Links Panel', async ({ page }) => {
    await page.goto('/Account/Login');
    await expect(page.getByTestId('login-demo-panel')).toBeVisible();
    await expect(page.getByTestId('demo-prefill-conductor')).toBeVisible();
    await expect(page.getByTestId('demo-prefill-musician')).toBeVisible();
  });

  test('Topbar zeigt Brand und Auth-Buttons (anonym)', async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('brand')).toBeVisible();
    await expect(page.getByTestId('nav-login')).toBeVisible();
    await expect(page.getByTestId('nav-register')).toBeVisible();
  });

  test('Eingeloggter User: Topbar mit Verein-Switcher und Topnav', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await expect(page.getByTestId('home-greeting')).toBeVisible();
    await expect(page.getByTestId('user-profile')).toBeVisible();
    await expect(page.getByTestId('logout-button')).toBeVisible();

    // Home zeigt Verein-Karte
    await expect(page.getByTestId('home-band-card').first()).toBeVisible();

    // Verein öffnen
    await page.getByTestId('home-band-card').first().click();

    // Topbar: Switcher + Topnav sichtbar
    await expect(page.getByTestId('band-switcher')).toBeVisible();
    await expect(page.getByTestId('band-switcher-select')).toHaveValue('demo');
  });

  test('Verein-Switcher navigiert', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Bands/demo/pieces');
    await expect(page.getByTestId('band-switcher-select')).toHaveValue('demo');
  });
});
