import { test, expect } from '@playwright/test';
import { registerLoginFresh, uniqueSlug, registerUser, confirmEmailViaMailhog, login, uniqueEmail } from './helpers';

test.describe('Iteration 8 — Funktionale Lücken', () => {

  test('Profil bearbeiten: DisplayName ändern + persistieren', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Account/Profile');
    await page.getByTestId('profile-displayname-input').fill('Maria Neue');
    await page.getByTestId('profile-save').click();
    await expect(page.getByTestId('profile-status')).toContainText('gespeichert');
    // Reload und prüfen
    await page.reload();
    const val = await page.getByTestId('profile-displayname-input').inputValue();
    expect(val).toBe('Maria Neue');

    // Wieder zurücksetzen
    await page.getByTestId('profile-displayname-input').fill('Maria Klarinette');
    await page.getByTestId('profile-save').click();
  });

  test('Werk bearbeiten: Edit-Page ändert Titel + Genre', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Bands/demo/pieces');
    await page.getByTestId('piece-row').first().click();
    await expect(page.getByTestId('piece-edit-link')).toBeVisible();
    await page.getByTestId('piece-edit-link').click();

    await page.getByTestId('piece-edit-genre').fill('Konzertmarsch');
    await page.getByTestId('piece-edit-save').click();

    // Detail-Seite zeigt Werk weiterhin
    await expect(page.getByTestId('piece-detail-title')).toBeVisible();

    // Liste hat Genre als Badge
    await page.goto('/Bands/demo/pieces');
    const rowText = await page.getByTestId('piece-row').first().textContent();
    expect(rowText).toContain('Konzertmarsch');
  });

  test('Verein-Profil: Beschreibung bearbeiten', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    await page.goto('/Bands/demo');
    await expect(page.getByTestId('band-edit-name')).toBeVisible();
    await page.getByTestId('band-edit-city').fill('München');
    await page.getByTestId('band-edit-save').click();
    // Reload
    await page.reload();
    const cityVal = await page.getByTestId('band-edit-city').inputValue();
    expect(cityVal).toBe('München');
  });

  test('iCal-Export liefert text/calendar', async ({ page }) => {
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('maria@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    const r = await page.request.get('/api/bands/demo/calendar.ics');
    expect(r.status()).toBe(200);
    const ct = r.headers()['content-type'];
    expect(ct).toContain('text/calendar');
    const body = await r.text();
    expect(body).toContain('BEGIN:VCALENDAR');
    expect(body).toContain('END:VCALENDAR');
  });

  test('Setlist Up/Down-Buttons sortieren um', async ({ page }) => {
    test.setTimeout(60_000);
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill('dirigent@demo.local');
    await page.getByTestId('login-password').fill('demo');
    await page.getByTestId('login-submit').click();

    const slug = uniqueSlug('sort');
    const bandName = 'Sort-Verein-' + Date.now();
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill(bandName);
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();
    // Warte auf Detail-Seite
    await expect(page.getByTestId('band-title')).toHaveText(bandName);

    // 2 Werke anlegen
    for (const t of ['Stück A', 'Stück B']) {
      await page.goto(`/Bands/${slug}/pieces`);
      await expect(page.getByTestId('newpiece-title')).toBeVisible();
      await page.getByTestId('newpiece-title').fill(t);
      await page.getByTestId('newpiece-submit').click();
      // Detail-Seite
      await expect(page.getByTestId('piece-detail-title')).toBeVisible();
    }

    await page.goto(`/Bands/${slug}/sets`);
    await page.getByTestId('newset-name').fill('Sort-Test');
    await page.getByTestId('newset-submit').click();
    // Detail-Seite mit add-piece-form
    await expect(page.getByTestId('addpiece-select')).toBeVisible();
    await page.getByTestId('addpiece-select').selectOption({ label: 'Stück A' });
    await page.getByTestId('addpiece-submit').click();
    await page.getByTestId('addpiece-select').selectOption({ label: 'Stück B' });
    await page.getByTestId('addpiece-submit').click();

    // Reihenfolge: A, B
    let items = await page.getByTestId('set-item').allTextContents();
    expect(items[0]).toContain('Stück A');
    expect(items[1]).toContain('Stück B');

    // B nach oben
    await page.getByTestId('set-item').nth(1).getByTestId('set-item-up').click();

    items = await page.getByTestId('set-item').allTextContents();
    expect(items[0]).toContain('Stück B');
    expect(items[1]).toContain('Stück A');
  });

  test('Passwort vergessen + Reset-Flow via MailHog', async ({ page }) => {
    test.setTimeout(60_000);
    // Zuerst neuen User registrieren + bestätigen
    const email = uniqueEmail('pwreset');
    await registerUser(page, email, 'PW Reset User');
    await confirmEmailViaMailhog(page, email);

    // Passwort vergessen
    await page.goto('/Account/ForgotPassword');
    await page.getByTestId('forgot-email').fill(email);
    await page.getByTestId('forgot-submit').click();
    await expect(page.getByTestId('forgot-sent')).toBeVisible();

    // MailHog auf Reset-Mail durchsuchen — die zweite/letzte Mail an diese Adresse
    let resetUrl: string | null = null;
    for (let i = 0; i < 30; i++) {
      const res = await fetch(`${process.env.MAILHOG_API ?? 'http://localhost:8025'}/api/v2/messages?limit=200`);
      if (res.ok) {
        const json: any = await res.json();
        // Mails sind neueste zuerst → erste an unsere Adresse mit "ResetPassword" im Body ist die richtige
        const hits = (json.items as any[]).filter(m => {
          const to = m.To?.[0];
          if (!to) return false;
          return `${to.Mailbox}@${to.Domain}`.toLowerCase() === email.toLowerCase();
        });
        for (const m of hits) {
          const decoded = (m.Content?.Body as string ?? '').replace(/=\r?\n/g, '').replace(/=([0-9A-Fa-f]{2})/g, (_: any, h: string) => String.fromCharCode(parseInt(h, 16)));
          const match = decoded.match(/href="([^"]+ResetPassword[^"]*)"/);
          if (match) { resetUrl = match[1].replaceAll('&amp;', '&'); break; }
        }
        if (resetUrl) break;
      }
      await page.waitForTimeout(500);
    }
    expect(resetUrl).toBeTruthy();

    await page.goto(resetUrl!);
    await page.getByTestId('reset-new').fill('neuesPW');
    await page.getByTestId('reset-confirm').fill('neuesPW');
    await page.getByTestId('reset-submit').click();
    await expect(page.getByTestId('reset-done')).toBeVisible();

    // Login mit neuem PW
    await page.goto('/Account/Login');
    await page.getByTestId('login-email').fill(email);
    await page.getByTestId('login-password').fill('neuesPW');
    await page.getByTestId('login-submit').click();
    await expect(page.getByTestId('home-greeting')).toContainText(email);
  });
});
