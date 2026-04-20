# E2E Tests — Sheetstorm

End-to-End-Tests für die Sheetstorm Flutter Web App mit Playwright.

## Voraussetzungen

1. **Node.js** (v18+) und **npm**
2. **.NET SDK 10** (für Backend)
3. **Flutter SDK** (für Flutter Web)
4. **Docker** (für PostgreSQL via Aspire)

## Lokaler Setup (Windows)

### 1. Backend + DB über Aspire starten

```powershell
Set-Location C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\src\Sheetstorm.AppHost
dotnet run
```

Das startet:
- PostgreSQL Container (Port 5432)
- Sheetstorm.Api (HTTPS Port 7001, HTTP Port 5001)
- Aspire Dashboard (Port 15000)

### 2. Flutter Web separat starten

**WICHTIG:** Aspire-Integration für Flutter Web ist noch TODO. Flutter Web muss manuell gestartet werden.

```powershell
Set-Location C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\sheetstorm_app
flutter run -d chrome --web-port 8080 `
  --dart-define=API_BASE_URL=https://localhost:7001
```

**Alternative:** HTML-Renderer für bessere Playwright-Kompatibilität (Semantics-Selektoren):

```powershell
flutter run -d chrome --web-port 8080 `
  --web-renderer html `
  --dart-define=API_BASE_URL=https://localhost:7001
```

### 3. Playwright installieren + Tests ausführen

```powershell
Set-Location C:\Privat\Sheetstorm-worktrees\feat-app-scaffold\sheetstorm_app

# Dependencies installieren
npm install

# Playwright Chromium Browser installieren
npm run e2e:install

# E2E Tests ausführen
npm run test:e2e
```

**Mit UI Mode (interaktiv):**

```powershell
npm run test:e2e:ui
```

**Mit sichtbarem Browser (headed):**

```powershell
npm run test:e2e:headed
```

**Test-Report ansehen:**

```powershell
npm run test:e2e:report
```

## CanvasKit vs HTML Renderer

Flutter Web nutzt standardmäßig **CanvasKit** als Renderer. Das bedeutet:

- ✅ **Pro:** Pixelgenaues Rendering, konsistent über Browser hinweg
- ❌ **Contra:** DOM ist opaque — Playwright kann Text nicht direkt mit `getByText()` finden

### Lösungsansätze für E2E-Tests

1. **HTML Renderer nutzen** (Dev/Test-Only):
   ```powershell
   flutter run -d chrome --web-renderer html --web-port 8080
   ```

2. **Flutter Semantics aktivieren** (empfohlener Weg):
   
   In `sheetstorm_app/web/index.html` (vor `flutter.js` Bootstrap):
   ```html
   <script>
     window.flutterSemanticsEnabled = true;
   </script>
   ```
   Dann nutzen wir `getByRole()`, `getByLabel()` etc.

3. **Screenshot-basierte Verifizierung** (Fallback):
   
   Siehe `ping-roundtrip.spec.ts` — wir nehmen Screenshots als Evidenz und prüfen via Visual Regression (wenn nötig).

4. **Keyboard-Navigation** (Accessibility-Test):
   
   Funktioniert unabhängig vom Renderer — siehe `ping-roundtrip.spec.ts`.

**Aktuelle Strategie:** Kombination aus (2) + (3) + (4). Siehe Framework-Spec §6.3.

## Test-Struktur

```
sheetstorm_app/
├── e2e/
│   ├── ping-roundtrip.spec.ts   # Ping-Antwort wird angezeigt
│   └── README.md                # Diese Datei
├── playwright.config.ts          # Playwright-Konfiguration
├── package.json                  # npm-Scripts
└── test-results/                 # Screenshots + Traces (gitignored)
```

## CI/CD Integration

In GitHub Actions muss Folgendes sichergestellt werden:

1. **Aspire + PostgreSQL starten** (via `dotnet run` in AppHost)
2. **Flutter Web starten** (via `flutter run -d web-server --web-port 8080`)
3. **Playwright Tests ausführen** (via `npm run test:e2e`)

Siehe `.github/workflows/e2e.yml` (TODO: noch zu implementieren).

## Troubleshooting

### Playwright findet keine Texte

**Problem:** CanvasKit-Renderer macht DOM opaque.

**Lösung:**
1. Flutter Semantics aktivieren (siehe oben)
2. HTML-Renderer für Tests nutzen (`--web-renderer html`)
3. Screenshots als Fallback verwenden

### Flutter Web lädt nicht

**Problem:** Port 8080 ist belegt.

**Lösung:**
```powershell
# Anderen Port nutzen
flutter run -d chrome --web-port 8081
# FLUTTER_WEB_URL setzen
$env:FLUTTER_WEB_URL="http://localhost:8081"
npm run test:e2e
```

### Backend nicht erreichbar

**Problem:** Aspire läuft nicht.

**Lösung:**
```powershell
cd src\Sheetstorm.AppHost
dotnet run
```

### CORS-Fehler

**Problem:** Flutter Web läuft auf anderem Port als in Aspire konfiguriert.

**Lösung:** In `src/Sheetstorm.Api/Program.cs` CORS-Policy anpassen:

```csharp
policy.WithOrigins("http://localhost:8080", "http://localhost:8081")
```

## Referenzen

- **Playwright Docs:** https://playwright.dev/
- **Flutter Web Semantics:** https://docs.flutter.dev/platform-integration/web/semantics
- **Framework-Spec §6.3:** Siehe `docs/specs/00-framework-and-process.md` (Branch `docs/framework-and-process-spec`)
- **Copilot-Instructions E2E:** Siehe `.github/copilot-instructions.md` Zeile 261-281
