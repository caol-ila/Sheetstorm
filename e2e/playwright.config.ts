import { defineConfig } from '@playwright/test';

/**
 * Sheetstorm E2E configuration.
 *
 * Web-Frontend wird vom Aspire AppHost auf einem dynamischen Port
 * gehostet. Setze E2E_WEB_URL auf die Adresse, die Aspire ausgibt.
 */
export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 10_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: process.env.E2E_WEB_URL ?? 'https://localhost:7242',
    ignoreHTTPSErrors: true,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    // Onboarding-Tour vor jedem Test ausblenden
    storageState: {
      cookies: [],
      origins: [{
        origin: process.env.E2E_WEB_URL ?? 'https://localhost:7242',
        localStorage: [{ name: 'sheetstorm-tour-done', value: '1' }],
      }],
    },
  },
  projects: [
    { name: 'chromium', use: { browserName: 'chromium' } },
  ],
});
