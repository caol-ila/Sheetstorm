# Playwright E2E Tests for Flutter Web

## Overview

This directory contains Playwright-based smoke tests for the Flutter web build of the PDF Labeler app.

## Scope

These tests verify that the Flutter web build boots correctly and renders the main UI. They do NOT test the full labeling workflow, since the browser cannot spawn the .NET CLI process.

### What is tested:
- ✅ Flutter app loads and renders (canvas visible)
- ✅ App responds to keyboard navigation
- ✅ App handles window resize

### What is NOT tested:
- ❌ PDF labeling workflow (requires CLI process, not possible in browser)
- ❌ File picker dialogs (browser sandboxing limitations)
- ❌ Detailed UI interactions (Flutter web uses canvas rendering, no DOM text)

## Prerequisites

- Node.js 18+ and npm
- Flutter web build: `flutter build web --release` (from parent directory)

## Setup

```bash
npm install
npm run install:chromium
```

## Running Tests

```bash
# Headless run (CI-friendly)
npm test

# With browser visible
npm test:headed

# Interactive UI mode
npm test:ui

# Just serve the build (manual testing)
npm run serve:build
```

## Architecture

- **Web server**: `http-server` serves the Flutter web build from `../build/web` on port 4173
- **Playwright config**: Automatically starts/stops the web server
- **Tests**: TypeScript test files in `tests/` directory

## Limitations

### Flutter CanvasKit Rendering

Flutter web uses CanvasKit (or HTML renderer), which means the UI is rendered to a `<canvas>` element. This has implications for testing:

1. **No DOM text**: You cannot use `page.getByText('Submit')` — the text is drawn on canvas
2. **Limited semantic selectors**: Standard accessibility queries don't work
3. **Screenshot-based verification**: Visual regression testing is more reliable
4. **Keyboard navigation**: Can be tested, but results depend on app's focus handling

### Browser Sandboxing

The browser environment cannot:
- Spawn child processes (e.g., the .NET CLI)
- Access arbitrary file system paths (e.g., source/target folders)
- Use native file picker dialogs (would require user interaction)

Thus, these tests focus on **UI loading and responsiveness**, not the full E2E workflow.

## CI Integration

```yaml
# Example GitHub Actions snippet
- name: Build Flutter web
  run: flutter build web --release

- name: Run Playwright tests
  working-directory: sheetstorm_pdf_labeler/e2e-playwright
  run: |
    npm install
    npx playwright install chromium
    npm test
```

## Further Reading

- [Playwright Documentation](https://playwright.dev/)
- [Flutter Web Renderers](https://docs.flutter.dev/platform-integration/web/renderers)
