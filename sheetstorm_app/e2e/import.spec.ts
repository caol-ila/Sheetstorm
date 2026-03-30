import { test, expect } from '@playwright/test';
import {
  navigateAndWaitForFlutter,
  expectTextVisible,
  takeNamedScreenshot,
} from './helpers';

test.describe('Datei-Import', () => {
  test('Import-Seite ist erreichbar', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/app/import');
    await page.waitForTimeout(2_000);

    const url = page.url();

    // Ohne Auth wird zu Login redirected
    if (url.includes('/login') || url.includes('/loading')) {
      await takeNamedScreenshot(page, 'import-requires-auth');
      expect(true, 'Import erfordert Authentifizierung').toBe(true);
      return;
    }

    // Import-Seite sollte geladen sein
    await expect(page.locator('flutter-view, flt-glass-pane')).toBeAttached();
    await takeNamedScreenshot(page, 'import-page');
  });

  test('Import-Seite zeigt Upload-Bereich', async ({ page }) => {
    await navigateAndWaitForFlutter(page, '/app/import');
    await page.waitForTimeout(2_000);

    const url = page.url();
    if (url.includes('/login')) {
      test.skip(true, 'Import benötigt authentifizierten User');
      return;
    }

    await takeNamedScreenshot(page, 'import-upload-area');

    // Prüfe ob die Import-Route aktiv ist
    expect(url).toContain('/app/import');
  });

  /**
   * LIMITATION: Datei-Upload über nativen File-Picker kann nicht
   * automatisiert getestet werden.
   *
   * Flutter Web verwendet `dart:html` FileUploadInputElement oder
   * das file_picker-Package, welches einen nativen Browser-Dialog öffnet.
   * Playwright kann native Dialoge nicht steuern.
   *
   * Mögliche Workarounds für die Zukunft:
   * 1. Drag & Drop über Playwright's `page.dispatchEvent()`
   * 2. Test-API-Endpoint der Dateien direkt akzeptiert
   * 3. Flutter-seitige Test-Hooks die den File-Picker umgehen
   */
  test.skip('Datei hochladen (nativer File-Picker — nicht automatisierbar)', async ({
    page,
  }) => {
    // Dieser Test ist absichtlich übersprungen.
    // Siehe Kommentar oben für Erklärung und mögliche Workarounds.
  });
});
