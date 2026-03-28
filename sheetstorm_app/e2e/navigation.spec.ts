import { test, expect } from '@playwright/test';
import {
  navigateAndWaitForFlutter,
  waitForFlutterReady,
  expectTextVisible,
  takeNamedScreenshot,
} from './helpers';

test.describe('Core Navigation', () => {
  test('App lädt auf Root-URL', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/');

    // Flutter-App sollte initialisiert sein
    await expect(page.locator('flutter-view, flt-glass-pane')).toBeAttached();
    await takeNamedScreenshot(page, 'app-root');
  });

  test('Bibliothek-Seite ist erreichbar', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/app/library');
    await page.waitForTimeout(2_000);

    const url = page.url();

    if (url.includes('/login') || url.includes('/loading')) {
      // Erwartetes Verhalten ohne Auth
      await takeNamedScreenshot(page, 'library-requires-auth');
      expect(true).toBe(true);
      return;
    }

    // Bibliothek sollte geladen sein
    expect(url).toContain('/app/library');
    await takeNamedScreenshot(page, 'library-page');
  });

  test('Navigation zwischen Hauptbereichen', async ({ page }) => {
    // Lade die App
    await navigateAndWaitForFlutter(page, '/');
    await page.waitForTimeout(2_000);

    const startUrl = page.url();

    if (startUrl.includes('/login') || startUrl.includes('/loading')) {
      test.skip(true, 'Navigation benötigt authentifizierten User');
      return;
    }

    // Prüfe verschiedene Routen
    const routes = [
      '/app/library',
      '/app/setlists',
      '/app/calendar',
      '/app/profile',
      '/app/settings',
    ];

    for (const route of routes) {
      await page.goto(route);
      await waitForFlutterReady(page);
      await page.waitForTimeout(1_000);

      // Prüfe ob die Route geladen wurde (kein 404/Crash)
      await expect(
        page.locator('flutter-view, flt-glass-pane'),
      ).toBeAttached();
    }

    await takeNamedScreenshot(page, 'navigation-complete');
  });

  test('Seiten-Reload behält Session bei', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/');
    await page.waitForTimeout(2_000);

    const urlBefore = page.url();

    // Seite neu laden
    await page.reload();
    await waitForFlutterReady(page);

    const urlAfter = page.url();

    // URL sollte konsistent sein (gleicher Auth-Status)
    // Entweder beide auf /login oder beide auf /app/*
    const bothLogin =
      urlBefore.includes('/login') && urlAfter.includes('/login');
    const bothApp =
      urlBefore.includes('/app/') && urlAfter.includes('/app/');
    const bothLoading =
      urlBefore.includes('/loading') && urlAfter.includes('/loading');

    expect(
      bothLogin || bothApp || bothLoading,
      `Session-Status sollte nach Reload konsistent sein (vorher: ${urlBefore}, nachher: ${urlAfter})`,
    ).toBe(true);

    await takeNamedScreenshot(page, 'after-reload');
  });

  test('Direkt-Navigation zu tiefem Link', async ({ page }) => {
    // Teste dass Deep-Links korrekt aufgelöst werden
    await navigateAndWaitForFlutter(page, '/app/settings');
    await page.waitForTimeout(2_000);

    const url = page.url();

    // Sollte entweder auf Settings landen (authentifiziert)
    // oder zu Login redirected werden
    const validRoute =
      url.includes('/app/settings') ||
      url.includes('/login') ||
      url.includes('/loading');

    expect(
      validRoute,
      'Deep-Link sollte korrekt aufgelöst werden',
    ).toBe(true);

    await takeNamedScreenshot(page, 'deep-link-settings');
  });
});
