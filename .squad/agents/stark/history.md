# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** Flutter (Dart) Frontend + ASP.NET Core 9 Backend + PostgreSQL + SQLite (Client)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design, Technologie-Entscheidung
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

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
```
