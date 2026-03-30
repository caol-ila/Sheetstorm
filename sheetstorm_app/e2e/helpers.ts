import { type Page, expect } from '@playwright/test';

/**
 * Wartet bis die Flutter-Web-App vollständig geladen ist.
 *
 * Flutter Web (CanvasKit) rendert auf ein <canvas>-Element.
 * Die App ist geladen, wenn das Flutter-Engine-Initialisierungs-Skript
 * fertig ist und die erste Route gerendert wurde.
 */
export async function waitForFlutterReady(page: Page): Promise<void> {
  // Warte auf das Flutter-Glass-Pane (Hauptcontainer der Flutter-App)
  await page.waitForSelector('flutter-view, flt-glass-pane', {
    state: 'attached',
    timeout: 20_000,
  });

  // Kurz warten bis Flutter die erste Route rendert
  await page.waitForTimeout(2_000);
}

/**
 * Navigiert zur App und wartet auf Flutter-Initialisierung.
 */
export async function navigateAndWaitForFlutter(
  page: Page,
  path = '/',
): Promise<void> {
  await page.goto(path);
  await waitForFlutterReady(page);
}

/**
 * Prüft ob ein Text im Accessibility-Tree sichtbar ist.
 *
 * Flutter Web erstellt Semantik-Nodes im Shadow DOM.
 * Diese Funktion durchsucht sowohl reguläre DOM-Elemente
 * als auch Flutter-Semantik-Elemente.
 */
export async function expectTextVisible(
  page: Page,
  text: string,
): Promise<void> {
  // Versuche zuerst Standard-Playwright-Locator
  const locator = page.getByText(text, { exact: false });
  const count = await locator.count();

  if (count > 0) {
    await expect(locator.first()).toBeVisible();
    return;
  }

  // Fallback: Suche im Flutter Semantics Shadow DOM
  const found = await page.evaluate((searchText) => {
    const findInShadowRoots = (root: Document | ShadowRoot): boolean => {
      const walker = document.createTreeWalker(
        root as unknown as Node,
        NodeFilter.SHOW_ELEMENT,
      );
      let node = walker.nextNode();
      while (node) {
        if (node.textContent?.includes(searchText)) return true;
        if ((node as Element).shadowRoot) {
          if (findInShadowRoots((node as Element).shadowRoot!)) return true;
        }
        node = walker.nextNode();
      }
      return false;
    };
    return findInShadowRoots(document);
  }, text);

  expect(found, `Text "${text}" sollte sichtbar sein`).toBe(true);
}

/**
 * Wartet auf eine URL-Änderung (GoRouter-Navigation).
 */
export async function waitForRoute(
  page: Page,
  route: string,
): Promise<void> {
  await page.waitForURL(`**${route}**`, { timeout: 10_000 });
}

/**
 * Macht einen Screenshot mit beschreibendem Namen.
 */
export async function takeNamedScreenshot(
  page: Page,
  name: string,
): Promise<Buffer> {
  return await page.screenshot({
    path: `test-results/screenshots/${name}.png`,
    fullPage: true,
  });
}
