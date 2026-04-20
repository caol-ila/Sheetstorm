# E2E Testing Operations Guide — Sheetstorm

Umfassende Anleitung für End-to-End-Testing mit Playwright in Sheetstorm.

## Übersicht

Sheetstorm nutzt **Playwright** für End-to-End-Tests der Flutter Web App. Diese Tests verifizieren den gesamten Stack: Flutter Frontend → ASP.NET Core Backend → PostgreSQL Datenbank.

**Technologien:**
- **Playwright 1.48.0** (TypeScript)
- **Flutter Web** (CanvasKit + HTML Renderer)
- **ASP.NET Core 10** Backend
- **.NET Aspire** Orchestrierung
- **PostgreSQL 16** Datenbank

---

## 1. Lokaler DevLoop

### 1.1 Erstmalige Einrichtung

```powershell
# 1. Backend Dependencies (einmalig)
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold
dotnet restore

# 2. Flutter Dependencies (einmalig)
cd sheetstorm_app
flutter pub get

# 3. Playwright Dependencies (einmalig)
npm install
npm run e2e:install  # Installiert Chromium Browser
```

### 1.2 Dev-Stack starten

**Terminal 1:** Aspire + Backend + PostgreSQL

```powershell
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\src\Sheetstorm.AppHost
dotnet run
```

**Output:**
- Aspire Dashboard: `http://localhost:15000`
- Backend API (HTTPS): `https://localhost:7001`
- Backend API (HTTP): `http://localhost:5001`
- PostgreSQL: `localhost:5432` (Container)

**Terminal 2:** Flutter Web

```powershell
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\sheetstorm_app
flutter run -d chrome --web-port 8080 `
  --dart-define=API_BASE_URL=https://localhost:7001
```

**Alternative mit HTML-Renderer (bessere Test-Kompatibilität):**

```powershell
flutter run -d chrome --web-port 8080 `
  --web-renderer html `
  --dart-define=API_BASE_URL=https://localhost:7001
```

### 1.3 E2E-Tests ausführen

**Terminal 3:** Playwright Tests

```powershell
cd C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\sheetstorm_app
npm run test:e2e
```

**Interaktiver UI-Mode (empfohlen für Dev):**

```powershell
npm run test:e2e:ui
```

**Mit sichtbarem Browser (Debugging):**

```powershell
npm run test:e2e:headed
```

---

## 2. CanvasKit vs HTML Renderer — Deep Dive

### 2.1 Problem

Flutter Web rendert standardmäßig mit **CanvasKit**:
- Rendering passiert auf `<canvas>` Element
- DOM ist opaque — keine semantischen HTML-Elemente
- Playwright kann `getByText("Hallo")` **nicht** finden

### 2.2 Lösungsansätze

#### Option 1: HTML-Renderer (Dev/Test-Only)

**Pro:**
- DOM ist vollständig zugänglich
- `getByText()`, `getByRole()` funktionieren out-of-the-box

**Contra:**
- Rendering unterscheidet sich vom Prod-Build
- Performance schlechter als CanvasKit

**Nutzung:**

```powershell
flutter run -d chrome --web-renderer html --web-port 8080
```

#### Option 2: Flutter Semantics aktivieren (Empfohlen)

**Pro:**
- CanvasKit bleibt aktiv (Prod-ähnlich)
- Accessibility-Baum wird parallel zum Canvas erstellt
- `getByRole()`, `getByLabel()` funktionieren

**Contra:**
- Erfordert manuelles Flag-Setzen
- Nicht alle Widgets haben automatisch Semantics

**Umsetzung:**

In `sheetstorm_app/web/index.html` **vor** Flutter-Bootstrap:

```html
<!DOCTYPE html>
<html>
<head>
  <!-- ... -->
</head>
<body>
  <script>
    // WICHTIG: Vor flutter.js laden!
    window.flutterSemanticsEnabled = true;
  </script>
  
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

In Flutter-Widgets Semantics explizit setzen:

```dart
// Beispiel: Button mit Semantic Label
Semantics(
  label: 'Ping-Antwort anzeigen',
  button: true,
  child: ElevatedButton(
    onPressed: () => pingProvider.refresh(),
    child: Text('Ping'),
  ),
)
```

#### Option 3: Screenshot-basierte Verifizierung (Fallback)

**Pro:**
- Funktioniert immer, unabhängig von Renderer
- Visuelle Regression Testing möglich

**Contra:**
- Keine Semantic-Prüfung
- Flaky bei Animationen/Timing
- Hoher Wartungsaufwand

**Nutzung:**

```typescript
// In Playwright-Test
await page.screenshot({ path: 'test-results/home.png', fullPage: true });
// Manuell verifizieren oder mit Snapshot-Tool vergleichen
```

#### Option 4: Keyboard-Navigation (Accessibility-Smoke)

**Pro:**
- Funktioniert renderer-unabhängig
- Testet echte Accessibility
- Minimaler Wartungsaufwand

**Contra:**
- Keine inhaltliche Verifizierung

**Nutzung:**

```typescript
await page.keyboard.press('Tab');
const focused = await page.evaluate(() => document.activeElement?.tagName);
expect(focused).not.toBe('BODY');
```

### 2.3 Aktuelle Sheetstorm-Strategie

**Kombination aus Option 2 + 3 + 4:**

1. **Primär:** Semantics aktivieren + `getByRole()` / `getByLabel()`
2. **Fallback:** Screenshots als Evidenz
3. **Zusätzlich:** Keyboard-Navigation für Accessibility-Smoke

Siehe `sheetstorm_app/e2e/ping-roundtrip.spec.ts` als Referenz.

---

## 3. Test-Strategien

### 3.1 Test-Pyramide

```
        E2E (Playwright)         ← Wenige, kritische User-Flows
       /                  \
      /   Integration      \     ← API + DB (xUnit + Testcontainers)
     /    (xUnit)           \
    /                        \
   /     Widget Tests         \  ← Flutter UI-Logik (testWidgets)
  /      (Flutter Test)        \
 /____________________________\ 
       Unit Tests               ← Domain-Logik (xUnit + FlutterTest)
```

**Faustregel:**
- **70%** Unit-Tests
- **20%** Integration-Tests
- **10%** E2E-Tests

### 3.2 Was sollte E2E-getestet werden?

**✅ JA:**
- Kritische User-Flows (Login, Hauptfeature-Abläufe)
- Datenfluss Frontend → Backend → DB → Frontend
- Responsive Layouts (Phone/Tablet/Desktop)
- Accessibility (Keyboard-Navigation, Screen-Reader-Struktur)

**❌ NEIN:**
- Edge-Cases der Business-Logik (→ Unit-Tests)
- Einzelne Widget-Interaktionen (→ Widget-Tests)
- API-Fehler-Handling (→ Integration-Tests)

### 3.3 Sheetstorm E2E-Test-Struktur

```typescript
test.describe('Feature-Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Login, Navigiere zur Seite, etc.
  });

  test('Happy Path: Haupt-Workflow funktioniert', async ({ page }) => {
    // 1. Aktion durchführen
    // 2. Erwartetes Ergebnis verifizieren
    // 3. Screenshot als Evidenz
  });

  test('Accessibility: Keyboard-Navigation', async ({ page }) => {
    // Tab, Enter, Arrow-Keys funktionieren
  });

  test('Responsive: Layout auf Tablet-Breite', async ({ page }) => {
    await page.setViewportSize({ width: 768, height: 1024 });
    // Erwartetes Layout verifizieren
  });
});
```

---

## 4. Playwright-Konfiguration

### 4.1 Wichtige Settings

In `sheetstorm_app/playwright.config.ts`:

```typescript
export default defineConfig({
  testDir: './e2e',                     // Test-Ordner
  baseURL: process.env.FLUTTER_WEB_URL ?? 'http://localhost:8080',
  
  use: {
    trace: 'on-first-retry',            // Trace bei Fehlschlag
    screenshot: 'only-on-failure',      // Screenshot bei Fehlschlag
    viewport: { width: 1280, height: 720 }, // Desktop-Viewport
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    // Firefox + Safari optional für Cross-Browser-Testing
  ],

  // webServer: { ... } // TODO: Automatisiere Aspire + Flutter-Start
});
```

### 4.2 Environment-Variablen

**`FLUTTER_WEB_URL`:** Überschreibt `baseURL` (für CI oder andere Ports)

```powershell
$env:FLUTTER_WEB_URL="http://localhost:8081"
npm run test:e2e
```

**`CI`:** Aktiviert CI-spezifische Settings (Retries, kein Parallel-Testing)

---

## 5. CI/CD-Integration

### 5.1 GitHub Actions Workflow (TODO)

Datei: `.github/workflows/e2e.yml`

```yaml
name: E2E Tests

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  e2e:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      # 1. Install .NET SDK
      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '10.0.x'
      
      # 2. Install Flutter SDK
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      # 3. Install Node.js
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      
      # 4. Restore .NET Dependencies
      - run: dotnet restore
      
      # 5. Start Aspire (Background)
      - run: |
          cd src/Sheetstorm.AppHost
          dotnet run &
          sleep 30  # Wait for Aspire to be ready
      
      # 6. Start Flutter Web (Background)
      - run: |
          cd sheetstorm_app
          flutter pub get
          flutter run -d web-server --web-port 8080 \
            --dart-define=API_BASE_URL=https://localhost:7001 &
          sleep 20  # Wait for Flutter to be ready
      
      # 7. Install Playwright
      - run: |
          cd sheetstorm_app
          npm install
          npx playwright install --with-deps chromium
      
      # 8. Run E2E Tests
      - run: |
          cd sheetstorm_app
          npm run test:e2e
      
      # 9. Upload Playwright Report
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: sheetstorm_app/playwright-report/
```

### 5.2 Timing-Herausforderungen in CI

**Problem:** Aspire + Flutter brauchen Zeit zum Starten.

**Lösung:**

1. **Health-Checks nutzen:**
   ```bash
   until curl -f http://localhost:8080/health; do sleep 2; done
   ```

2. **Playwright `waitForURL()` nutzen:**
   ```typescript
   await page.goto('/');
   await page.waitForLoadState('networkidle');
   ```

3. **Timeouts erhöhen in CI:**
   ```typescript
   expect(locator).toBeVisible({ timeout: 30_000 }); // 30s statt 10s
   ```

---

## 6. Debugging

### 6.1 Playwright Inspector

**Interaktives Debugging:**

```powershell
cd sheetstorm_app
npx playwright test --debug
```

**Features:**
- Step-through Tests
- Live DOM-Inspektion
- Selector-Picker
- Console-Logs

### 6.2 Trace Viewer

**Nach Fehlschlag Trace ansehen:**

```powershell
npx playwright show-trace test-results/.../trace.zip
```

**Features:**
- Timeline der Actions
- Netzwerk-Requests
- Screenshots pro Step
- DOM-Snapshots

### 6.3 Screenshots + Videos

**Screenshots:**

```typescript
await page.screenshot({ path: 'debug.png', fullPage: true });
```

**Videos (in Config aktivieren):**

```typescript
use: {
  video: 'retain-on-failure',
}
```

### 6.4 Häufige Fehler

**1. "Timeout 10000ms exceeded"**

**Ursache:** Element nicht gefunden (CanvasKit?) oder langsame Netzwerk-Requests.

**Lösung:**
- Timeout erhöhen: `{ timeout: 30_000 }`
- `waitForLoadState('networkidle')` vor Interaktion
- Screenshot machen, um DOM zu inspizieren

**2. "Navigation failed because page was closed"**

**Ursache:** Flutter Web Crash oder Navigations-Redirect.

**Lösung:**
- `page.on('console', msg => console.log(msg.text()))` aktivieren
- Flutter DevTools öffnen (`flutter run` Output zeigt URL)

**3. "getByText() findet nichts"**

**Ursache:** CanvasKit-Rendering.

**Lösung:**
- Semantics aktivieren (siehe Abschnitt 2.2)
- `getByRole()` statt `getByText()` nutzen
- Screenshot-Fallback

---

## 7. Best Practices

### 7.1 Page Object Model (POM)

**Anti-Pattern:**

```typescript
// Direkt im Test
await page.getByRole('button', { name: 'Login' }).click();
await page.getByLabel('Username').fill('test');
```

**Best Practice:**

```typescript
// pages/login-page.ts
export class LoginPage {
  constructor(private page: Page) {}

  async login(username: string, password: string) {
    await this.page.getByLabel('Username').fill(username);
    await this.page.getByLabel('Password').fill(password);
    await this.page.getByRole('button', { name: 'Login' }).click();
  }
}

// login.spec.ts
test('Login funktioniert', async ({ page }) => {
  const loginPage = new LoginPage(page);
  await loginPage.login('test', 'password');
});
```

### 7.2 Test-Daten-Management

**Problem:** Flaky Tests wegen inkonsistenter Daten.

**Lösungen:**

1. **Testcontainers:** Jeder Test bekommt frische DB (Backend-Integration-Tests)
2. **Fixtures:** Seed-Daten vor Test laden
3. **Cleanup:** Nach Test aufräumen (`test.afterEach`)

### 7.3 Selektoren-Strategie

**Präferenz-Reihenfolge:**

1. **`getByRole()`** — Accessibility-freundlich, robust
2. **`getByLabel()`** — Für Formulare
3. **`getByPlaceholder()`** — Für Inputs
4. **`getByText()`** — Für statische Texte (CanvasKit-Probleme!)
5. **`getByTestId()`** — Letzter Ausweg, explizites `data-testid`

**❌ Vermeide:**
- CSS-Selektoren (`page.locator('.my-class')`)
- XPath (`//div[@class="..."]`)

### 7.4 Assertions

**Playwright-native:**

```typescript
await expect(page.getByRole('heading')).toHaveText('Sheetstorm');
await expect(page.getByLabel('Email')).toBeVisible();
await expect(page).toHaveURL(/dashboard/);
```

**Custom Matchers** (wenn nötig):

```typescript
// test-utils/matchers.ts
export async function toContainFlutterText(page: Page, text: string) {
  const screenshot = await page.screenshot();
  // OCR oder Pixel-Vergleich
}
```

---

## 8. Troubleshooting

### 8.1 Aspire läuft nicht

**Symptom:**
```
Error: connect ECONNREFUSED 127.0.0.1:7001
```

**Diagnose:**

```powershell
cd src\Sheetstorm.AppHost
dotnet run
# Warte auf "Application started" im Terminal
```

**Häufige Ursachen:**
- PostgreSQL-Container startet nicht (Docker läuft nicht?)
- Port 7001 ist belegt
- NuGet-Restore fehlgeschlagen

### 8.2 Flutter Web lädt nicht

**Symptom:**
```
Timeout while waiting for http://localhost:8080
```

**Diagnose:**

```powershell
cd sheetstorm_app
flutter run -d chrome --web-port 8080 -v  # Verbose-Modus
```

**Häufige Ursachen:**
- Port 8080 belegt → Anderer Port nutzen
- `flutter pub get` nicht ausgeführt
- ARB-Generierung fehlgeschlagen (`flutter gen-l10n`)

### 8.3 CORS-Fehler

**Symptom (in Browser DevTools):**
```
Access to XMLHttpRequest at 'https://localhost:7001/ping' from origin 
'http://localhost:8080' has been blocked by CORS policy
```

**Lösung:**

In `src/Sheetstorm.Api/Program.cs`:

```csharp
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("http://localhost:8080", "http://localhost:8081")
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});
```

### 8.4 Playwright installiert Browser nicht

**Symptom:**
```
Executable doesn't exist at C:\Users\...\chromium-1234\chrome.exe
```

**Lösung:**

```powershell
cd sheetstorm_app
npx playwright install chromium --with-deps
```

**Windows-spezifisch:** PowerShell als Admin ausführen.

---

## 9. Referenzen

- **Playwright Docs:** https://playwright.dev/docs/intro
- **Flutter Web Semantics:** https://docs.flutter.dev/platform-integration/web/semantics
- **Testcontainers .NET:** https://dotnet.testcontainers.org/
- **Aspire Docs:** https://learn.microsoft.com/en-us/dotnet/aspire/
- **Framework-Spec §6:** `docs/specs/00-framework-and-process.md` (Branch `docs/framework-and-process-spec`)
- **Copilot-Instructions:** `.github/copilot-instructions.md` (E2E-Sektion Zeile 261-281)
- **E2E Quickstart:** `sheetstorm_app/e2e/README.md`

---

## 10. Checkliste vor Merge

Vor jedem PR mit E2E-Änderungen:

- [ ] E2E-Tests lokal grün (`npm run test:e2e`)
- [ ] Screenshots/Traces in `test-results/` nicht committed (gitignored)
- [ ] Page Object Model genutzt (bei komplexen Flows)
- [ ] Accessibility-Selektoren (`getByRole`) bevorzugt
- [ ] Keyboard-Navigation getestet (wo sinnvoll)
- [ ] Timeouts ausreichend für CI (min. 15s)
- [ ] Dokumentation aktualisiert (bei neuen Test-Patterns)
