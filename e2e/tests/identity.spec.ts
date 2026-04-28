import { test, expect } from '@playwright/test';
import { registerUser, confirmEmailViaMailhog, login, registerLoginFresh, uniqueEmail } from './helpers';

test.describe('Iteration 1 — Identität', () => {

  test('Neuer Nutzer registriert sich, bestätigt E-Mail, loggt ein', async ({ page }) => {
    const email = uniqueEmail('reg');
    await registerUser(page, email, 'Maria Klarinette');
    await confirmEmailViaMailhog(page, email);
    await login(page, email);

    await expect(page.getByTestId('home-greeting')).toContainText(email);
    await expect(page.getByTestId('home-no-bands')).toBeVisible();
  });

  test('Nicht-eingeloggter User wird auf Login umgeleitet', async ({ page }) => {
    await page.goto('/Bands');
    await expect(page).toHaveURL(/Account\/Login/);
  });
});
