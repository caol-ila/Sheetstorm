import { test, expect } from '@playwright/test';
import * as path from 'node:path';

/**
 * End-to-End Audiveris-Erkennung.
 *
 * Voraussetzung: Audiveris-Container läuft auf Audiveris__BaseUrl (Default
 * http://localhost:8090). Wenn nicht, AUDIVERIS_ON nicht setzen → Test wird
 * geskipped.
 */

const FIXTURE_PDF = path.join(__dirname, '..', 'fixtures', 'Dichterliebe01.pdf');

test.describe('Audiveris E2E — PDF zu MusicXML', () => {

  test('Dirigent lädt PDF hoch + Audiveris erkennt + Score zeigt sich', async ({ browser }) => {
    test.skip(!process.env.AUDIVERIS_ON, 'AUDIVERIS_ON env var setzen wenn Audiveris-Container läuft.');
    test.setTimeout(15 * 60_000); // bis 15 min für die Erkennung

    const ctx = await browser.newContext({
      ignoreHTTPSErrors: true,
      storageState: { cookies: [], origins: [{ origin: process.env.E2E_WEB_URL!, localStorage: [{ name: 'sheetstorm-tour-done', value: '1' }] }] },
    });
    const page = await ctx.newPage();

    // 1) Login Demo
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page.getByTestId('home-greeting')).toBeVisible();

    // 2) Werk anlegen
    await page.goto('/Bands/demo/pieces');
    const title = 'Audiveris-Test ' + Date.now();
    await page.getByTestId('newpiece-title').fill(title);
    await page.getByTestId('newpiece-composer').fill('Robert Schumann');
    await page.getByTestId('newpiece-genre').fill('Klavierlied');
    await page.getByTestId('newpiece-difficulty').fill('4');
    await page.getByTestId('newpiece-submit').click();

    // Detail-Seite
    await expect(page.getByTestId('piece-detail-title')).toHaveText(title);

    // 3) Stimme hinzufügen mit echtem PDF
    await page.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('addpart-displayname').fill('Klavier-Stimme');
    await page.getByTestId('addpart-file').setInputFiles(FIXTURE_PDF);
    await page.getByTestId('addpart-submit').click();

    // Stimme erscheint
    await expect(page.getByTestId('part-select')).toBeVisible({ timeout: 15000 });
    await page.getByTestId('part-show').click();

    // 4) Viewer ist da, hat noch keine MusicXML, "Audiveris-Erkennung"-Knopf sichtbar
    await expect(page.getByTestId('viewer-stage')).toBeVisible();
    const startBtn = page.getByTestId('run-audiveris');
    await expect(startBtn).toBeVisible({ timeout: 10000 });

    // 5) Klick — Hintergrund-Job läuft. Erst kurz warten dass Blazor-Circuit
    // wirklich connected ist (toolbar + button-state interaktiv reagieren).
    await page.waitForTimeout(2500);
    await startBtn.click();

    // Banner erscheint nach Server-Roundtrip — geben dem ein paar Sekunden
    await expect(page.getByTestId('run-audiveris-result')).toBeVisible({ timeout: 30000 });

    // 6) Auf Score-Modus warten (max 10 min). Wenn Audiveris erfolgreich ist,
    // reloadet die Page automatisch und zeigt den Score-Mode-Button.
    await expect(page.getByTestId('viewer-mode-score')).toBeVisible({ timeout: 10 * 60_000 });

    // 7) Score-Host muss da sein
    const scoreHost = page.locator('[data-testid="score-host"]');
    expect(await scoreHost.count()).toBeGreaterThan(0);

    await ctx.close();
  });
});
