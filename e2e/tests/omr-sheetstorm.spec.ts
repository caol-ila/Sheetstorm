import { test, expect } from '@playwright/test';
import * as path from 'node:path';

/**
 * End-to-End Sheetstorm-OMR-Engine (Rust) — PDF zu MusicXML.
 *
 * Voraussetzung:
 *   - Sheetstorm-OMR-Container läuft auf Omr__BaseUrl (Default http://localhost:8092)
 *   - Sheetstorm.Web mit Omr__Provider=sheetstorm gestartet
 *
 * Wenn der Container fehlt → SHEETSTORM_OMR_ON nicht setzen → Test wird geskipped.
 *
 * Vorteile gegenüber Audiveris-Test:
 *   - Erkennung läuft viel schneller (1-3s statt 30-60s)
 *   - Keine 10-Minuten-Timeouts
 */

const FIXTURE_PDF = path.join(__dirname, '..', 'fixtures', 'Dichterliebe01.pdf');

test.describe('Sheetstorm-OMR E2E — PDF zu MusicXML (Rust-Engine)', () => {

  test('Dirigent lädt PDF hoch + Sheetstorm-OMR erkennt + Score zeigt sich', async ({ browser }) => {
    test.skip(!process.env.SHEETSTORM_OMR_ON, 'SHEETSTORM_OMR_ON env var setzen wenn der Rust-OMR-Container läuft.');
    test.setTimeout(2 * 60_000); // 2 min sollten weit reichen

    const ctx = await browser.newContext({
      ignoreHTTPSErrors: true,
      storageState: {
        cookies: [],
        origins: [{
          origin: process.env.E2E_WEB_URL!,
          localStorage: [{ name: 'sheetstorm-tour-done', value: '1' }]
        }]
      },
    });
    const page = await ctx.newPage();

    // 1) Login
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page.getByTestId('home-greeting')).toBeVisible();

    // 2) Werk anlegen
    await page.goto('/Bands/demo/pieces');
    const title = 'Sheetstorm-OMR-Test ' + Date.now();
    await page.getByTestId('newpiece-title').fill(title);
    await page.getByTestId('newpiece-composer').fill('Robert Schumann');
    await page.getByTestId('newpiece-genre').fill('Klavierlied');
    await page.getByTestId('newpiece-difficulty').fill('4');
    await page.getByTestId('newpiece-submit').click();
    await expect(page.getByTestId('piece-detail-title')).toHaveText(title);

    // 3) Stimme mit PDF anlegen
    await page.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('addpart-displayname').fill('Klavier-Stimme');
    await page.getByTestId('addpart-file').setInputFiles(FIXTURE_PDF);
    await page.getByTestId('addpart-submit').click();

    await expect(page.getByTestId('part-select')).toBeVisible({ timeout: 15000 });
    await page.getByTestId('part-show').click();

    // 4) Viewer + OMR-Button sichtbar
    await expect(page.getByTestId('viewer-stage')).toBeVisible();
    const startBtn = page.getByTestId('run-audiveris'); // Button-Name beibehalten — Provider-agnostisch
    await expect(startBtn).toBeVisible({ timeout: 10000 });

    // 5) Klick — wir warten bis der Blazor-Circuit interaktiv ist
    await page.waitForTimeout(2500);
    await startBtn.click();

    await expect(page.getByTestId('run-audiveris-result')).toBeVisible({ timeout: 30000 });

    // 6) Score-Modus binnen 60s (Sheetstorm-OMR ist viel schneller als Audiveris)
    await expect(page.getByTestId('viewer-mode-score')).toBeVisible({ timeout: 60_000 });

    // 7) Score-Host muss da sein
    const scoreHost = page.locator('[data-testid="score-host"]');
    expect(await scoreHost.count()).toBeGreaterThan(0);

    await ctx.close();
  });

  test('Health-Endpoint des OMR-Containers antwortet sofort', async ({ request }) => {
    test.skip(!process.env.SHEETSTORM_OMR_ON, 'SHEETSTORM_OMR_ON env var setzen.');
    const baseUrl = process.env.OMR_BASE_URL || 'http://localhost:8092';
    const resp = await request.get(`${baseUrl}/health`);
    expect(resp.status()).toBe(200);
    const body = await resp.json();
    expect(body.ok).toBe(true);
    expect(body.engine).toBe('sheetstorm-omr');
    expect(body.capabilities).toContain('musicxml-4.0');
  });

  test('Direkter API-Call /recognize liefert MusicXML', async ({ request }) => {
    test.skip(!process.env.SHEETSTORM_OMR_ON, 'SHEETSTORM_OMR_ON env var setzen.');
    test.setTimeout(60_000);
    const baseUrl = process.env.OMR_BASE_URL || 'http://localhost:8092';
    const fs = await import('node:fs/promises');
    const buf = await fs.readFile(FIXTURE_PDF);
    const resp = await request.post(`${baseUrl}/recognize`, {
      multipart: {
        file: {
          name: 'Dichterliebe01.pdf',
          mimeType: 'application/pdf',
          buffer: buf,
        },
      },
    });
    expect(resp.status()).toBe(200);
    const xml = await resp.text();
    expect(xml).toContain('<?xml');
    expect(xml).toContain('<score-partwise');
    expect(xml).toContain('<step>');
  });
});
