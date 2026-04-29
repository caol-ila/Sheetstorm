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
  const tmp = path.join(os.tmpdir(), `sheetstorm-conduct-${Date.now()}.pdf`);
  fs.writeFileSync(tmp, pdfBytes);
  return tmp;
}

test.describe('Iteration 4 — Conductor Sync (SignalR)', () => {

  test('Dirigent öffnet Stück, Mitglied (anderer Browser-Kontext) sieht es live', async ({ browser }) => {
    // Dirigent + Mitglied im selben Verein.
    const cdCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const cd = await cdCtx.newPage();
    await registerLoginFresh(cd, 'dirigent');

    const slug = uniqueSlug('mv');
    await cd.goto('/Bands');
    await cd.getByTestId('newband-name').fill('Sync-Verein');
    await cd.getByTestId('newband-slug').fill(slug);
    await cd.getByTestId('newband-submit').click();

    // Mitglied registrieren und einladen
    const mCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const m = await mCtx.newPage();
    const member = await registerLoginFresh(m, 'follower');

    await cd.goto(`/Bands/${slug}`);
    await cd.getByTestId('invite-email').fill(member.email);
    await cd.getByTestId('invite-submit').click();
    const inviteUrl = (await cd.getByTestId('invite-url').textContent())!.trim();
    await m.goto(inviteUrl);
    await expect(m.getByTestId('invite-success')).toBeVisible();

    // Mitglied: Klarinette in B als bevorzugt
    await m.goto('/Account/Profile');
    await m.getByTestId('primary-instrument-select').first().selectOption({ label: 'Klarinette in B (in B)' });
    await m.getByTestId('primary-instrument-save').first().click();

    // Dirigent legt 2 Werke an + Stimmen
    const pdfPath = createTinyPdf();
    for (const title of ['Sync-Stück Alpha', 'Sync-Stück Beta']) {
      await cd.goto(`/Bands/${slug}/pieces`);
      await cd.getByTestId('newpiece-title').fill(title);
      await cd.getByTestId('newpiece-submit').click();
      await cd.getByTestId('addpart-instrument').selectOption({ label: 'Klarinette in B (in B)' });
      await cd.getByTestId('addpart-displayname').fill('Klarinette 1 in B');
      await cd.getByTestId('addpart-file').setInputFiles(pdfPath);
      await cd.getByTestId('addpart-submit').click();
      await expect(cd.getByTestId('part-show')).toBeVisible();
    }

    // Setlist + Termin
    await cd.goto(`/Bands/${slug}/sets`);
    await cd.getByTestId('newset-name').fill('Sync-Setlist');
    await cd.getByTestId('newset-submit').click();
    await cd.getByTestId('addpiece-select').selectOption({ label: 'Sync-Stück Alpha' });
    await cd.getByTestId('addpiece-submit').click();
    await cd.getByTestId('addpiece-select').selectOption({ label: 'Sync-Stück Beta' });
    await cd.getByTestId('addpiece-submit').click();

    await cd.goto(`/Bands/${slug}/events`);
    await cd.getByTestId('newevent-type').selectOption('Konzert');
    await cd.getByTestId('newevent-title').fill('Sync-Konzert');
    await cd.getByTestId('newevent-setlist').selectOption({ label: 'Sync-Setlist' });
    await cd.getByTestId('newevent-submit').click();

    // Beide öffnen Sync-Page (URL ist gleich, Verhalten unterscheidet sich nach Rolle)
    const eventConductLink = cd.getByTestId('event-conduct');
    const conductHref = await eventConductLink.getAttribute('href');
    expect(conductHref).toBeTruthy();

    await cd.goto(conductHref!);
    await m.goto(conductHref!);

    // Warte bis Blazor InteractiveServer Circuit etabliert ist
    await cd.waitForTimeout(2000);
    await m.waitForTimeout(2000);

    // Dirigent sieht Controls; Mitglied sieht idle
    await expect(cd.getByTestId('conductor-controls')).toBeVisible();
    await expect(m.getByTestId('conductor-controls')).toHaveCount(0);
    await expect(m.getByTestId('follower-idle')).toBeVisible();

    // Dirigent startet Session — kann je nach Crypto-Init dauern
    const startBtn = cd.getByTestId('start-session');
    if (await startBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await startBtn.click();
    }
    await expect(cd.getByTestId('session-active')).toBeVisible({ timeout: 20000 });

    // Mitglied muss neu laden, um aktive Session zu sehen
    await m.reload();
    await m.waitForTimeout(2000);
    await expect(m.getByTestId('follower-waiting')).toBeVisible();

    // Dirigent öffnet Stück Alpha
    await cd.getByTestId('conductor-piece').first().getByTestId('conductor-open-piece').click();

    // Mitglied bekommt Live-Update via SignalR
    await expect(m.getByTestId('now-playing-title')).toHaveText('Sync-Stück Alpha', { timeout: 15000 });
    await expect(m.getByTestId('follower-part-name')).toContainText('Klarinette');

    // Dirigent öffnet Beta
    await cd.getByTestId('conductor-piece').nth(1).getByTestId('conductor-open-piece').click();
    await expect(m.getByTestId('now-playing-title')).toHaveText('Sync-Stück Beta', { timeout: 15000 });

    fs.unlinkSync(pdfPath);
    await cdCtx.close();
    await mCtx.close();
  });
});
