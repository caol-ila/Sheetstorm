import { test, expect, type Page } from '@playwright/test';

/**
 * Test-Helpers für Sheetstorm E2E.
 *
 * Generiert eindeutige Test-User pro Run und kapselt häufige
 * Auth-Flows (Register + Email-Confirm via MailHog API).
 */

const MAILHOG_API = process.env.MAILHOG_API ?? 'http://localhost:8025';

let userCounter = 0;
const runId = Date.now().toString(36);

export function uniqueEmail(label = 'user'): string {
  userCounter += 1;
  return `${label}-${runId}-${userCounter}@example.test`;
}

export function uniqueSlug(label = 'verein'): string {
  return `${label}-${runId}-${userCounter}`.toLowerCase();
}

const PASSWORD = 'Test-Pass-1234!';

export async function registerUser(page: Page, email: string, displayName: string): Promise<void> {
  await page.goto('/Account/Register');
  await page.getByTestId('input-displayname').fill(displayName);
  await page.getByTestId('input-email').fill(email);
  await page.getByTestId('input-password').fill(PASSWORD);
  await page.getByTestId('register-submit').click();
  await expect(page.getByTestId('register-confirmation')).toBeVisible();
}

function decodeQuotedPrintable(s: string): string {
  // Strip soft line breaks first
  s = s.replace(/=\r?\n/g, '');
  // Decode =XX hex sequences
  return s.replace(/=([0-9A-Fa-f]{2})/g, (_, hex) => String.fromCharCode(parseInt(hex, 16)));
}

export async function confirmEmailViaMailhog(page: Page, email: string): Promise<void> {
  let confirmUrl: string | null = null;
  for (let i = 0; i < 40; i++) {
    const res = await fetch(`${MAILHOG_API}/api/v2/messages?limit=200`);
    if (res.ok) {
      const json: any = await res.json();
      const items: any[] = json.items ?? [];
      const found = items.find((m) => {
        const to = m.To?.[0];
        if (!to) return false;
        const addr = `${to.Mailbox}@${to.Domain}`.toLowerCase();
        return addr === email.toLowerCase();
      });
      if (found) {
        const decoded = decodeQuotedPrintable(found.Content?.Body ?? '');
        const match = decoded.match(/href="([^"]+)"/);
        if (match) {
          confirmUrl = match[1].replaceAll('&amp;', '&');
          break;
        }
      }
    }
    await page.waitForTimeout(500);
  }
  if (!confirmUrl) {
    throw new Error(`Keine Bestätigungs-Mail für ${email} in MailHog`);
  }
  await page.goto(confirmUrl);
  await expect(page.getByTestId('email-confirmed')).toBeVisible();
}

export async function login(page: Page, email: string): Promise<void> {
  await page.goto('/Account/Login');
  await page.getByTestId('login-email').fill(email);
  await page.getByTestId('login-password').fill(PASSWORD);
  await page.getByTestId('login-submit').click();
  // Nach Login landen wir auf "/"
  await expect(page.getByTestId('home-greeting')).toBeVisible();
}

export async function registerLoginFresh(page: Page, label = 'user'): Promise<{ email: string; displayName: string }> {
  const email = uniqueEmail(label);
  const displayName = `${label}-${runId}`;
  await registerUser(page, email, displayName);
  await confirmEmailViaMailhog(page, email);
  await login(page, email);
  return { email, displayName };
}

export async function deleteAllMail(): Promise<void> {
  try { await fetch(`${MAILHOG_API}/api/v1/messages`, { method: 'DELETE' }); } catch { /* ignore */ }
}
