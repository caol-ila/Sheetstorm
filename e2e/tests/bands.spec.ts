import { test, expect } from '@playwright/test';
import { registerLoginFresh, uniqueSlug } from './helpers';

test.describe('Iteration 1 — Vereine', () => {

  test('Owner erstellt Verein und sieht ihn als aktiv', async ({ page }) => {
    await registerLoginFresh(page, 'owner');

    await page.goto('/Bands');
    await expect(page.getByTestId('no-bands')).toBeVisible();

    const slug = uniqueSlug('mv');
    await page.getByTestId('newband-name').fill('Musikverein Testdorf');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    await expect(page).toHaveURL(new RegExp(`/Bands/${slug}`));
    await expect(page.getByTestId('band-title')).toHaveText('Musikverein Testdorf');

    // Mitglieder-Tabelle hat den Owner mit Owner-Rolle
    await expect(page.getByTestId('members-table')).toBeVisible();
    const memberRoles = await page.getByTestId('member-roles').first().textContent();
    expect(memberRoles).toContain('Owner');
    expect(memberRoles).toContain('Admin');
  });

  test('Beitritt per Code: Owner generiert Code, anderer Nutzer reicht ein, Owner approved', async ({ browser }) => {
    // Owner-Kontext
    const ownerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ownerPage = await ownerCtx.newPage();
    await registerLoginFresh(ownerPage, 'owner');

    const slug = uniqueSlug('mv');
    await ownerPage.goto('/Bands');
    await ownerPage.getByTestId('newband-name').fill('Verein A');
    await ownerPage.getByTestId('newband-slug').fill(slug);
    await ownerPage.getByTestId('newband-submit').click();
    await expect(ownerPage).toHaveURL(new RegExp(`/Bands/${slug}`));

    // Code generieren
    await ownerPage.getByTestId('gen-code').click();
    const codeEl = ownerPage.getByTestId('generated-code-value');
    await expect(codeEl).toBeVisible();
    const code = (await codeEl.textContent())!.trim();
    expect(code).toMatch(/^[A-Z2-9]{8}$/);

    // Joiner-Kontext
    const joinerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const joinerPage = await joinerCtx.newPage();
    const joiner = await registerLoginFresh(joinerPage, 'joiner');

    await joinerPage.goto('/Bands');
    await joinerPage.getByTestId('joincode-input').fill(code);
    await joinerPage.getByTestId('joincode-submit').click();
    await expect(joinerPage.getByTestId('join-message')).toBeVisible();

    // Owner approved — kurz warten damit DB-commit sicher durch ist
    await ownerPage.waitForTimeout(500);
    await ownerPage.goto(`/Bands/${slug}`);
    const pendingRow = ownerPage.getByTestId('pending-request');
    await expect(pendingRow).toContainText(joiner.email);
    await pendingRow.getByTestId('approve').click();

    // Joiner sieht Verein nach Reload
    await joinerPage.goto('/Bands');
    await expect(joinerPage.getByTestId('bands-list')).toContainText('Verein A');

    await ownerCtx.close();
    await joinerCtx.close();
  });

  test('Einladung per Mail: Owner lädt ein, anderer Nutzer akzeptiert', async ({ browser }) => {
    const ownerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ownerPage = await ownerCtx.newPage();
    await registerLoginFresh(ownerPage, 'owner');

    const slug = uniqueSlug('mv');
    await ownerPage.goto('/Bands');
    await ownerPage.getByTestId('newband-name').fill('Verein B');
    await ownerPage.getByTestId('newband-slug').fill(slug);
    await ownerPage.getByTestId('newband-submit').click();
    await expect(ownerPage).toHaveURL(new RegExp(`/Bands/${slug}`));

    // Joiner zuerst registrieren (damit AcceptInvitation funktioniert)
    const joinerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const joinerPage = await joinerCtx.newPage();
    const joiner = await registerLoginFresh(joinerPage, 'invitee');

    // Owner lädt joiner ein
    await ownerPage.getByTestId('invite-email').fill(joiner.email);
    await ownerPage.getByTestId('invite-submit').click();
    const linkEl = ownerPage.getByTestId('invite-url');
    await expect(linkEl).toBeVisible();
    const inviteUrl = (await linkEl.textContent())!.trim();
    expect(inviteUrl).toContain('/Account/AcceptInvitation?token=');

    // Joiner besucht Link
    await joinerPage.goto(inviteUrl);
    await expect(joinerPage.getByTestId('invite-success')).toBeVisible();

    // Joiner sieht Verein
    await joinerPage.goto('/Bands');
    await expect(joinerPage.getByTestId('bands-list')).toContainText('Verein B');

    await ownerCtx.close();
    await joinerCtx.close();
  });

  test('Admin entzieht Dirigent-Rolle', async ({ browser }) => {
    const ownerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ownerPage = await ownerCtx.newPage();
    await registerLoginFresh(ownerPage, 'admin');

    const slug = uniqueSlug('mv');
    await ownerPage.goto('/Bands');
    await ownerPage.getByTestId('newband-name').fill('Verein C');
    await ownerPage.getByTestId('newband-slug').fill(slug);
    await ownerPage.getByTestId('newband-submit').click();

    // Mitglied einladen
    const joinerCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const joinerPage = await joinerCtx.newPage();
    const joiner = await registerLoginFresh(joinerPage, 'member');

    await ownerPage.getByTestId('invite-email').fill(joiner.email);
    await ownerPage.getByTestId('invite-submit').click();
    const inviteUrl = (await ownerPage.getByTestId('invite-url').textContent())!.trim();
    await joinerPage.goto(inviteUrl);
    await expect(joinerPage.getByTestId('invite-success')).toBeVisible();

    // Owner reload, sieht joiner als Mitglied
    await ownerPage.reload();
    const memberRow = ownerPage.locator('[data-testid="member-row"]', { hasText: joiner.email });
    await expect(memberRow).toBeVisible();

    // Dirigent-Rolle gewähren
    await memberRow.getByTestId('toggle-conductor').click();
    await expect(memberRow.getByTestId('member-roles')).toContainText('Dirigent');

    // Dirigent-Rolle wieder entziehen
    await memberRow.getByTestId('toggle-conductor').click();
    const finalRoles = await memberRow.getByTestId('member-roles').textContent();
    expect(finalRoles).not.toContain('Dirigent');

    await ownerCtx.close();
    await joinerCtx.close();
  });

  test('Profil: bevorzugte Stimme setzen wird persistiert', async ({ page }) => {
    await registerLoginFresh(page, 'maria');

    const slug = uniqueSlug('mv');
    await page.goto('/Bands');
    await page.getByTestId('newband-name').fill('Verein D');
    await page.getByTestId('newband-slug').fill(slug);
    await page.getByTestId('newband-submit').click();

    await page.goto('/Account/Profile');
    await expect(page.getByTestId('profile-membership').first()).toBeVisible();

    const select = page.getByTestId('primary-instrument-select').first();
    // Klarinette in B exakt — "Bassklarinette in B" enthält denselben Text, deshalb Locator über exakte Option
    await select.selectOption({ label: 'Klarinette in B (in B)' });
    await page.getByTestId('primary-instrument-save').first().click();

    await expect(page.getByTestId('primary-instrument-current').first()).toContainText('Klarinette in B');

    // Reload — Persistenz prüfen
    await page.reload();
    await expect(page.getByTestId('primary-instrument-current').first()).toContainText('Klarinette in B');
  });
});
