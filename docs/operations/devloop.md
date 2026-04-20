# DevLoop Guide — Sheetstorm

Schritt-für-Schritt-Anleitung für neue Contributors, um die Sheetstorm-Entwicklungsumgebung aufzusetzen und produktiv zu werden.

---

## 1. Repository clonen + Worktree Policy lesen

### Clonen

```powershell
git clone https://github.com/caol-ila/Sheetstorm.git
Set-Location Sheetstorm
```

### Worktree-Policy

Dieses Projekt nutzt **git worktrees** für parallele Feature-Arbeit.

**Warum?** Parallele Branches ohne Stash/Checkout-Chaos, mehrere AI-Agenten arbeiten gleichzeitig an verschiedenen Features.

**Policy:** Siehe `.squad/README.md` oder `.squad/worktree-setup.md`

Kurz:
- Worktrees in `C:\Privat\Sheetstorm-worktrees\<branch-name>`
- Main-Repo ist read-only (nur Pull/Fetch)
- Jeder Feature-Branch → eigenes Worktree

**Worktree erstellen:**

```powershell
git worktree add -b feat/my-feature C:\Privat\Sheetstorm-worktrees\feat-my-feature origin/main
Set-Location C:\Privat\Sheetstorm-worktrees\feat-my-feature
```

---

## 2. Voraussetzungen installieren

### Windows-spezifische Hinweise

- **PowerShell 7+:** [Installationsanleitung](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
- **Git for Windows:** [Download](https://git-scm.com/download/win)
- **Visual Studio Code:** Empfohlen, mit Extensions für C#, Flutter, Playwright

### .NET SDK

**Empfohlen:** .NET 10 SDK (falls verfügbar), alternativ .NET 9 SDK

```powershell
dotnet --version  # Sollte 9.x oder 10.x zeigen
```

Download: https://dotnet.microsoft.com/download

**Aspire Workload installieren:**

```powershell
dotnet workload install aspire
```

> **Hinweis:** Ohne Aspire-Workload ist `Sheetstorm.AppHost` ein Platzhalter. Backend kann trotzdem direkt via `dotnet run --project src/Sheetstorm.Api` gestartet werden.

### Flutter SDK

**Version:** 3.5+ (3.24+ empfohlen)

**Installation:** https://docs.flutter.dev/get-started/install/windows

**Nach Installation:**

```powershell
flutter --version
flutter doctor -v  # Überprüft Setup
```

**Plattformen aktivieren:**

```powershell
flutter config --enable-web
flutter config --enable-windows-desktop
```

### Docker Desktop

**Für Testcontainers** (Integration-Tests mit PostgreSQL)

Download: https://www.docker.com/products/docker-desktop/

Nach Installation:

```powershell
docker --version
docker ps  # Sollte leer sein, aber funktionieren
```

> **Ohne Docker:** Integration-Tests werden geskipped (Testcontainers erkennt fehlendes Docker automatisch).

### Node.js

**Version:** 20+ (für Playwright E2E-Tests)

Download: https://nodejs.org/

```powershell
node --version  # Sollte v20.x oder höher zeigen
npm --version
```

---

## 3. First-Run: Dependencies installieren

### Backend (.NET)

```powershell
Set-Location C:\Privat\Sheetstorm  # Oder dein Worktree-Pfad
dotnet restore Sheetstorm.sln
dotnet build Sheetstorm.sln
```

**Erwartete Ausgabe:**

```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

### Flutter

```powershell
Set-Location sheetstorm_app
flutter pub get
```

**Localization generieren:**

```powershell
flutter gen-l10n
```

(Wird auch automatisch beim ersten `flutter run` gemacht, da `pubspec.yaml` `generate: true` hat)

**Plattform-Code generieren (einmalig):**

```powershell
flutter create --platforms=android,ios,windows,web --org de.sheetstorm .
```

> **Warum?** Plattform-spezifische Ordner (`android/`, `ios/`, `windows/`, `web/`) sind nicht im Git (zu groß, generierbar). Müssen lokal erstellt werden.

### Playwright

```powershell
Set-Location sheetstorm_app
npm install
npx playwright install  # Browser-Binaries
```

---

## 4. First-Run: Backend starten (Aspire)

### Mit Aspire Workload

```powershell
Set-Location src\Sheetstorm.AppHost
dotnet run
```

**Output:**

```
Aspire Dashboard: https://localhost:17001
```

Dashboard öffnen → Zeigt laufende Ressourcen (API, Postgres-Container).

**API testen:**

```powershell
curl https://localhost:7001/api/v1/ping
```

Erwartete Antwort:

```json
{"message":"Hallo Blaskapelle"}
```

### Ohne Aspire Workload (Direkt API starten)

```powershell
Set-Location src\Sheetstorm.Api
dotnet run
```

**Hinweis:** Postgres-Container muss manuell gestartet werden:

```powershell
docker run -d -p 5432:5432 `
  -e POSTGRES_USER=sheetstorm `
  -e POSTGRES_PASSWORD=dev123 `
  -e POSTGRES_DB=sheetstorm `
  --name sheetstorm-postgres `
  postgres:16
```

**Connection-String in `appsettings.Development.json` setzen:**

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=sheetstorm;Username=sheetstorm;Password=dev123"
  }
}
```

---

## 5. First-Run: Flutter starten

**Web-Target:**

```powershell
Set-Location sheetstorm_app
flutter run -d chrome --web-port 8080 `
  --dart-define=API_BASE_URL=https://localhost:7001
```

**Erwartete Ausgabe:**

- Browser öffnet `http://localhost:8080`
- Home-Screen zeigt "Sheetstorm" + Backend-Ping-Response

**Andere Plattformen:**

```powershell
flutter run -d windows  # Windows Desktop
flutter run -d edge     # Edge Browser
flutter devices         # Alle verfügbaren Targets
```

---

## 6. Tests ausführen

### Backend-Tests (xUnit)

```powershell
dotnet test Sheetstorm.sln
```

**Erwartete Ausgabe:**

```
Passed! - Failed: 0, Passed: X, Skipped: Y
```

> **Skipped Tests:** Integration-Tests ohne Docker werden automatisch geskipped (via `[Fact(Skip = "...")]` in Testcontainers-Setup).

### Flutter-Tests

```powershell
Set-Location sheetstorm_app
flutter test
```

**Erwartete Ausgabe:**

```
00:02 +X: All tests passed!
```

**Einzelne Tests:**

```powershell
flutter test test/features/home/home_screen_test.dart
```

### E2E-Tests (Playwright)

**Voraussetzung:** Backend + Flutter Web müssen laufen.

**Terminal 1 (Backend):**

```powershell
Set-Location src\Sheetstorm.AppHost
dotnet run
```

**Terminal 2 (Flutter Web):**

```powershell
Set-Location sheetstorm_app
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=https://localhost:7001
```

**Terminal 3 (Playwright):**

```powershell
Set-Location sheetstorm_app
npm run test:e2e
```

**Interaktiver Modus (mit UI):**

```powershell
npm run test:e2e:ui
```

**Mit Browser-Fenster:**

```powershell
npm run test:e2e:headed
```

---

## 7. Commit-Workflow

### Conventional Commits

Format:

```
<type>: <kurze Beschreibung> (#<issue-nummer>)

<optionaler Body>

Co-authored-by: <Name> <email>
```

**Typen:**

- `feat`: Neues Feature
- `fix`: Bugfix
- `refactor`: Code-Umstrukturierung ohne Verhaltensänderung
- `test`: Neue Tests oder Test-Korrekturen
- `docs`: Dokumentationsänderungen
- `chore`: Build, Dependencies, Konfiguration

**Beispiel:**

```powershell
git add src/Sheetstorm.Api/Controllers/BandController.cs
git commit -m "feat: add Band CRUD endpoints (#127)

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"
```

### Issue-Ref

Jeder Commit MUSS eine Issue-Nummer enthalten (`#<number>`). Ausnahmen:

- Merge-Commits
- Chore-Commits ohne Issue-Kontext (z.B. `chore: update .gitignore`)

### Co-authored-by Trailer

Wenn AI-Assistenz genutzt wurde:

```
Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

---

## 8. Worktree-Workflow für parallele Feature-Arbeit

### Szenario: Zwei Features parallel entwickeln

**Feature 1: Band CRUD**

```powershell
git worktree add -b feat/band-crud C:\Privat\Sheetstorm-worktrees\feat-band-crud origin/main
Set-Location C:\Privat\Sheetstorm-worktrees\feat-band-crud
# ... entwickeln, testen, committen
git push -u origin feat/band-crud
```

**Feature 2: Noten Import**

```powershell
git worktree add -b feat/noten-import C:\Privat\Sheetstorm-worktrees\feat-noten-import origin/main
Set-Location C:\Privat\Sheetstorm-worktrees\feat-noten-import
# ... entwickeln, testen, committen
git push -u origin feat/noten-import
```

**Worktree auflisten:**

```powershell
git worktree list
```

**Worktree entfernen:**

```powershell
git worktree remove C:\Privat\Sheetstorm-worktrees\feat-band-crud
```

---

## 9. Troubleshooting

### Kein Docker → Testcontainers skip

**Symptom:** Integration-Tests werden geskipped.

**Lösung:** Docker Desktop installieren. Oder: Tests akzeptieren die Skips (keine Action erforderlich).

### Kein Flutter → Build only

**Symptom:** Flutter-Befehle schlagen fehl.

**Lösung 1:** Flutter SDK installieren (siehe oben).

**Lösung 2 (nur Backend entwickeln):**

```powershell
dotnet build Sheetstorm.sln  # Funktioniert ohne Flutter
```

Flutter-CI-Workflow testet Flutter automatisch.

### CanvasKit vs. HTML Renderer

**Symptom:** Flutter Web zeigt leere Seite oder langsame Performance.

**Lösung:** Renderer wechseln:

```powershell
# HTML-Renderer (schneller, aber weniger Features)
flutter run -d chrome --web-renderer html

# CanvasKit-Renderer (default, besser für komplexe UI)
flutter run -d chrome --web-renderer canvaskit
```

**Für E2E-Tests:** Playwright kann CanvasKit-Text nicht lesen. Test-Code nutzt `getByRole`, Screenshots und Keyboard-Navigation als Workaround.

### EF Core Migrations fehlen

**Symptom:** Backend startet, aber DB-Queries schlagen fehl.

**Status:** Aktuell keine Migrations (noch keine Entities außer Base-Classes). Wird in Feature-Entwicklung hinzugefügt.

**Wenn Migrations vorhanden:**

```powershell
Set-Location src\Sheetstorm.Infrastructure
dotnet ef database update --startup-project ../Sheetstorm.Api
```

### Aspire Dashboard startet nicht

**Symptom:** `dotnet run` in `AppHost` zeigt Fehler.

**Lösung 1:** Aspire Workload installieren:

```powershell
dotnet workload install aspire
```

**Lösung 2:** API direkt starten (siehe Abschnitt 4).

### Port bereits belegt

**Symptom:** `Address already in use: localhost:7001`

**Lösung:**

```powershell
# Windows: Port-Prozess finden
netstat -ano | findstr :7001
# PID notieren, dann:
Stop-Process -Id <PID>
```

### Playwright: `Target page, context or browser has been closed`

**Symptom:** E2E-Tests schlagen fehl mit "context closed".

**Lösung:** Flutter-Web muss laufen BEVOR Playwright startet. Reihenfolge:

1. Backend starten
2. Flutter Web starten
3. Warten bis Browser-Fenster erscheint
4. Dann erst Playwright

**Automatische Lösung (in Arbeit):** Startup-Script, das alle Services in richtiger Reihenfolge startet.

---

## Nächste Schritte

Nachdem DevLoop läuft:

1. **Code-Exploration:** Siehe `docs/specs/app-foundation-plan.md` (File-Structure-Map)
2. **Architektur-Entscheidungen:** `.squad/decisions.md`
3. **Feature entwickeln:** Issue-Board auf GitHub (`Issues` Tab)
4. **Squad-Framework:** `.squad/README.md` — AI-Team-Nutzung

---

**Fragen?** Issue erstellen oder in `#dev` fragen.
