import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import os from 'os';

/**
 * Vollständiger UI-Durchlauf des OMR-Annotation-Tools.
 *
 * **Wichtig**: Alle Pieces dieses Tests beginnen mit "[E2E-TEST]" — der
 * Training-Export-Service filtert solche aus. Damit fließt KEIN Test-Stuff
 * in die Trainings-Daten.
 *
 * Voraussetzungen:
 *   - dev-stack läuft (Aspire mit --enable-omr → echte Detections)
 *   - Demo-User dirigent@demo.local existiert
 *   - Realistisches PDF unter env TEST_PDF_PATH oder default Pfad
 */

const TEST_PIECE_TITLE_PREFIX = '[E2E-TEST] ';
const REAL_PDF = process.env.TEST_PDF_PATH
  ?? 'C:\\Users\\tmahlberg\\OneDrive\\Noten\\Anja\\Labeled\\BAVARIA.pdf';

test.describe('Annotation-Tool — vollständiger Workflow', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page).not.toHaveURL(/Login/);
  });

  test('Upload → Confirm → Annotation-Page → alle Korrektur-Features', async ({ page }) => {
    test.skip(!fs.existsSync(REAL_PDF), `Test-PDF fehlt: ${REAL_PDF}`);
    test.setTimeout(300_000); // 5min für ganzen Workflow

    // 1) PDF mit E2E-Marker im Dateinamen kopieren
    const tempPdf = path.join(os.tmpdir(), `e2e-test-${Date.now()}.pdf`);
    fs.copyFileSync(REAL_PDF, tempPdf);

    // 2) OMR-Job hochladen
    await page.goto('/Bands/demo/omr');
    await expect(page.getByTestId('omr-heading')).toBeVisible();
    await page.getByTestId('omr-pdf-input').setInputFiles(tempPdf);
    await page.getByTestId('omr-upload-submit').click();

    // 3) Auf "Erkennung abgeschlossen" warten
    await expect(page.getByTestId('omr-status')).toContainText('abgeschlossen', { timeout: 120_000 });

    // 4) Title mit E2E-Marker setzen — Training-Export filtert das raus
    const baseTitle = await page.getByTestId('omr-confirm-title').inputValue();
    const testTitle = TEST_PIECE_TITLE_PREFIX + (baseTitle || 'BAVARIA');
    await page.getByTestId('omr-confirm-title').fill(testTitle);

    // 5) Confirm → Piece + Parts werden angelegt + Auto-Trigger Detections
    await page.getByTestId('omr-confirm-submit').click();
    await expect(page.getByTestId('piece-detail-title')).toContainText('E2E-TEST', { timeout: 30_000 });

    // 6) Erste Stimme auswählen + Annotation-Page öffnen
    if ((await page.getByTestId('part-select').count()) === 0) {
      throw new Error('Keine Stimme erzeugt');
    }
    await page.getByTestId('part-show').click();

    // Button ist immer sichtbar (nicht nur wenn Detections fertig)
    const annotateLink = page.getByTestId('part-annotate-link');
    await expect(annotateLink).toBeVisible({ timeout: 15_000 });
    await annotateLink.click();

    // 7) Auf der Annotation-Page: Detections müssen geladen werden
    // (entweder schon da oder Auto-Trigger startet beim Page-Load)
    await page.waitForURL(/\/parts\/.+\/annotate$/);
    // Canvas + Toolbar erscheinen sobald Detections da sind
    await expect(page.getByTestId('annotate-canvas')).toBeVisible({ timeout: 120_000 });
    await expect(page.getByTestId('annotate-coverage')).toBeVisible();

    // 8) Tool-Modes umschalten + zurück zum Click-Modus
    await page.getByTestId('annotate-tool-region').click();
    await page.getByTestId('annotate-tool-click').click();

    // 9) Klick auf einen NH — wir versuchen mehrere Stellen bis was selektiert ist
    const canvas = page.getByTestId('annotate-canvas');
    const box = await canvas.boundingBox();
    if (!box) throw new Error('Canvas-BoundingBox nicht messbar');

    let selected = false;
    for (let i = 0; i < 12 && !selected; i++) {
      const fx = 0.15 + (i % 4) * 0.18;
      const fy = 0.20 + Math.floor(i / 4) * 0.20;
      await canvas.click({ position: { x: box.width * fx, y: box.height * fy } });
      await page.waitForTimeout(400);
      selected = await page.getByTestId('annotate-selected-card').isVisible().catch(() => false);
    }
    expect(selected, 'Konnte keine erkannte Note per Klick treffen').toBe(true);

    // 10) Korrektur-Test 1: "Korrekt erkannt" → Confirmed
    await page.getByTestId('annotate-confirmed').click();
    await page.waitForTimeout(500);

    // 11) Coverage-Counter sollte ≥ 1 confirmed zeigen
    const coverageText = await page.getByTestId('annotate-coverage-text').textContent();
    expect(coverageText).toMatch(/\d+ bestätigt/);

    // 12) Korrektur-Test 2: anderen NH selektieren + Pitch ändern
    let nextSelected = false;
    for (let i = 0; i < 8 && !nextSelected; i++) {
      const fx = 0.30 + (i % 3) * 0.22;
      const fy = 0.40 + Math.floor(i / 3) * 0.18;
      await canvas.click({ position: { x: box.width * fx, y: box.height * fy } });
      await page.waitForTimeout(400);
      nextSelected = await page.getByTestId('annotate-selected-card').isVisible().catch(() => false);
    }
    if (nextSelected) {
      await page.getByTestId('annotate-wrong-pitch').click();
      const pitchInput = page.locator('input[type="number"]').first();
      await pitchInput.fill('72');
      await page.getByRole('button', { name: 'OK' }).first().click();
      await page.waitForTimeout(500);
    }

    // 13) Korrektur-Test 3: Wrong Duration + Wrong Kind via separate clicks
    let third = false;
    for (let i = 0; i < 8 && !third; i++) {
      const fx = 0.50 + (i % 3) * 0.15;
      const fy = 0.55 + Math.floor(i / 3) * 0.12;
      await canvas.click({ position: { x: box.width * fx, y: box.height * fy } });
      await page.waitForTimeout(400);
      third = await page.getByTestId('annotate-selected-card').isVisible().catch(() => false);
    }
    if (third) {
      await page.getByTestId('annotate-wrong-duration').click();
      await page.getByRole('button', { name: 'OK' }).first().click();
      await page.waitForTimeout(500);
    }

    // 14) Korrektur-Test 4: NotANote auf einer Detection
    let fourth = false;
    for (let i = 0; i < 8 && !fourth; i++) {
      const fx = 0.60 + (i % 3) * 0.10;
      const fy = 0.30 + Math.floor(i / 3) * 0.15;
      await canvas.click({ position: { x: box.width * fx, y: box.height * fy } });
      await page.waitForTimeout(400);
      fourth = await page.getByTestId('annotate-selected-card').isVisible().catch(() => false);
    }
    if (fourth) {
      await page.getByTestId('annotate-not-a-note').click();
      await page.waitForTimeout(500);
    }

    // 15) Korrektur-Test 5: Click auf leere Stelle → MissedNote
    // Wir finden eine leere Stelle indem wir am Rand klicken
    await page.getByTestId('annotate-tool-click').click();
    await canvas.click({ position: { x: box.width * 0.95, y: box.height * 0.95 } });
    await page.waitForTimeout(400);
    const missedCard = page.getByTestId('annotate-missed-card');
    if (await missedCard.isVisible().catch(() => false)) {
      await page.getByTestId('annotate-save-missed').click();
      await page.waitForTimeout(500);
    }

    // 16) Region-Bestätigung mit Drag — Tool wechseln + Drag auf Canvas
    await page.getByTestId('annotate-tool-region').click();
    await canvas.dragTo(canvas, {
      sourcePosition: { x: box.width * 0.10, y: box.height * 0.10 },
      targetPosition: { x: box.width * 0.40, y: box.height * 0.20 },
    });
    await page.waitForTimeout(800);

    // 17) Liste sollte mehrere Korrekturen haben
    const listItems = page.locator('.list-group-item');
    expect(await listItems.count()).toBeGreaterThanOrEqual(1);

    // 18) Page-Navigation testen (falls > 1 Seite)
    const pageLabel = await page.getByTestId('annotate-page-label').textContent();
    if (pageLabel && /\/\s*[2-9]/.test(pageLabel)) {
      await page.getByTestId('annotate-next').click();
      await page.waitForTimeout(500);
      await expect(canvas).toBeVisible();
      await page.getByTestId('annotate-prev').click();
      await page.waitForTimeout(500);
    }

    // 19) Zoom-Slider — KEINE locale-bedingten Sprünge
    const zoomInput = page.getByTestId('annotate-zoom');
    await zoomInput.fill('150');
    await zoomInput.dispatchEvent('input');
    await page.waitForTimeout(300);
    await expect(page.locator('text=/150%/')).toBeVisible();

    // 20) Layer-Toggles
    await page.locator('label:has-text("Stems") input').uncheck();
    await page.waitForTimeout(200);
    await page.locator('label:has-text("Stems") input').check();

    // 21) Cleanup: PDF wegwerfen (Server-Daten haben E2E-Marker → kein Training-Risiko)
    fs.unlinkSync(tempPdf);

    // (Server-side cleanup wäre nice-to-have via DELETE-API,
    // aber der E2E-Marker im Title schützt schon.)
  });

  test('Annotation-Page crasht nicht bei Page-Load wenn keine Detections', async ({ page }) => {
    // Direkter Aufruf einer Annotation-URL einer Stimme ohne Detections darf
    // nicht "Ups, da ist was schiefgegangen" zeigen, sondern den Auto-Trigger
    // "Erkennung läuft…" anzeigen.

    // Wir brauchen zumindest ein Piece mit Stimme — wir öffnen einfach das
    // erste verfügbare. Wenn keins existiert, skip.
    await page.goto('/Bands/demo/pieces');
    const firstPiece = page.locator('[data-testid="piece-row"]').first();
    if ((await firstPiece.count()) === 0) {
      test.skip(true, 'Keine Pieces vorhanden — kein direkter URL-Test möglich');
    }
    await firstPiece.click();

    if ((await page.getByTestId('part-select').count()) === 0) {
      test.skip(true, 'Keine Stimme vorhanden');
    }
    await page.getByTestId('part-show').click();

    // Button MUSS immer da sein für canEdit
    await expect(page.getByTestId('part-annotate-link')).toBeVisible();
    await page.getByTestId('part-annotate-link').click();

    // Page lädt — entweder mit Canvas oder Pending-Hinweis
    const canvas = page.getByTestId('annotate-canvas');
    const pending = page.getByTestId('annotate-pending');
    await expect(canvas.or(pending)).toBeVisible({ timeout: 30_000 });

    // Kein "Ups"-Error
    const body = await page.textContent('body');
    expect(body).not.toContain('Ups, da ist was schiefgegangen');
  });

});

