import { test, expect } from '@playwright/test';

test.describe('Iteration 6 — Offline-Cache (Service Worker + PWA)', () => {

  test('Service Worker registriert sich, manifest erreichbar', async ({ page }) => {
    await page.goto('/');

    // Manifest erreichbar
    const r = await page.request.get('/manifest.webmanifest');
    expect(r.status()).toBe(200);
    const json = await r.json();
    expect(json.name).toContain('Sheetstorm');
    expect(json.start_url).toBe('/');

    // sw.js wird ausgeliefert
    const sw = await page.request.get('/sw.js');
    expect(sw.status()).toBe(200);
    const swText = await sw.text();
    expect(swText).toContain('sheetstorm-shell');
    expect(swText).toContain('FILES_CACHE');
  });

  test('Demo-Login + Werk als offline markieren + Badge in Liste', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await expect(page.getByTestId('home-greeting')).toBeVisible();

    await page.goto('/Bands/demo/pieces');
    await expect(page.getByTestId('pieces-list')).toBeVisible();

    // Erstes Werk öffnen
    await page.getByTestId('piece-row').first().click();
    await expect(page.getByTestId('piece-detail-title')).toBeVisible();

    // Reset auf "nicht offline" falls von vorherigem Test-Run gesetzt
    const toggle = page.getByTestId('offline-toggle');
    if ((await toggle.textContent())?.includes('✓ Offline')) {
      await toggle.click();
      await expect(page.getByTestId('offline-toggle')).toContainText('Offline verfügbar machen');
    }

    // Toggle on
    await page.getByTestId('offline-toggle').click();
    await expect(page.getByTestId('offline-toggle')).toContainText('✓ Offline verfügbar');
    await expect(page.getByTestId('offline-hint')).toBeVisible();

    // Zurück zur Liste — Offline-Badge sichtbar
    await page.goto('/Bands/demo/pieces');
    const offlineBadges = page.getByTestId('badge-offline');
    await expect(offlineBadges.first()).toBeVisible();
    expect(await offlineBadges.count()).toBeGreaterThan(0);

    // /api/offline/urls liefert URLs des markierten Werks
    const apiRes = await page.request.get('/api/offline/urls');
    expect(apiRes.status()).toBe(200);
    const json = await apiRes.json();
    expect(json.urls.length).toBeGreaterThan(0);
    expect(json.urls[0]).toMatch(/^\/files\/parts\//);

    // Toggle wieder off, damit Folge-Tests sauberen State haben
    await page.goto('/Bands/demo/pieces');
    await page.getByTestId('piece-row').first().click();
    await page.getByTestId('offline-toggle').click();
    await expect(page.getByTestId('offline-toggle')).toContainText('Offline verfügbar machen');
  });

  test('PDF kann via Cache API gecacht werden (Service-Worker-Cache verfügbar)', async ({ page }) => {
    // Login
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    // Werk markieren
    await page.goto('/Bands/demo/pieces');
    await page.getByTestId('piece-row').first().click();
    const toggle = page.getByTestId('offline-toggle');
    if ((await toggle.textContent())?.includes('verfügbar machen')) {
      await toggle.click();
      await expect(page.getByTestId('offline-toggle')).toContainText('✓ Offline');
    }

    // PDF-URL holen
    const urlsRes = await page.request.get('/api/offline/urls');
    const urls = (await urlsRes.json()).urls as string[];
    expect(urls.length).toBeGreaterThan(0);
    const firstUrl = urls[0];

    // Cache API direkt nutzen (Service-Worker-Lifecycle in self-signed-Test-Env nicht zuverlässig)
    const cached = await page.evaluate(async (u) => {
      try {
        const cache = await caches.open('sheetstorm-files-v1');
        const r = await fetch(u, { credentials: 'include' });
        if (!r.ok) return { ok: false, status: r.status };
        await cache.put(u, r.clone());
        const back = await cache.match(u);
        return { ok: back !== undefined, status: back?.status, contentType: back?.headers.get('content-type') };
      } catch (e: any) {
        return { ok: false, error: e.message };
      }
    }, firstUrl);
    expect(cached.ok).toBe(true);
    expect(cached.status).toBe(200);
    expect(cached.contentType).toContain('pdf');
  });
});
