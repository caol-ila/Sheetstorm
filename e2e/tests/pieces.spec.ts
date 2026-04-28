import { test, expect } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import os from 'os';
import { registerLoginFresh, uniqueSlug } from './helpers';

/**
 * Erzeugt eine kleine, valide PDF-Datei für Upload-Tests.
 */
function createTinyPdf(): string {
  const pdfBytes = Buffer.from(
    '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 200 200]/Resources<<>>/Contents 4 0 R>>endobj\n4 0 obj<</Length 44>>stream\nBT /F1 12 Tf 50 100 Td (Test Stimme) Tj ET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f\n0000000010 00000 n\n0000000053 00000 n\n0000000100 00000 n\n0000000175 00000 n\ntrailer<</Size 5/Root 1 0 R>>\nstartxref\n245\n%%EOF',
    'binary',
  );
  const tmp = path.join(os.tmpdir(), `sheetstorm-test-${Date.now()}.pdf`);
  fs.writeFileSync(tmp, pdfBytes);
  return tmp;
}

test.describe('Iteration 2 — Notenmanagement', () => {

  test('Admin lädt PDF-Stimme hoch, sieht Werk in Liste, öffnet Detail', async ({ page }) => {
    await registerLoginFresh(page, 'maestro');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Notenverein');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    // Notenseite öffnen
    await page.goto(`/Bands/${slug}/pieces`);
    await expect(page.getByTestId('pieces-heading')).toBeVisible();
    await expect(page.getByTestId('pieces-empty')).toBeVisible();

    // Werk anlegen
    await page.getByTestId('newpiece-title').fill('Marsch der Bayrischen Volkspartei');
    await page.getByTestId('newpiece-composer').fill('Anonym');
    await page.getByTestId('newpiece-genre').fill('Marsch');
    await page.getByTestId('newpiece-difficulty').fill('3');
    await page.getByTestId('newpiece-submit').click();

    // Detail-Seite
    await expect(page.getByTestId('piece-detail-title')).toHaveText('Marsch der Bayrischen Volkspartei');
    await expect(page.getByTestId('piece-composer')).toHaveText('Anonym');
    await expect(page.getByTestId('parts-empty')).toBeVisible();

    // Stimme hochladen — Klarinette in B
    const pdfPath = createTinyPdf();
    await page.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('addpart-displayname').fill('Klarinette 1 in B');
    await page.getByTestId('addpart-file').setInputFiles(pdfPath);
    await page.getByTestId('addpart-submit').click();

    // Stimme erscheint
    await expect(page.getByTestId('part-select')).toBeVisible();
    await expect(page.getByTestId('part-show')).toBeVisible();
    await page.getByTestId('part-show').click();
    await expect(page.getByTestId('selected-part-name')).toHaveText('Klarinette 1 in B');
    // Neuer PartViewer: zeigt entweder PDF-Embed oder Toolbar mit Files-Info
    await expect(page.getByTestId('viewer-host').or(page.getByTestId('viewer-no-files'))).toBeVisible();

    // Liste enthält Werk
    await page.goto(`/Bands/${slug}/pieces`);
    await expect(page.getByTestId('piece-row')).toContainText('Marsch der Bayrischen Volkspartei');
    await expect(page.getByTestId('pieces-count')).toContainText('1');

    fs.unlinkSync(pdfPath);
  });

  test('Suche und Filter blenden Werke korrekt aus', async ({ page }) => {
    await registerLoginFresh(page, 'libra');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Bibliothek-Verein');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    await page.goto(`/Bands/${slug}/pieces`);

    for (const work of [
      { title: 'Radetzky-Marsch', composer: 'Strauss', genre: 'Marsch' },
      { title: 'Florentiner Marsch', composer: 'Fucik', genre: 'Marsch' },
      { title: 'Festliche Ouvertüre', composer: 'Schostakowitsch', genre: 'Konzert' },
    ]) {
      await page.getByTestId('newpiece-title').fill(work.title);
      await page.getByTestId('newpiece-composer').fill(work.composer);
      await page.getByTestId('newpiece-genre').fill(work.genre);
      await page.getByTestId('newpiece-submit').click();
      await page.goto(`/Bands/${slug}/pieces`);
    }

    await expect(page.getByTestId('pieces-count')).toContainText('3');

    // Volltext-Suche nach Komponist
    await page.getByTestId('filter-query').fill('Strauss');
    await page.getByTestId('filter-apply').click();
    await expect(page.getByTestId('pieces-count')).toContainText('1');
    await expect(page.getByTestId('piece-row')).toContainText('Radetzky');

    // Genre-Filter
    await page.getByTestId('filter-query').fill('');
    await page.getByTestId('filter-genre').selectOption('Marsch');
    await page.getByTestId('filter-apply').click();
    await expect(page.getByTestId('pieces-count')).toContainText('2');
  });

  test('Bevorzugte Stimme erscheint als erste Option im Dropdown', async ({ page }) => {
    await registerLoginFresh(page, 'pref');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Stimm-Verein');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    // Bevorzugte Stimme = Klarinette in B
    await page.goto('/Account/Profile');
    await page.getByTestId('primary-instrument-select').first().selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('primary-instrument-save').first().click();
    await expect(page.getByTestId('primary-instrument-current').first()).toContainText('Klarinette in B');

    // Werk anlegen mit zwei Stimmen: Klarinette in B (bevorzugt) + Trompete in B
    await page.goto(`/Bands/${slug}/pieces`);
    await page.getByTestId('newpiece-title').fill('Test-Stück');
    await page.getByTestId('newpiece-submit').click();

    const pdfPath = createTinyPdf();
    // Erst Trompete (nicht bevorzugt)
    await page.getByTestId('addpart-instrument').selectOption({ label: 'Trompete in B (in B)' });
    await page.getByTestId('addpart-displayname').fill('Trompete 1');
    await page.getByTestId('addpart-file').setInputFiles(pdfPath);
    await page.getByTestId('addpart-submit').click();

    // Dann Klarinette (bevorzugt)
    await page.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('addpart-displayname').fill('Klarinette 1 in B');
    await page.getByTestId('addpart-file').setInputFiles(pdfPath);
    await page.getByTestId('addpart-submit').click();

    // Erste Option im Stimm-Dropdown muss Klarinette sein (mit ⭐)
    const select = page.getByTestId('part-select');
    const firstOption = await select.locator('option').first().textContent();
    expect(firstOption).toContain('Klarinette');
    expect(firstOption).toContain('⭐');

    fs.unlinkSync(pdfPath);
  });
});
