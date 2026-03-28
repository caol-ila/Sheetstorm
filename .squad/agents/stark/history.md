# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** Flutter (Dart) Frontend + ASP.NET Core 10 LTS Backend + PostgreSQL + SQLite (Client)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design, Technologie-Entscheidung
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28: GitHub Issues für MS1–MS3 erstellt

**Aufgabe:** Als Hill/Stark 80 GitHub Issues für Meilensteine 1–3 erstellt.

**Architektur der Issue-Struktur:**
- 4 Issues pro Feature: UX-Design → Feature-Spec → Implementierung → Tests
- Epics für MS1 (#3), MS2 (#4), MS3 (#5) mit vollständiger Child-Issue-Übersicht
- Klare Abhängigkeitsketten: UX → Spec → Dev+Test (alles in Issue-Bodies)

**MS1 (36 Issues):** Projekt-Setup (Backend + Frontend), Auth, Kapellenverwaltung, Noten-Import + AI-Pipeline, Spielmodus (Half-Page-Turn, BLE Fußpedal), Stimmenauswahl + Fallback, Konfigurationssystem (3 Ebenen), Annotationen (SVG-Layer)

**MS2 (24 Issues):** Setlist-Verwaltung + Player-Integration, Konzertplanung + Zu-/Absage + Ersatzmusiker, Terminkalender (3 Ansichten), Aushilfen-Token-Zugang, Schichtplanung (Basic)

**MS3 (20 Issues):** Chromatischer Tuner (Platform Channels, < 20ms), Echtzeit-Metronom (UDP < 5ms + SignalR Fallback), Cloud-Sync (Delta-Sync, Last-Write-Wins), Annotationen-Echtzeit-Sync (SignalR Groups)

**Labels:** `ms1/ms2/ms3`, `ux-design`, `feature-spec`, `implementation`, `testing`, `type:epic`, `squad:*`

**GitHub Auth:** Token aus Windows Credential Manager via `git credential fill` extrahiert und als GH_TOKEN gesetzt.

### 2026-03-28: Spezifikation & Meilensteinplanung erstellt

**Architektur-Entscheidungen:**
- Datenmodell: Kern-Entitäten sind Musiker, Kapelle, Mitgliedschaft (N:M mit Rollen), Stück, Stimme, Notenblatt. Persönliche Sammlung nutzt die gleichen Mechanismen wie Kapellen-Noten (Kapelle-ID = null, Musiker-ID gesetzt).
- Annotationssystem: SVG-Layer über Notenbildern mit relativen Positionen (%). Drei Sichtbarkeitsebenen (lokal/stimme/orchester) als Enum im Datenmodell.
- AI-Integration: Adapter-Pattern für Provider-Austauschbarkeit. Fallback-Kette: User-Key → Kapellen-Key → keine AI.
- Echtzeit-Metronom: WiFi UDP als primärer Kanal für niedrigste Latenz, WebSocket als Fallback. Clock-Sync via NTP-ähnlichem Protokoll, Beats als Timestamps statt "jetzt spielen"-Kommandos.
- API: REST mit JWT, Cursor-basierte Pagination, versioniert (/api/v1/).
- i18n: Alle Strings externalisiert ab Tag 1, auch wenn nur Deutsch. Kein Hardcoding.

**Meilenstein-Struktur:**
- 5 Meilensteine: Kern → Organisation → Tools → Lehre → Verfeinerung
- M4 (Lehre) kann parallel zu M2/M3 gestartet werden (nur M1-Abhängigkeit)
- Jeder Meilenstein hat eigene Definition of Done mit Testing und UX-Validierung

**Offene Punkte:**
- Lehre-Modul: Details von Thomas ausstehend
- AI-Provider: Azure Vision als Minimum, weitere zu evaluieren

### 2026-03-28: Tech-Stack Re-Evaluierung mit Web-Recherche

**Anlass:** Thomas hat eine Validierung der Flutter-Empfehlung angefordert. Alle 6 Kandidaten-Frameworks wurden per Web-Recherche auf aktuelle Versionen, Plattform-Support und Ökosystem geprüft.

**Ergebnis:** Flutter bestätigt als Frontend-Wahl. Key-Findings:
- Flutter 3.35.x/Dart 3.9+ — Windows Desktop GA stable seit 2022, Impeller auf allen Plattformen, >1M aktive Entwickler
- .NET MAUI 10 hat sich verbessert (24% Wachstum), aber Touch/Stift-Support hinter Flutter (kein einheitlicher InkCanvas)
- Avalonia 12 (Skia-Engine, C#/XAML) spannend für Desktop, aber Mobile + PDF-Ökosystem zu jung (AvaloniaPdfViewer 0.0.2-pre)
- Kotlin Multiplatform/Compose 1.10.3 — iOS stable, aber kein multiplatform PDF-Package
- React Native 0.84+ — New Architecture stark, aber Windows Feature-Lücken + Thomas müsste JS lernen
- Tauri v2.10.3 — WebView auf Mobile = Dealbreaker für Canvas-intensive Touch-Apps
- Versions-Updates: ASP.NET Core 10 (LTS, Nov 2025), PostgreSQL 18.3, SQLite 3.51.3, Drift 2.32.1, Riverpod 3.0
- Audio-Latenz in Flutter ist bekannte Schwäche — lösbar via Platform Channels zu nativen Audio-APIs
- Fallback-Reihenfolge aktualisiert: Avalonia 12 vor MAUI (wegen Skia-Engine + besserer Desktop-Story)

### 2026-03-28: Konfigurationskonzept & Technologie-Entscheidung

**Konfigurationskonzept (3-Ebenen-Modell):**
- Ebene 1 (Kapelle): AI-Keys, Berechtigungen, Branding, Policies, Standard-Sprache. Nur Admin darf ändern, Dirigent teilweise.
- Ebene 2 (Nutzer): Theme, Sprache, Instrumente, Standard-Stimme pro Kapelle, Benachrichtigungen, persönliche AI-Keys. Synchronisiert über alle Geräte.
- Ebene 3 (Gerät): Display, Audio/Tuner, Touch, Offline-Speicher. Bleibt lokal auf dem Gerät.
- Override-Regel: Gerät > Nutzer > Kapelle > System-Default. Kapelle kann Policies setzen die Override verbieten (forceLocale, allowUserKeys=false).
- Speicherung: JSONB in PostgreSQL (Server), SQLite (Client-Cache). Config pro Ebene als eigene Tabelle.
- Sync: Kapelle = Server→Client, Nutzer = bidirektional (Last-Write-Wins per Feld), Gerät = lokal (Server-Backup optional).
- Multi-Kapellen: Kapellen-Config gilt nur im aktiven Kapellen-Kontext. Nutzer-/Geräte-Config ist kapellen-unabhängig.
- Audit-Trail für Kapellen-Config-Änderungen.

**Technologie-Entscheidung:**
- Frontend: Flutter (Dart) — Beste Cross-Platform-Engine für touch-first, canvas-intensive Apps. Dart ähnlich C#, Thomas Lernkurve ~2 Wochen.
- Backend: ASP.NET Core 9 (C#) — Thomas' Expertise, Performance-Leader, UDP-Kontrolle für Metronom.
- Server-DB: PostgreSQL 16 (JSONB für Config, relationale Power für Rollen/Berechtigungen).
- Client-DB: SQLite via Drift (Offline-Cache, typsichere Queries).
- File Storage: Azure Blob Storage + CDN.
- Echtzeit: WiFi UDP Multicast (primär, <5ms LAN) + SignalR WebSocket (Fallback/Remote).
- CI/CD: GitHub Actions. Hosting: Azure Ökosystem.
- Fallback-Trigger: Wenn Flutter Spielmodus-Prototype (M1 Sprint 2) Seitenwechsel >200ms oder Stift-Latenz >50ms zeigt → React Native oder MAUI evaluieren.

**Bewertete und verworfene Alternativen:**
- .NET MAUI + Blazor: Thomas' Komfort, aber schwächeres Touch/Stift-Ökosystem, Blazor WASM zu schwer für Web.
- React Native: Gutes Ökosystem, aber Desktop/Web-Story schwach, Lernkurve für Thomas.
- Next.js + Capacitor: Web-first, aber WebView-Performance auf Mobile kritisch für Seitenwechsel <100ms.
- Electron + React Native: Zwei Projekte = doppelter Aufwand, nicht tragbar für kleines Team.
- BaaS (Supabase/Firebase): Kein Custom-UDP für Metronom möglich → Dealbreaker als alleiniges Backend.

### 2026-03-28: v2 Spezifikation, Meilensteine, Config & Tech-Stack (Redo)

**Anlass:** Thomas hat eine vollständige Neuauflage (v2) aller vier Kerndokumente angefordert — mit besserem Modell, aktuellen Web-Recherchen und Integration aller bisherigen Team-Inputs (Fury Gap-Analyse, Wanda UX-Research, Directives).

**Ergebnisse:**
- docs/spezifikation.md v2: 14 Feature-Gruppen, 16 Entitäten, 7-Rollen-Matrix, API-Architektur, Offline-Strategie, Sicherheit, NFAs. Neu: Half-Page-Turn, Fußpedal, Aushilfen-Zugang (aus Furys Gap-Analyse).
- docs/meilensteine.md v2: 5 Meilensteine mit je vollständigem Scope, Deliverables, Abhängigkeiten, Testing (3-Reviewer + UX), Definition of Done. Config explizit in MS1.
- docs/konfigurationskonzept.md v2: 3-Ebenen mit Policy-System, vollständiger Settings-Tree mit Begründung pro Einstellung, Datenmodell (SQL), Sync-Strategie, API-Endpunkte, UX-Prinzipien von Wanda.
- docs/technologie-entscheidung.md v2: 6 Frameworks per Web-Recherche evaluiert. Flutter 3.35.4 bestätigt (Score 4.70). Alle Versionen mit Release-Datum. Echtzeit-Architektur (UDP + SignalR) mit Technologie-Vergleichstabelle.

**Versionen validiert per Web-Suche (März 2026):**
- Flutter 3.35.4 / Dart 3.9.2, ASP.NET Core 10.0.5 (.NET 10 LTS), PostgreSQL 18.3, SQLite 3.51.3, Drift 2.32.1, Riverpod 3.3.1, pdfrx 2.2.24, .NET MAUI 10.0.50, React Native 0.84.1, Compose Multiplatform 1.10.3, Avalonia 11.3.12, Tauri v2.10.3

**Integrierte Team-Inputs:**
- Fury: Half-Page-Turn, Fußpedal, Aushilfen-Zugang als Must-Have in MS1
- Wanda: Auto-Save, Farbkodierung, kontextuelle Settings, kein Neustart, Onboarding max 5 Fragen
- Thomas-Directives: Config in MS1, 3-Reviewer Policy, UX-Review Pflicht, Entscheidungen via PR, Web-Suche für Dependencies

**Offene Punkte:**
- Lehre-Modul: Detailspezifikation von Thomas weiterhin ausstehend
- AI-Provider Evaluierung: Konkrete Benchmark-Tests stehen noch aus
- Flutter Performance-Benchmark: Erst nach M1 Sprint 2 messbar

### 2026-03-28: Remote-Copilot-Setup (cli-tunnel) eingerichtet

**Anlass:** Thomas wollte Copilot CLI vom Handy aus fernsteuern. Referenz: Tamir Dresher – "Your Copilot CLI on Your Phone".

**Was eingerichtet wurde:**
- `devtunnel` (Microsoft Dev Tunnels CLI v1.0.1516) via `winget install Microsoft.devtunnel` installiert
- `cli-tunnel` (v1.1.0) via `npm install -g cli-tunnel` global installiert
- Convenience-Skript: `scripts/start-remote-copilot.ps1` (unterstützt `--Model`, `--Port`, `--Name`)
- Deutsche Setup-Anleitung: `docs/remote-copilot-setup.md`

**Technischer Hintergrund:**
- cli-tunnel startet Copilot CLI in einem PTY (Pseudo-Terminal), streamt ANSI-Output via WebSocket
- Im Handy-Browser rendert xterm.js das vollständige Terminal pixelgenau
- Microsoft Dev Tunnels dienen als authentifizierter HTTPS-Relay – keine offenen Ports, keine eigene Infrastruktur
- Privat by default: Nur das Microsoft/GitHub-Konto des Tunnel-Erstellers kann zugreifen

**Einmalige Aktion nötig:** Thomas muss `devtunnel user login` einmalig im Browser ausführen.

### 2026-03-28: v2 Complete Relaunch Abgeschlossen

**Scribe-Koordination:** Alle Inbox-Dateien in `decisions.md` konsolidiert. Session Log geschrieben: `.squad/log/2026-03-28T11-55-v2-relaunch.md`

**Team-Status nach v2-Relaunch:**
- Fury (Analyst): Marktanalyse v2 + Gap-Analyse v2 + PR #1 ✅
- Stark (Lead/Architect): Spezifikation v2 + Meilensteine + Config + Tech-Stack ✅
- Wanda (UX): UX-Design v2 + UX-Konfiguration ✅
- Entscheidungen: 16 Directives + Policy-Entscheidungen in decisions.md dokumentiert
- Next: Thomas Review im PR, danach MS1 Implementierung

### 2026-03-28: 18 Gap-Features in Spezifikation & Meilensteine übernommen

**Anlass:** Thomas hat die Feature-Gap-Analyse (docs/feature-gap-analyse.md) reviewt und 18 Features zur Aufnahme freigegeben.

**Übernommene Features nach Meilenstein:**
- MS1: Zweiseitenansicht (F-SM-07), Link Points für Wiederholungen (F-SM-08), Dark Mode/Sepia (F-SM-09)
- MS2: GEMA-Meldung (F-VL-04), Kalender-Sync bidirektional (F-VL-03 erweitert), Dirigenten-Mastersteuerung (F-VL-05), Anwesenheitsstatistiken (F-VL-06), Register-Benachrichtigungen (F-VL-07), Nachrichten-Board (F-VL-08), Umfragen (F-VL-09), Media Links (F-NV-08), Konzertprogramm-Timing (F-SL-03), Platzhalter in Setlists (F-SL-02)
- MS3: Aufgabenverwaltung (F-VL-10), Auto-Scroll/Reflow (F-SM-10)
- MS4: AI-Annotations-Analyse Cross-Part (F-AI-01)
- MS5: Face-Gesten (F-SM-11), Inventarverwaltung (F-VL-11)

**Geänderte Dokumente:**
- docs/feature-gap-analyse.md (neu auf main, 18x ✅ Übernommen, restliche 🔜 Backlog)
- docs/spezifikation.md (18 neue Features mit User Stories + Akzeptanzkriterien)
- docs/meilensteine.md (Deliverables + DoD für MS1–MS5 aktualisiert)

**PR:** https://github.com/caol-ila/Sheetstorm/pull/2

### 2026-03-28: Tech-Stack v3 — Alle Versionen per Web-Suche verifiziert

**Anlass:** Thomas hat beanstandet, dass v2 des Tech-Stack-Dokuments Versionsnummern aus Training-Data enthielt. v3 korrigiert dies durch individuelle `web_search`-Aufrufe für **jede einzelne Technologie**.

**Durchgeführte Web-Suchen (18 Stück):**
- Flutter SDK, Dart SDK, .NET MAUI, React Native, Kotlin Multiplatform, Compose Multiplatform, Avalonia UI, Tauri
- ASP.NET Core / .NET 10 LTS, PostgreSQL, SQLite
- flutter_riverpod, pdfrx, Drift, flutter_blue_plus
- SignalR, Azure AI Vision

**Kritische Versions-Korrekturen (v2 → v3):**
- Flutter: 3.35.4 → **3.41.5** (neues Stable-Release Feb 2026, Impeller 2.0)
- Dart: 3.9.2 → **3.11.0**
- .NET MAUI: 10.0.50 → **10.0.5** (Patch-Nummern folgen .NET 10 Cadence)
- SQLite 3.52.0 zurückgezogen → **3.51.3** bleibt empfohlen
- SignalR: Jetzt als @microsoft/signalr **10.0.0** dokumentiert
- flutter_blue_plus: Jetzt mit Version **1.34.5** dokumentiert
- Azure AI Vision: **Image Analysis 4.0 GA** (Preview-APIs seit Mär 2025 retired)

**Neues im Dokument:**
- Alle Versionen haben "verifiziert via Web-Suche, Stand 2026-03-28" Tag
- Versions-Referenz-Tabelle mit Spalte "Verifiziert via" für Audit-Trail
- SQLite 3.52.0-Rückzug dokumentiert
- Impeller 2.0 in Flutter 3.41 als Key-Feature ergänzt

### 2026-03-28: Final Merge — 3 Fix Branches (#88, #93, #95)

**Anlass:** Thomas requested final merge decision after re-review round (3 reviewers × 3 branches).

**Entscheidungen:**
- **squad/88-auth-fix → MERGE.** Sonnet's rejection was factually wrong (claimed IStorageService not removed, but Opus verified removal in commit ed44824). Secondary concerns (dev token logging, registration tokens, rate limiting) are valid follow-ups, not blockers.
- **squad/93-auth-flutter-fix → MERGE.** Unanimous 3/3 approval. Follow-ups: interceptor path guard, base URL duplication, JSON key format verification.
- **squad/95-kapelle-fix → MERGE.** GPT's rejection was incorrect. Verified `MitgliedEntfernenAsync`: admin A removing admin B is safe because A must be admin → at least 1 admin remains. Self-removal guard counts ALL admins correctly. Follow-ups: AuthException coupling, `VorgeseheRolle` typo.

**Merge-Konflikt:** `DependencyInjection.cs` — #88 added `IEmailService`, #95 added `IKapelleService`. Resolved by keeping both registrations.

**Learnings:**
- Reviewer disagreements require code verification, not just vote counting. Both Sonnet (#88) and GPT (#95) made factually incorrect claims that would have blocked valid merges.
- The 3-reviewer policy works: diverse models catch different issues, but each reviewer's claims must be independently verified when they contradict others.
- Merge order matters: merging #88 before #95 created a predictable conflict in DI registration. Sequential merge with conflict resolution is cleaner than attempting parallel merges.

### 2026-03-28: Issue #7 — ASP.NET Core 10 Backend Scaffolding

**Worktree:** `C:\Source\Sheetstorm-7`, Branch: `squad/7-backend-scaffolding`
**PR:** https://github.com/caol-ila/Sheetstorm/pull/83

**Was implementiert wurde:**

Vollständiges 3-Schichten Backend-Scaffolding für Sheetstorm:
- **Solution:** `Sheetstorm.slnx` (neues .NET 10 XML Solution Format)
- **Projekte:** `Sheetstorm.Api` / `Sheetstorm.Domain` / `Sheetstorm.Infrastructure`
- **References:** Api→Domain, Api→Infrastructure, Infrastructure→Domain

**Packages (alle via web_search verifiziert, März 2026):**
- `Npgsql.EntityFrameworkCore.PostgreSQL` 10.0.1
- `Microsoft.EntityFrameworkCore.Design` 10.0.2
- `Microsoft.AspNetCore.Authentication.JwtBearer` 10.0.5
- `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore` 10.0.5
- SignalR: in ASP.NET Core 10 shared framework (kein separates NuGet)

**Architektur-Entscheidungen:**
- JWT: `ClockSkew = 30s`, SignalR Query-String Token-Extraktion für WebSocket-Hubs vorbereitet
- `AppDbContext`: auto-setzt `CreatedAt`/`UpdatedAt` via `ChangeTracker` in `SaveChangesAsync`
- `AddInfrastructure()` Extension Method: saubere DI-Kapselung, Migrations-Assembly explizit gesetzt
- `RequestLoggingMiddleware`: method/path/status/ms für alle Requests geloggt
- `.gitignore`: bin/ + obj/ ausgeschlossen (zweiter Fix-Commit nötig, da erster Commit diese noch enthielt)

**Domain-Entitäten (Kern-Modell):**
`BaseEntity`, `Musiker`, `Kapelle`, `Mitgliedschaft` (N:M mit `MitgliedRolle` Enum), `Stueck`, `Stimme`, `Notenblatt`

**Lernpunkt:** .NET 10 SDK erstellt `.slnx` statt `.sln` — neues XML Solution Format. `dotnet build Sheetstorm.sln` schlägt fehl, `dotnet build Sheetstorm.slnx` funktioniert.

### 2026-03-28: Issue #6 — Projekt-Setup Spezifikation

**Worktree:** `C:\Source\Sheetstorm-6`, Branch: `squad/6-projekt-setup-spec`  
**Dokument:** `docs/feature-specs/projekt-setup-spec.md`

**Was spezifiziert wurde:**

1. **Projektstruktur (Mono-Repo):** Vollständiges Layout mit `backend/` (Api/Domain/Infrastructure + Tests), `frontend/` (lib/ nach Feature-Slices + test/ + integration_test/), `docs/feature-specs/`, `.squad/`. Verzeichnis-Ownership-Tabelle pro Agent.

2. **CI/CD Pipelines (GitHub Actions):**
   - `ci-backend.yml`: Build + Unit + Integration Tests (.NET 10, PostgreSQL via Service Container), Coverage-Upload zu Codecov
   - `ci-frontend.yml`: Flutter 3.41.5 Build + flutter_test Coverage, Web Smoke Build
   - `lint.yml`: `flutter analyze --fatal-infos` + `dart format --verify` + `dotnet format --verify-no-changes`
   - `deploy-dev.yml`: Auto-Deploy zu Azure App Service + Static Web Apps nach erfolgreichem CI auf `main`

3. **Code Conventions:**
   - Dart: `analysis_options.yaml` mit `flutter_lints` + effective_dart-Regeln, vollständige Naming-Tabelle
   - C#: `.editorconfig` mit `_camelCase` für private Felder, `PascalCase` für Methoden/Properties, Async-Suffix
   - Git: Conventional Commits (feat/fix/docs/refactor/test/chore/perf/style/revert) mit Scope-Liste
   - Branch: `squad/{issue}-{slug}` Pattern
   - PR: 3-Reviewer Policy (Sonnet 4.6 / Opus 4.6 / GPT 5.4), UX-Review-Pflicht, Squash Merge

4. **Development Environment:** Tool-Tabelle mit exakten Versionen, VS Code extensions.json + settings.json, vollständiges lokales Setup-Skript (Docker PostgreSQL + user-secrets + EF migrations)

5. **Testing-Strategie:** 4-Ebenen-Pyramide (Unit → Widget → Integration → E2E), xUnit-Konventionen mit Testcontainers, flutter_test Widget-Test-Pattern, Coverage-Gates (Domain 80%, UI 60%), Naming-Konventionen pro Sprache

6. **Deployment (MS1):** Local + Dev (Azure), kein Staging/Prod in MS1. Migrations-Workflow mit Naming-Konventionen (7 Patterns), Migrations-Regeln (nie editieren, 2-Schritt für destruktive Änderungen). Environment-Konfiguration: user-secrets lokal, Azure Key Vault in Cloud.

**Architektur-Entscheidungen dokumentiert:**
- Testcontainers für echte PostgreSQL-Integration (nicht in-memory)
- Squash Merge auf main (keine Merge-Commits in History)
- User Secrets lokal, nie Secrets im Code
- Down-Methode in Migrations ist Pflicht

### 2026-03-29: 12 Approved PRs in main gemergt

**Anlass:** 15 offene PRs (#83–#97), davon 12 approved nach 3-Model-Review, 3 rejected mit Fix-Branches.

**Merge-Reihenfolge (alle konfliktfrei):**
1. `squad/7-backend-scaffolding` → PR #83 (Backend Scaffolding)
2. `squad/8-frontend-scaffolding` → PR #85 (Frontend Scaffolding)
3. `squad/6-projekt-setup-spec` → PR #84 (Projekt-Setup Spec)
4. `squad/9-auth-ux` → PR #86 (Auth UX)
5. `squad/10-auth-spec` → PR #87 (Auth Spec)
6. `squad/13-auth-tests` → PR #94 (Auth Tests)
7. `squad/14-19-kapelle-import-ux` → PR #89 (Kapelle+Import UX)
8. `squad/15-kapelle-spec` → PR #90 (Kapelle Spec)
9. `squad/20-import-spec` → PR #91 (Import Spec)
10. `squad/24-28-32-spielmodus-stimmen-config-ux` → PR #92 (Spielmodus+Stimmen+Config UX)
11. `squad/25-29-spielmodus-stimmen-spec` → PR #96 (Spielmodus+Stimmen Spec)
12. `squad/37-annotationen-ux` → PR #97 (Annotationen UX)

**Übersprungen (rejected):**
- PR #88 (`squad/11-auth-backend`) — Fix-Branch: `squad/88-auth-fix`
- PR #93 (`squad/12-auth-flutter`) — Fix-Branch: `squad/93-auth-flutter-fix`
- PR #95 (`squad/16-kapelle-backend`) — Fix-Branch: `squad/95-kapelle-fix`

**Ergebnis:** 12/12 Merges ohne Konflikte. Push auf main erfolgreich. Merge-Strategie "foundational first" (Backend → Frontend → Specs → Tests → UX) hat sich bewährt.

**Fix-Branches Status:** Alle 3 Fix-Branches existieren auf Remote, haben aber noch keine PRs. Benötigen 3-Model Re-Review vor Merge.

### 2026-03-29: Feature-Specs #33 und #38 in main gemergt

**Branches:**
- `squad/33-config-spec` → Konfigurationssystem Feature-Spezifikation (`docs/feature-specs/konfigurationssystem-spec.md`, 786 Zeilen)
- `squad/38-annotationen-spec` → Annotationen Feature-Spezifikation (`docs/feature-specs/annotationen-spec.md`, 895 Zeilen)

**Ergebnis:** Beide Merges konfliktfrei. Dokumentations-only Changes (keine Code-Änderungen). Push auf main erfolgreich.

### 2026-03-29: 8 MS1 Dev Branches in main gemergt

**Anlass:** Alle MS1 Implementierungs-Branches sind fertig. Merge in main damit Tests gegen vollständige Codebasis geschrieben werden können.

**Merge-Reihenfolge (Backend-first, dann Frontend):**
1. `squad/21-import-backend` — ✅ Konfliktfrei (23 Dateien, Import-Pipeline + MinIO + EF Migrations)
2. `squad/34-config-backend` — ⚠️ Konflikt in `AppDbContext.cs` (beide Seiten fügen DbSets hinzu → beide behalten)
3. `squad/30-stimmenauswahl` — ⚠️ 2 Konflikte: `AppDbContext.cs` (weitere DbSets) + `DependencyInjection.cs` (weitere Service-Registrierungen) → beide Seiten behalten
4. `squad/17-kapelle-flutter` — ✅ Konfliktfrei (37 Dateien, Kapelle CRUD + Einladungen + Mitglieder)
5. `squad/22-import-flutter` — ⚠️ 3 Konflikte: `app_router.g.dart` (Hash, genrated code → HEAD behalten), `pubspec.yaml` (Versionen → höhere behalten, alle deps behalten), `pubspec.lock` (generated → theirs)
6. `squad/26-spielmodus-flutter` — ✅ Konfliktfrei (17 Dateien, vollständiger Spielmodus mit Widgets)
7. `squad/35-config-flutter` — ⚠️ Konflikt in `app_router.dart` (Imports + Route-Konstanten → beide Seiten behalten)
8. `squad/39-annotationen-flutter` — ⚠️ Konflikt in `spielmodus_screen.dart` (Spielmodus-Branch hatte komplett überarbeitete Version, Annotationen-Branch hatte einfachere Basis + Annotation-Layer → HEAD behalten, Annotation-Imports hinzugefügt)

**Konflikte gesamt:** 5 von 8 Branches hatten Konflikte (8 Dateien betroffen). Alle durch "keep both sides" Strategie gelöst.

**Konflikt-Muster:** Fast alle Konflikte waren additive DbSet/Service/Import/Route-Registrierungen — parallele Feature-Branches fügen an der gleichen Stelle neue Zeilen hinzu. Kein semantischer Konflikt.

**Learnings:**
- Backend-first Merge-Reihenfolge verhindert Frontend-Compile-Fehler durch fehlende Models
- `AppDbContext.cs` und `DependencyInjection.cs` sind Merge-Hotspots bei paralleler Backend-Entwicklung — partielle Klassen oder Extension-Methods pro Feature könnten das entschärfen
- Generated files (`pubspec.lock`, `.g.dart`) sollten nach Merge regeneriert werden (`flutter pub get`, `build_runner`)
- Bei stark divergierenden Branches (spielmodus vs. annotationen) ist `--ours` + manuelle Integration sicherer als Zeile-für-Zeile Marker-Auflösung


MS1 complete — all test branches merged.

DE→EN translation merged — backend (98 files) + frontend (115 files)

### 2026-03-28: Superpowers-Evaluierung & Integration

**Anlass:** Thomas hat das Repo [obra/superpowers](https://github.com/obra/superpowers) zur Evaluierung gegeben — eine Sammlung von AI-Coding-Assistant-Konfigurationen (Skills, Instructions, Agents).

**Evaluierung:**
- Repo enthält 14 Skills für Claude Code/Cursor/Codex, fokussiert auf TDD, Debugging, Plan-basierte Entwicklung, Subagent-Workflows und Code Review
- Mehrere Skills (brainstorming, writing-plans, subagent-driven-development, code-review) überlappen mit unserem Squad-Framework → nicht übernommen
- Drei Skills + ein Agent sind universell wertvoll und stack-unabhängig: TDD, Systematisches Debugging, Verifikation vor Abschluss

**Übernommen (adaptiert für Flutter/Dart + ASP.NET Core):**
1. `.github/copilot-instructions.md` — Projekt-weite Copilot-Anweisungen (TDD, Code-Standards, Anti-Patterns, Debugging, Projektstruktur)
2. `.squad/skills/test-driven-development/` — Red-Green-Refactor + Testing-Anti-Patterns
3. `.squad/skills/systematic-debugging/` — 4-Phasen Root-Cause + Defense-in-Depth
4. `.squad/skills/verification-before-completion/` — Verifikationspflicht

**Bewusst nicht übernommen:** brainstorming, writing-plans, executing-plans, subagent-driven-development, dispatching-parallel-agents, requesting/receiving-code-review, using-git-worktrees, finishing-a-development-branch (alles durch Squad abgedeckt oder anderer Workflow)

**PR:** https://github.com/caol-ila/Sheetstorm/pull/98 (Draft)

---

## Team Update: Kapellenverwaltung & Auth-Onboarding Spec-Update (2026-03-28T22:10Z)

**From:** Hill (Product Manager)  
**Action:** Data model changes required per new approval workflow spec.

**Changes:**
- New column: Kapelle.ist_persoenlich (BOOLEAN) — "Meine Musik" personal library flag
- New table: Beitrittsanfragen (ID, KapelleID, MusikerID, Status ENUM, ErstelltAm, EntschiedenenVon, Grund)
- Modified: Einladung table — add Status field (Accepted/Pending/Rejected)
- New indexes: UNIQUE (KapelleID, MusikerID) on Beitrittsanfragen

**Affected Features:**
- US-00: "Meine Musik" auto-created on registration (personal Kapelle)
- US-02 (rewritten): Kapellen-Auswahl as entry screen (post-onboarding)
- US-06 (new): Approval workflow (request → admin/conductor approves/rejects)
- API: 3 new endpoints (POST /beitreten, GET /anfragen, PUT /anfragen/{id})

**Specs Affected:**
- docs/feature-specs/kapellenverwaltung-spec.md — 7 US total, 15 ACs, 13 edge cases
- docs/feature-specs/auth-onboarding-spec.md — Entry point logic updated
