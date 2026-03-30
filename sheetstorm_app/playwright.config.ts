import { defineConfig } from '@playwright/test';

/**
 * Playwright-Konfiguration für Sheetstorm E2E-Tests.
 *
 * Voraussetzung: Dev-Stack läuft (`.\start.ps1 -Web` im Repo-Root).
 * Flutter Web muss mit festem Port gestartet werden:
 *   flutter run -d chrome --web-port 8080
 *
 * Hinweis: Flutter Web nutzt standardmäßig CanvasKit (Canvas-Rendering).
 * Für bessere DOM-Interaktion kann der HTML-Renderer verwendet werden:
 *   flutter run -d chrome --web-renderer html --web-port 8080
 */
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  expect: {
    timeout: 10_000,
  },
  fullyParallel: false,
  retries: 1,
  reporter: [['html', { open: 'never' }]],
  use: {
    baseURL: process.env.FLUTTER_WEB_URL ?? 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'on-first-retry',
  },
  projects: [
    {
      name: 'chromium',
      use: { browserName: 'chromium' },
    },
  ],
});
