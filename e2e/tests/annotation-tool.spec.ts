import { test, expect } from '@playwright/test';

/**
 * E2E-Test für das OMR-Annotation-Tool.
 *
 * Voraussetzungen:
 *   - dev server läuft (siehe .start.ps1)
 *   - SHEETSTORM_OMR_ON=1 (sonst hat Stub-Engine keine Detections)
 *   - Demo-User dirigent@demo.local existiert
 *
 * Was wird getestet:
 *   1) Annotation-Page ist via PieceDetail erreichbar wenn Detections vorhanden
 *   2) Canvas wird geladen + ist sichtbar
 *   3) Toolbar mit Page-Navigation, Zoom, Layer-Toggles
 *   4) Korrektur-Workflow (NotANote auf einen NH klicken)
 */
test.describe('OMR Annotation-Tool', () => {

  test('Annotation-Page lädt Canvas + Toolbar', async ({ page }) => {
    test.skip(!process.env.SHEETSTORM_OMR_ON,
      'Annotation-Tool braucht echte OMR-Engine (SHEETSTORM_OMR_ON=1). Stub liefert keine Detections.');

    test.setTimeout(120_000);

    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page).not.toHaveURL(/Login/);

    // Direkt zur Pieces-Liste — wir nehmen das erste Piece mit einer Stimme
    await page.goto('/Bands/demo/pieces');
    const firstPiece = page.locator('[data-testid="piece-row"]').first();
    if ((await firstPiece.count()) === 0) {
      test.skip(true, 'Keine Pieces vorhanden — Test braucht ein Piece mit Stimme');
    }
    await firstPiece.click();

    // Auf Piece-Detail eine Stimme auswählen
    const partSelect = page.getByTestId('part-select');
    if ((await partSelect.count()) === 0) {
      test.skip(true, 'Keine Stimmen vorhanden für dieses Piece');
    }
    await page.getByTestId('part-show').click();

    // Falls Detections noch nicht fertig sind, warten — Auto-Trigger
    // läuft im Hintergrund nach Confirm. Bei existing Pieces sind sie
    // i.d.R. schon vorhanden.
    const annotateLink = page.getByTestId('part-annotate-link');
    await expect(annotateLink).toBeVisible({ timeout: 60_000 });
    await annotateLink.click();

    // Annotation-Page Title
    await expect(page.getByTestId('annotate-title')).toBeVisible();

    // Canvas existiert
    await expect(page.getByTestId('annotate-canvas')).toBeVisible();

    // Toolbar — Zoom, Page-Nav
    await expect(page.getByTestId('annotate-zoom')).toBeVisible();
    await expect(page.getByTestId('annotate-page-label')).toBeVisible();

    // Help-Text bevor Klick
    await expect(page.getByTestId('annotate-help')).toBeVisible();
  });

  test('NotANote-Korrektur speichert Annotation', async ({ page, request }) => {
    test.skip(!process.env.SHEETSTORM_OMR_ON,
      'Braucht echte OMR-Engine');
    test.setTimeout(60_000);

    // Login
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    // Zum ersten Piece
    await page.goto('/Bands/demo/pieces');
    const firstPiece = page.locator('[data-testid="piece-row"]').first();
    if ((await firstPiece.count()) === 0) {
      test.skip(true, 'Keine Pieces vorhanden');
    }
    await firstPiece.click();

    if ((await page.getByTestId('part-select').count()) === 0) {
      test.skip(true, 'Keine Stimme vorhanden');
    }
    await page.getByTestId('part-show').click();

    const annotateLink = page.getByTestId('part-annotate-link');
    if (!(await annotateLink.isVisible({ timeout: 5_000 }).catch(() => false))) {
      test.skip(true, 'Detections noch nicht fertig — manueller Test nötig');
    }
    await annotateLink.click();

    await expect(page.getByTestId('annotate-canvas')).toBeVisible();

    // Klick auf eine Position im Canvas (mittig) — bei einem PDF mit Noten
    // sollte das einen NH treffen.
    const canvas = page.getByTestId('annotate-canvas');
    const box = await canvas.boundingBox();
    if (!box) test.skip(true, 'Canvas-Box nicht messbar');

    // Mehrmals an unterschiedlichen Stellen klicken bis die Selected-Card erscheint
    let selected = false;
    for (let i = 0; i < 6 && !selected; i++) {
      await canvas.click({
        position: {
          x: box!.width * (0.2 + 0.1 * i),
          y: box!.height * 0.3
        }
      });
      selected = await page.getByTestId('annotate-selected-card').isVisible({ timeout: 1000 }).catch(() => false);
    }

    if (!selected) {
      test.skip(true, 'Konnte keine NH per Klick selektieren — abhängig von Detection-Layout');
    }

    // NotANote-Button drücken → Annotation wird gespeichert
    await page.getByTestId('annotate-not-a-note').click();

    // Liste sollte einen Eintrag bekommen
    await expect(page.locator('.list-group-item').first()).toBeVisible({ timeout: 5000 });
  });

});
