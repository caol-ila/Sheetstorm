import { test, expect } from '@playwright/test';

/**
 * BLE-Broadcast-E2E (Pure-Advertising-Modus, V2).
 *
 * Hardware kann CI nicht bereitstellen — daher fährt die /ble-test-Seite
 * einen Loopback-Conductor im selben Tab. Der Follower auf derselben Seite
 * empfängt die Pakete via window-Event und durchläuft dieselbe Ed25519-
 * Verify-Pipeline wie ein echter BLE-Empfänger.
 *
 * Das ist ein _funktionaler_ Sanity-Check für Sign/Verify, Tempo-Decode,
 * BPM/Beat/Drift-Display und Click-Toggle.
 */

test.describe('BLE-Broadcast (Loopback)', () => {

  test.beforeEach(async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();
    await page.goto('/ble-test');
    await expect(page.getByRole('heading', { name: /BLE-Tester/ })).toBeVisible();
  });

  test('Loopback liefert Tempo-Pakete an Follower mit korrekter BPM', async ({ page }) => {
    // Loopback-Conductor mit BPM 120 starten
    await page.getByTestId('loopback-bpm').fill('120');
    await page.getByTestId('loopback-bpm').blur();
    await page.getByTestId('loopback-start').click();
    await expect(page.getByTestId('loopback-pubkey')).toBeVisible({ timeout: 5000 });

    // Follower-Empfang starten (übernimmt Loopback-Pubkey automatisch)
    await page.getByTestId('follower-start').click();

    // Mindestens 1 Tempo-Paket sollte innerhalb von 3 Sekunden ankommen
    await expect.poll(
      async () => parseInt((await page.getByTestId('follower-count').textContent()) || '0', 10),
      { timeout: 6000, intervals: [200, 400, 800, 1500] }
    ).toBeGreaterThan(0);

    // BPM muss 120 sein
    await expect(page.getByTestId('follower-bpm')).toHaveText('120');

    // Beat-Counter sollte hochzählen während wir warten
    const beatBefore = parseInt((await page.getByTestId('follower-beat').textContent()) || '0', 10);
    await page.waitForTimeout(2200);
    const beatAfter = parseInt((await page.getByTestId('follower-beat').textContent()) || '0', 10);
    expect(beatAfter, `Beats sollten hochzählen (vorher=${beatBefore}, nachher=${beatAfter})`).toBeGreaterThan(beatBefore);

    // Stoppen
    await page.getByTestId('follower-stop').click();
    await page.getByTestId('loopback-stop').click();
  });

  test('Falscher Public-Key verwirft das Paket (Sig-Check)', async ({ page }) => {
    // Loopback starten
    await page.getByTestId('loopback-bpm').fill('100');
    await page.getByTestId('loopback-start').click();
    await expect(page.getByTestId('loopback-pubkey')).toBeVisible({ timeout: 5000 });

    // Follower mit absichtlich falschem (anderem) Pubkey starten
    const wrongKp = await page.evaluate(async () => {
      const ny: any = (window as any).SheetstormNative;
      return await ny.generateConductorKey();
    });
    await page.getByTestId('follower-pubkey').fill(wrongKp.publicKey);
    await page.getByTestId('follower-start').click();

    // 3 Sekunden warten — der Counter darf nicht hochzählen
    await page.waitForTimeout(3000);
    const count = parseInt((await page.getByTestId('follower-count').textContent()) || '0', 10);
    expect(count, 'Pakete mit falscher Sig dürfen nicht akzeptiert werden').toBe(0);

    await page.getByTestId('follower-stop').click();
    await page.getByTestId('loopback-stop').click();
  });

  test('Piece-Loopback wird angezeigt', async ({ page }) => {
    await page.getByTestId('loopback-start').click();
    await expect(page.getByTestId('loopback-pubkey')).toBeVisible({ timeout: 5000 });
    await page.getByTestId('follower-start').click();

    // Piece-Block kommt mit dem ersten Loopback-Start als einmaliges Paket
    await expect(page.getByTestId('follower-piece-title')).toHaveText('Loopback-Demo', { timeout: 6000 });

    await page.getByTestId('follower-stop').click();
    await page.getByTestId('loopback-stop').click();
  });
});
