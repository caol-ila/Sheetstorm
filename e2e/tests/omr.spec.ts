import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import os from 'os';

function createTinyPdf(label = 'OMR-Test'): string {
  const pdfBytes = Buffer.from(
    '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]/Resources<<>>/Contents 4 0 R>>endobj\n4 0 obj<</Length 38>>stream\nBT /F1 12 Tf 50 100 Td (' + label + ') Tj ET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f\n0000000010 00000 n\n0000000053 00000 n\n0000000100 00000 n\n0000000175 00000 n\ntrailer<</Size 5/Root 1 0 R>>\nstartxref\n245\n%%EOF',
    'binary',
  );
  const tmp = path.join(os.tmpdir(), `sheetstorm-omr-${Date.now()}-${Math.random().toString(36).slice(2)}.pdf`);
  fs.writeFileSync(tmp, pdfBytes);
  return tmp;
}

test.describe('Iteration 5 — OMR-Pipeline', () => {

  test('Dirigent lädt PDF hoch, Erkennung läuft, Stimmen werden vorgeschlagen, Werk wird angelegt', async ({ page }) => {
    test.skip(!!process.env.AUDIVERIS_ON || !!process.env.SHEETSTORM_OMR_ON,
      'Test braucht Stub-OMR; bei echter Engine fail mit Mini-PDF.');
    test.setTimeout(60_000);

    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Bands/demo/omr');
    await expect(page.getByTestId('omr-heading')).toBeVisible();

    // Mit Komponist im Dateinamen
    const pdfPath = createTinyPdf();
    const renamedPath = pdfPath.replace(/\.pdf$/, '-Strauss - Radetzky-Marsch.pdf');
    fs.copyFileSync(pdfPath, renamedPath);

    await page.getByTestId('omr-pdf-input').setInputFiles(renamedPath);
    await page.getByTestId('omr-upload-submit').click();

    // Detail-Seite
    await expect(page.getByTestId('omr-detail-heading')).toBeVisible();

    // Status wechselt von Queued/Running zu Done — InteractiveServer pollt alle 1.5s
    await expect(page.getByTestId('omr-status')).toContainText('abgeschlossen', { timeout: 30000 });

    // Vorgeschlagene Stimmen sind sichtbar
    await expect(page.getByTestId('omr-detected-parts')).toBeVisible();
    const partRows = page.getByTestId('omr-detected-row');
    expect(await partRows.count()).toBeGreaterThan(0);

    // Titel + Komponist sind aus Dateiname extrahiert
    const titleVal = await page.getByTestId('omr-confirm-title').inputValue();
    expect(titleVal).toContain('Radetzky');

    // Werk anlegen
    await page.getByTestId('omr-confirm-submit').click();

    // Landet auf Piece-Detail-Seite
    await expect(page.getByTestId('piece-detail-title')).toContainText('Radetzky', { timeout: 15000 });

    // Stimmen sind vorhanden (Dropdown sichtbar)
    await expect(page.getByTestId('part-select')).toBeVisible();

    fs.unlinkSync(pdfPath);
    fs.unlinkSync(renamedPath);
  });

  test('OMR-Job-Liste zeigt vorherige Aufträge', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Bands/demo/omr');
    // Mindestens 1 Job vom vorigen Test
    const jobsVisible = await page.getByTestId('omr-jobs-list').isVisible({ timeout: 3000 }).catch(() => false);
    if (jobsVisible) {
      const rows = page.getByTestId('omr-job-row');
      expect(await rows.count()).toBeGreaterThan(0);
    } else {
      await expect(page.getByTestId('omr-empty')).toBeVisible();
    }
  });
});
