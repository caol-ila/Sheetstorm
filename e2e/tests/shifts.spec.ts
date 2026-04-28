import { test, expect } from '@playwright/test';

test.describe('Iteration 13 — Arbeitseinsatz-Schichten', () => {

  test('Dirigent legt Schicht an, Mitglied trägt sich ein', async ({ browser }) => {
    test.setTimeout(60_000);
    const cdCtx = await browser.newContext({
      ignoreHTTPSErrors: true,
      storageState: { cookies: [], origins: [{ origin: process.env.E2E_WEB_URL!, localStorage: [{ name: 'sheetstorm-tour-done', value: '1' }] }] },
    });
    const cd = await cdCtx.newPage();
    await cd.goto('/Account/Login');
    await cd.getByTestId('login-email').fill('dirigent@demo.local');
    await cd.getByTestId('login-password').fill('demo');
    await cd.getByTestId('login-submit').click();

    // Arbeitseinsatz-Termin anlegen
    await cd.goto('/Bands/demo/events');
    await cd.getByTestId('newevent-type').selectOption('Arbeitseinsatz');
    const title = 'Festle ' + Date.now();
    await cd.getByTestId('newevent-title').fill(title);
    await cd.getByTestId('newevent-submit').click();

    // Schichten-Page öffnen
    const eventRow = cd.locator('[data-testid="event-row"]', { hasText: title }).first();
    await eventRow.getByTestId('event-shifts').click();

    await expect(cd.getByTestId('shifts-heading')).toContainText(title);
    await expect(cd.getByTestId('shifts-empty')).toBeVisible();

    // Schicht "Theke" anlegen (RequiredCount default 2)
    await cd.getByTestId('shift-create-title').fill('Theke');
    await cd.getByTestId('shift-create-submit').click();

    await expect(cd.getByTestId('shift-row')).toHaveCount(1);
    await expect(cd.getByTestId('shift-fill')).toContainText('0 / 2');

    // Dirigent trägt sich ein
    await cd.getByTestId('shift-toggle').click();
    await expect(cd.getByTestId('shift-fill')).toContainText('1 / 2');
    await expect(cd.getByTestId('shift-toggle')).toContainText('Austragen');

    await cdCtx.close();
  });
});
