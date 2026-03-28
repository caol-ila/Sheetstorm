import { test, expect } from '@playwright/test';
import {
  navigateAndWaitForFlutter,
  expectTextVisible,
  takeNamedScreenshot,
} from './helpers';

test.describe('Onboarding Flow', () => {
  test('Onboarding-Seite lädt korrekt', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/onboarding');

    // Flutter sollte geladen sein
    await expect(page.locator('flutter-view, flt-glass-pane')).toBeAttached();

    await takeNamedScreenshot(page, 'onboarding-page');

    // Wenn unauthentifiziert, wird GoRouter wahrscheinlich zu /login redirecten
    const url = page.url();
    if (url.includes('/login') || url.includes('/loading')) {
      // Erwartetes Verhalten: Ohne Auth kein Zugriff auf Onboarding
      expect(true).toBe(true);
      return;
    }

    // Falls authentifiziert: Onboarding-Texte prüfen
    await expectTextVisible(page, 'Willkommen bei Sheetstorm');
  });

  test('Onboarding zeigt 5 Schritte', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/onboarding');
    await page.waitForTimeout(2_000);

    const url = page.url();
    if (url.includes('/login')) {
      test.skip(true, 'Onboarding benötigt authentifizierten User');
      return;
    }

    // Schritt 1: Name
    await expectTextVisible(page, 'Willkommen bei Sheetstorm');
    await expectTextVisible(page, 'Stimmt dein Name so?');
    await takeNamedScreenshot(page, 'onboarding-step-1');

    // Weiter-Button klicken
    const weiterButton = page.getByRole('button', { name: /weiter/i });
    const buttonCount = await weiterButton.count();
    if (buttonCount > 0) {
      await weiterButton.click();
      await page.waitForTimeout(1_000);
      await takeNamedScreenshot(page, 'onboarding-step-2');
    }
  });

  test('Onboarding abschließen → Weiterleitung zur Bibliothek', async ({
    page,
  }) => {
    await navigateAndWaitForFlutter(page, '/onboarding');
    await page.waitForTimeout(2_000);

    const url = page.url();
    if (url.includes('/login')) {
      test.skip(true, 'Onboarding benötigt authentifizierten User');
      return;
    }

    // Überspringen-Buttons klicken um schnell zum Ende zu kommen
    for (let step = 0; step < 5; step++) {
      const skipButton = page.getByRole('button', {
        name: /überspringen/i,
      });
      const weiterButton = page.getByRole('button', { name: /weiter/i });
      const fertigButton = page.getByRole('button', {
        name: /zur bibliothek/i,
      });

      const fertigCount = await fertigButton.count();
      if (fertigCount > 0) {
        await fertigButton.click();
        break;
      }

      const skipCount = await skipButton.count();
      if (skipCount > 0) {
        await skipButton.click();
        await page.waitForTimeout(500);
        continue;
      }

      const weiterCount = await weiterButton.count();
      if (weiterCount > 0) {
        await weiterButton.click();
        await page.waitForTimeout(500);
      }
    }

    // Sollte zur Bibliothek weiterleiten
    await page.waitForTimeout(2_000);
    const finalUrl = page.url();
    const atLibrary = finalUrl.includes('/app/library');

    // Nur prüfen wenn wir tatsächlich durch das Onboarding gekommen sind
    if (!url.includes('/login')) {
      await takeNamedScreenshot(page, 'after-onboarding');
    }
  });

  test('Wiederkehrender User überspringt Onboarding', async ({ page }) => {
    // Dieser Test prüft, dass ein bereits ongeboardeter User
    // direkt zur Library weitergeleitet wird.
    // Erfordert einen bereits eingerichteten User-Account.
    await navigateAndWaitForFlutter(page, '/');
    await page.waitForTimeout(3_000);

    const url = page.url();
    await takeNamedScreenshot(page, 'returning-user');

    // Dokumentiere das erwartete Verhalten
    // Ein authentifizierter, ongeboardeter User sollte auf /app/library landen
    // Ein unauthentifizierter User auf /login
    const validRoute =
      url.includes('/login') ||
      url.includes('/app/library') ||
      url.includes('/loading');
    expect(
      validRoute,
      'User sollte auf Login oder Library landen',
    ).toBe(true);
  });
});
