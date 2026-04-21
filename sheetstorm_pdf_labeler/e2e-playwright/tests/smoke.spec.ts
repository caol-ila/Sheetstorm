import { test, expect } from '@playwright/test';

test.describe('PDF Labeler Web Smoke Test', () => {
  test('app boots and main UI is visible', async ({ page }) => {
    await page.goto('/');

    // Wait for Flutter to bootstrap
    // Flutter web uses a canvas-based rendering engine (CanvasKit or HTML renderer)
    // We look for the flt-glass-pane element which is Flutter's root container
    await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 30000 });

    // Check that the page title contains our app name
    await expect(page).toHaveTitle(/Sheetstorm PDF Labeler/i);

    // Take a screenshot to verify the UI loaded
    await page.screenshot({ path: 'test-results/main-screen.png', fullPage: true });

    // Flutter web renders via canvas, so text content is not in the DOM
    // Instead, we verify the canvas element is present and has dimensions
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible();

    const box = await canvas.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.width).toBeGreaterThan(100);
    expect(box!.height).toBeGreaterThan(100);
  });

  test('app responds to keyboard navigation (settings accessible)', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 30000 });

    // Flutter web apps typically support keyboard navigation
    // Tab through UI elements - exact behavior depends on the app's focus implementation
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');

    // Take screenshot after navigation
    await page.screenshot({ path: 'test-results/after-keyboard-nav.png', fullPage: true });

    // Verify app is still responsive (canvas still visible)
    const canvas = page.locator('canvas').first();
    await expect(canvas).toBeVisible();
  });

  test('app handles window resize', async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('flt-glass-pane, flutter-view', { timeout: 30000 });

    // Initial size
    await page.setViewportSize({ width: 1280, height: 720 });
    await page.waitForTimeout(500);

    let canvas = page.locator('canvas').first();
    let box = await canvas.boundingBox();
    expect(box!.width).toBeLessThanOrEqual(1280);

    // Resize to smaller
    await page.setViewportSize({ width: 800, height: 600 });
    await page.waitForTimeout(500);

    canvas = page.locator('canvas').first();
    box = await canvas.boundingBox();
    expect(box!.width).toBeLessThanOrEqual(800);

    await page.screenshot({ path: 'test-results/resized-window.png', fullPage: true });
  });
});
