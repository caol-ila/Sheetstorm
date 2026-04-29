import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { registerLoginFresh, uniqueSlug } from './helpers';

function createTinyPdf(): string {
  const pdfBytes = Buffer.from(
    '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]/Resources<<>>/Contents 4 0 R>>endobj\n4 0 obj<</Length 44>>stream\nBT /F1 12 Tf 50 100 Td (Test Stimme) Tj ET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f\n0000000010 00000 n\n0000000053 00000 n\n0000000100 00000 n\n0000000175 00000 n\ntrailer<</Size 5/Root 1 0 R>>\nstartxref\n245\n%%EOF',
    'binary',
  );
  const tmp = path.join(os.tmpdir(), `sheetstorm-events-${Date.now()}.pdf`);
  fs.writeFileSync(tmp, pdfBytes);
  return tmp;
}

test.describe('Iteration 3 — Termine & Setlists', () => {

  test('Dirigent erstellt Probe, Mitglied bestätigt Anwesenheit', async ({ page }) => {
    await registerLoginFresh(page, 'dirigent');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Probe-Verein');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    await page.goto(`/Bands/${slug}/events`);
    await expect(page.getByTestId('events-empty')).toBeVisible();

    // Probe anlegen
    await page.getByTestId('newevent-type').selectOption('Probe');
    await page.getByTestId('newevent-title').fill('Wöchentliche Probe');
    await page.getByTestId('newevent-submit').click();

    await expect(page.getByTestId('event-row')).toBeVisible();
    await expect(page.getByTestId('event-title')).toHaveText('Wöchentliche Probe');

    // Zusagen
    await page.getByTestId('respond-yes').click();
    await expect(page.getByTestId('my-status')).toContainText('Yes');
    await expect(page.getByTestId('att-yes-count')).toContainText('1');

    // Auf Vielleicht ändern
    await page.getByTestId('respond-maybe').click();
    await expect(page.getByTestId('my-status')).toContainText('Maybe');
    await expect(page.getByTestId('att-yes-count')).toContainText('0');
    await expect(page.getByTestId('att-maybe-count')).toContainText('1');
  });

  test('Setlist mit Werken erstellen + Konzert-Modus blättert durch Stücke', async ({ page }) => {
    await registerLoginFresh(page, 'concert');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Konzert-Verein');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    // 2 Werke + 1 Stimme pro Werk
    const pdfPath = createTinyPdf();
    for (const title of ['Marsch Nr. 1', 'Marsch Nr. 2']) {
      await page.goto(`/Bands/${slug}/pieces`);
      await page.getByTestId('newpiece-title').fill(title);
      await page.getByTestId('newpiece-submit').click();
      await page.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
      await page.getByTestId('addpart-displayname').fill('Klarinette 1 in B');
      await page.getByTestId('addpart-file').setInputFiles(pdfPath);
      await page.getByTestId('addpart-submit').click();
      await expect(page.getByTestId('part-show')).toBeVisible();
    }

    // Setlist erstellen
    await page.goto(`/Bands/${slug}/sets`);
    await page.getByTestId('newset-name').fill('Frühschoppen 2026');
    await page.getByTestId('newset-submit').click();

    await expect(page.getByTestId('set-detail-title')).toContainText('Frühschoppen');

    // 2 Werke hinzufügen
    await page.getByTestId('addpiece-select').selectOption({ label: 'Marsch Nr. 1' });
    await page.getByTestId('addpiece-submit').click();
    await page.getByTestId('addpiece-select').selectOption({ label: 'Marsch Nr. 2' });
    await page.getByTestId('addpiece-submit').click();
    await expect(page.getByTestId('set-item')).toHaveCount(2);

    // Konzert anlegen mit dieser Setlist
    await page.goto(`/Bands/${slug}/events`);
    await page.getByTestId('newevent-type').selectOption('Konzert');
    await page.getByTestId('newevent-title').fill('Sommerkonzert');
    await page.getByTestId('newevent-setlist').selectOption({ label: 'Frühschoppen 2026' });
    await page.getByTestId('newevent-submit').click();

    // Konzert-Modus öffnen
    await page.getByTestId('event-perform').click();
    await expect(page.getByTestId('perform-piece-title')).toHaveText('Marsch Nr. 1');
    await expect(page.getByTestId('perform-position')).toContainText('1 von 2');

    // Nächstes Stück
    await page.getByTestId('perform-next').click();
    await expect(page.getByTestId('perform-piece-title')).toHaveText('Marsch Nr. 2');
    await expect(page.getByTestId('perform-position')).toContainText('2 von 2');

    // Voriges
    await page.getByTestId('perform-prev').click();
    await expect(page.getByTestId('perform-piece-title')).toHaveText('Marsch Nr. 1');

    fs.unlinkSync(pdfPath);
  });
});
