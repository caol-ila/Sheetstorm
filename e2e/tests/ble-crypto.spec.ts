import { test, expect } from '@playwright/test';

test.describe('Iteration 4b — BLE/Crypto Layer', () => {

  test('Ed25519 verfügbar im Browser', async ({ page }) => {
    await page.goto('/');
    const available = await page.evaluate(async () => (window as any).__sheetstormSync?.ed25519Available());
    expect(available).toBe(true);
  });

  test('Ed25519 Sign + Verify Roundtrip funktioniert', async ({ page }) => {
    await page.goto('/');
    const result = await page.evaluate(async () => {
      const sync = (window as any).__sheetstormSync;
      const internal = sync._internal;
      const kp = await internal.generateKeyPair();
      const eventIdShort = internal.shortIdFromGuid('11111111-2222-3333-4444-555555555555');
      const pieceIdShort = internal.shortIdFromGuid('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      const payload = internal.buildPayload(eventIdShort, pieceIdShort, 42);
      const sig = await internal.sign(kp.privateKey, payload);
      const ok = await internal.verify(kp.publicKey, sig, payload);
      const okWrongData = await internal.verify(kp.publicKey, sig, new Uint8Array([0, 1, 2, 3]));
      return { okValid: ok, okWrongData, payloadLength: payload.length, sigLength: sig.length };
    });
    expect(result.okValid).toBe(true);
    expect(result.okWrongData).toBe(false);
    expect(result.payloadLength).toBe(27);
    expect(result.sigLength).toBe(64);
  });

  test('Public Key wird beim Session-Start erzeugt + via API verfügbar', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    // Erstelle eine Setlist + Konzert ad-hoc
    await page.goto('/Bands/demo/sets');
    await page.getByTestId('newset-name').fill('BLE-Setlist ' + Date.now());
    await page.getByTestId('newset-submit').click();

    // Falls keine Werke vorhanden — Demo hat 3, also einfach erstes hinzufügen
    if (await page.getByTestId('addpiece-submit').isVisible({ timeout: 2000 }).catch(() => false)) {
      await page.getByTestId('addpiece-submit').click();
    }

    // Konzert anlegen
    await page.goto('/Bands/demo/events');
    await page.getByTestId('newevent-type').selectOption('Konzert');
    const title = 'BLE-Test ' + Date.now();
    await page.getByTestId('newevent-title').fill(title);
    // Erste BLE-Setlist auswählen (die wir gerade angelegt haben)
    const setlistOptions = await page.getByTestId('newevent-setlist').locator('option').allTextContents();
    const bleOption = setlistOptions.find(o => o.startsWith('BLE-Setlist'));
    if (bleOption) await page.getByTestId('newevent-setlist').selectOption({ label: bleOption });
    await page.getByTestId('newevent-submit').click();

    // Sync-Page
    const conductLink = page.getByTestId('event-conduct').first();
    await conductLink.click();

    await page.waitForTimeout(1500);
    let freshSession = false;
    const startBtn = page.getByTestId('start-session');
    if (await startBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
      await startBtn.click();
      freshSession = true;
    }
    await expect(page.getByTestId('session-active')).toBeVisible({ timeout: 20000 });

    // Crypto-Status nur prüfen wenn Session frisch (sonst Page-Refresh-Pfad ohne JS-Aufruf)
    if (freshSession) {
      await expect(page.getByTestId('crypto-status')).toContainText('Ed25519', { timeout: 10000 });
    }
    await expect(page.getByTestId('crypto-pubkey')).toBeVisible();

    // Public Key auch via Crypto-API verifizierbar (nur wenn frisch erstellt im selben Browser-Kontext)
    if (freshSession) {
      const url = page.url();
      const eventGuid = url.match(/\/conduct\/([0-9a-f-]+)/)![1];
      const verifyResult = await page.evaluate(async (eventId) => {
        const sync = (window as any).__sheetstormSync;
        const dummyPieceId = '00000000-0000-0000-0000-000000000001';
        const signed = await sync.signOpenPiece(eventId, dummyPieceId, 1);
        return { hasPayload: !!signed.payload, hasSignature: !!signed.signature };
      }, eventGuid);
      expect(verifyResult.hasPayload).toBe(true);
      expect(verifyResult.hasSignature).toBe(true);
    }
  });
});
