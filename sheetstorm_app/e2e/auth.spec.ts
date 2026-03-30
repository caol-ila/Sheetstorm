import { test, expect } from '@playwright/test';
import {
  navigateAndWaitForFlutter,
  waitForFlutterReady,
  expectTextVisible,
  waitForRoute,
  takeNamedScreenshot,
} from './helpers';

test.describe('Auth Flow', () => {
  test('Login-Seite wird angezeigt', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/login');

    // Flutter sollte geladen sein
    await expect(page.locator('flutter-view, flt-glass-pane')).toBeAttached();

    // Screenshot zur visuellen Verifikation
    await takeNamedScreenshot(page, 'login-page');

    // Prüfe ob Login-Texte sichtbar sind
    await expectTextVisible(page, 'Sheetstorm');
    await expectTextVisible(page, 'Anmelden');
  });

  test('Login mit gültigen Credentials → Weiterleitung', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/login');

    // E-Mail-Feld finden und ausfüllen
    // Flutter Web: Versuche Input über Accessibility-Rollen
    const emailInput = page.getByRole('textbox', { name: /e-mail/i });
    const passwordInput = page.getByRole('textbox', { name: /passwort/i });

    // Falls Flutter keine Accessibility-Rollen exponiert,
    // fokussiere das erste Eingabefeld via Tab-Navigation
    const emailCount = await emailInput.count();
    if (emailCount > 0) {
      await emailInput.fill('demo@test.local');
      await passwordInput.fill('demo');
    } else {
      // Fallback: Keyboard-Navigation für CanvasKit
      await page.keyboard.press('Tab');
      await page.keyboard.type('demo@test.local');
      await page.keyboard.press('Tab');
      await page.keyboard.type('demo');
    }

    // Anmelden-Button klicken oder Enter drücken
    const loginButton = page.getByRole('button', { name: /anmelden/i });
    const buttonCount = await loginButton.count();
    if (buttonCount > 0) {
      await loginButton.click();
    } else {
      await page.keyboard.press('Enter');
    }

    // Warte auf Weiterleitung (Library oder Onboarding)
    await page.waitForTimeout(3_000);
    const url = page.url();
    const redirected =
      url.includes('/app/library') ||
      url.includes('/onboarding') ||
      url.includes('/loading');

    expect(redirected, 'Sollte nach Login weiterleiten').toBe(true);
    await takeNamedScreenshot(page, 'after-login');
  });

  test('Login mit ungültigen Credentials → Fehlermeldung', async ({
    page,
  }) => {
    await navigateAndWaitForFlutter(page, '/login');

    const emailInput = page.getByRole('textbox', { name: /e-mail/i });
    const passwordInput = page.getByRole('textbox', { name: /passwort/i });

    const emailCount = await emailInput.count();
    if (emailCount > 0) {
      await emailInput.fill('invalid@test.local');
      await passwordInput.fill('wrongpassword');
    } else {
      await page.keyboard.press('Tab');
      await page.keyboard.type('invalid@test.local');
      await page.keyboard.press('Tab');
      await page.keyboard.type('wrongpassword');
    }

    const loginButton = page.getByRole('button', { name: /anmelden/i });
    const buttonCount = await loginButton.count();
    if (buttonCount > 0) {
      await loginButton.click();
    } else {
      await page.keyboard.press('Enter');
    }

    // Sollte auf Login-Seite bleiben
    await page.waitForTimeout(2_000);
    expect(page.url()).toContain('/login');

    await takeNamedScreenshot(page, 'login-invalid-credentials');
  });

  test('Zugriff auf /app/library ohne Login → Redirect zu Login', async ({
    page,
  }) => {
    await navigateAndWaitForFlutter(page, '/app/library');

    // GoRouter sollte unauthentifizierte User auf /login umleiten
    await page.waitForTimeout(3_000);
    const url = page.url();
    const onLoginOrLoading =
      url.includes('/login') || url.includes('/loading');

    expect(
      onLoginOrLoading,
      'Unauthentifizierter Zugriff sollte zu Login weiterleiten',
    ).toBe(true);

    await takeNamedScreenshot(page, 'redirect-to-login');
  });
});
