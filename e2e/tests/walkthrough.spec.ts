import { test, expect, type Page, type BrowserContext } from '@playwright/test';

/**
 * Walkthrough — klickt sich systematisch durch die gesamte App und prueft
 * Verhalten an jeder Station. Soll Bugs schnell sichtbar machen, indem es
 * alle Hauptflows einmal beruehrt.
 *
 * Voraussetzung: Demo-Daten gesynt (Verein "demo", User dirigent@demo.local /
 * demo). Tour wird ueber localStorage uebersprungen.
 */

const DEMO_PWD = 'demo';

async function loginDemo(page: Page, email = 'dirigent@demo.local'): Promise<void> {
  await page.goto('/Account/Login');
  await page.getByTestId('login-email').fill(email);
  await page.getByTestId('login-password').fill(DEMO_PWD);
  await page.getByTestId('login-submit').click();
  await expect(page.getByTestId('home-greeting')).toBeVisible();
}

async function newDemoContext(browser: any): Promise<BrowserContext> {
  return await browser.newContext({
    ignoreHTTPSErrors: true,
    storageState: { cookies: [], origins: [{ origin: process.env.E2E_WEB_URL!, localStorage: [{ name: 'sheetstorm-tour-done', value: '1' }] }] },
  });
}

test.describe('Walkthrough — alle Hauptflows', () => {

  test('Login + Home', async ({ browser }) => {
    test.setTimeout(60_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);
    // Home zeigt die Begrüßung — die schon verifiziert ist; schauen ob auch der Verein-Link sichtbar ist
    await expect(page.locator('a[href*="/Bands/demo"]').first()).toBeVisible();
    await ctx.close();
  });

  test('Pieces: Liste, Detail, Part-Viewer mit OSMD-Score', async ({ browser }) => {
    test.setTimeout(120_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);

    await page.goto('/Bands/demo/pieces');
    await expect(page.getByTestId('pieces-heading')).toBeVisible();
    const rows = page.getByTestId('piece-row');
    expect(await rows.count()).toBeGreaterThan(0);
    await rows.first().click();

    await expect(page.getByTestId('piece-detail-title')).toBeVisible();
    // Stimme aus Dropdown waehlen + anzeigen
    const partSelect = page.getByTestId('part-select');
    await expect(partSelect).toBeVisible();
    await page.getByTestId('part-show').click();

    // PartViewer muss eine Stage zeigen
    const stage = page.getByTestId('viewer-stage');
    await expect(stage).toBeVisible();

    // Demo-MusicXML wurde geseedet → Score-Modus default
    await expect(page.getByTestId('viewer-mode-score')).toBeVisible();
    const scoreHost = page.locator('[data-testid="score-host"]');
    expect(await scoreHost.count()).toBeGreaterThan(0);

    // Toolbar zeigt alle Tools
    for (const t of ['tool-pen', 'tool-marker', 'tool-text', 'tool-eraser']) {
      await expect(page.getByTestId(t)).toBeVisible();
    }

    await ctx.close();
  });

  test('Events: Anlegen, Orga-Tabs, Tag/Station/Schicht/Bring/Poll', async ({ browser }) => {
    test.setTimeout(180_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);

    // Event anlegen
    await page.goto('/Bands/demo/events');
    await expect(page.getByTestId('events-heading')).toBeVisible();
    const title = 'Walkthrough-Fest ' + Date.now();
    await page.getByTestId('newevent-type').selectOption('Arbeitseinsatz');
    await page.getByTestId('newevent-title').fill(title);
    await page.getByTestId('newevent-submit').click();

    // Orga oeffnen
    const eventRow = page.locator('[data-testid="event-row"]', { hasText: title }).first();
    await eventRow.getByTestId('event-orga').click();
    await expect(page.getByTestId('orga-heading')).toContainText(title);

    // Tab Tage
    await page.getByTestId('tab-days').click();
    await page.getByTestId('day-date').fill('2026-08-01');
    await page.getByTestId('day-theme').fill('Tag der Vereine');
    await page.getByTestId('day-add').click();
    await expect(page.getByTestId('orga-day-row').first()).toContainText('Tag der Vereine');

    // Tab Stationen
    await page.getByTestId('tab-stations').click();
    await page.getByTestId('station-name').fill('Rote Wurst');
    await page.getByTestId('station-icon').fill('🌭');
    await page.getByTestId('station-add').click();
    await expect(page.getByTestId('orga-station-row').first()).toContainText('Rote Wurst');

    // Tab Schichten — manuell + Generator
    await page.getByTestId('tab-shifts').click();
    await page.getByTestId('shift-title').fill('Verkauf 12-14');
    await page.getByTestId('shift-start').fill('2026-08-01 12:00');
    await page.getByTestId('shift-end').fill('2026-08-01 14:00');
    await page.getByTestId('shift-required').fill('2');
    await page.getByTestId('shift-add').click();
    await expect(page.getByTestId('orga-shift-row').first()).toContainText('Verkauf');

    // Generator: 4 Slots a 2h zwischen 14 und 22 Uhr
    await page.getByTestId('gen-title').fill('Schicht {start}-{end}');
    await page.getByTestId('gen-start').fill('2026-08-01 14:00');
    await page.getByTestId('gen-end').fill('2026-08-01 22:00');
    await page.getByTestId('gen-duration').fill('2');
    await page.getByTestId('gen-required').fill('2');
    await page.getByTestId('gen-submit').click();
    // 1 manuelle + 4 generierte = 5 Schichten
    expect(await page.getByTestId('orga-shift-row').count()).toBeGreaterThanOrEqual(5);

    // Eintragen in eine Schicht
    const firstToggle = page.getByTestId('shift-toggle').first();
    await firstToggle.click();
    await expect(page.getByTestId('shift-toggle').first()).toContainText(/Austragen/);

    // Tab Bring-Liste
    await page.getByTestId('tab-contributions').click();
    await page.getByTestId('contrib-title').fill('Salate');
    await page.getByTestId('contrib-wanted').fill('8');
    await page.getByTestId('contrib-add').click();
    await expect(page.getByTestId('orga-contrib-row').first()).toContainText('Salate');

    // Pledge: ich bring 2 Kartoffelsalate
    const qty = page.getByTestId('pledge-quantity').first();
    await qty.fill('2');
    await page.getByTestId('pledge-what').first().fill('Kartoffelsalat fuer 6');
    await page.getByTestId('pledge-submit').first().click();
    await expect(page.getByTestId('contrib-progress').first()).toContainText('2 / 8');

    // Tab Polls — DateFinder
    await page.getByTestId('tab-polls').click();
    await page.getByTestId('poll-kind').selectOption('DateFinder');
    await page.getByTestId('poll-title').fill('Wann fotografieren?');
    await page.getByTestId('poll-options').fill('2026-08-15 14:00\n2026-08-22 10:00\n2026-08-29 14:00');
    await page.getByTestId('poll-create').click();
    const pollRow = page.getByTestId('orga-poll-row').first();
    await expect(pollRow).toContainText('Wann fotografieren');
    await pollRow.getByTestId('poll-open').click();

    await expect(page.getByTestId('poll-heading')).toContainText('Wann fotografieren');
    // Auf Option 1 mit "Ja" voten
    await page.getByTestId('vote-yes').first().click();
    // Counter steigt: erste Option Spalte Yes >= 1
    const firstRow = page.getByTestId('poll-option-row').first();
    await expect(firstRow.locator('.bg-success').first()).toContainText('1');

    await ctx.close();
  });

  test('Dark Mode bleibt nach Navigation erhalten', async ({ browser }) => {
    test.setTimeout(60_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);

    // Toggle ein
    await page.getByTestId('theme-toggle').click();
    let theme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
    expect(theme).toBe('dark');

    // Navigation auf andere Seite
    await page.goto('/Bands/demo/pieces');
    theme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
    expect(theme).toBe('dark');

    // Noch eine Page
    await page.goto('/Bands/demo/events');
    theme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
    expect(theme).toBe('dark');

    // Direkt-Reload
    await page.reload();
    theme = await page.evaluate(() => document.documentElement.getAttribute('data-theme'));
    expect(theme).toBe('dark');

    await ctx.close();
  });

  test('OMR-Stub-Banner ist sichtbar wenn Audiveris nicht laeuft', async ({ browser }) => {
    test.setTimeout(60_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);
    await page.goto('/Bands/demo/omr');
    await expect(page.getByTestId('omr-stub-banner')).toBeVisible();
  });

  test('Alle Top-Level-Pages laden ohne Server-Error', async ({ browser }) => {
    test.setTimeout(120_000);
    const ctx = await newDemoContext(browser);
    const page = await ctx.newPage();
    await loginDemo(page);

    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push('pageerror: ' + e.message));
    page.on('response', (r) => {
      if (r.status() >= 500 && !r.url().includes('/_blazor')) errors.push(`HTTP ${r.status()} ${r.url()}`);
    });

    const pages = [
      '/',
      '/Account/Profile',
      '/Bands',
      '/Bands/demo',
      '/Bands/demo/pieces',
      '/Bands/demo/events',
      '/Bands/demo/setlists',
      '/Bands/demo/omr',
    ];
    for (const p of pages) {
      await page.goto(p);
      // jede Seite sollte einen <h1> oder ähnlichen Inhalt haben
      const hasContent = await page.locator('h1, h2').count();
      expect(hasContent, `Seite ${p} hat keine Headline`).toBeGreaterThan(0);
    }

    expect(errors, `Server/Page-Errors: ${errors.join(', ')}`).toEqual([]);
    await ctx.close();
  });
});
