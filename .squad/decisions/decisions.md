# Decisions

## Decision 1: Tech-Stack v3 — Verifizierte Versionen

**Autor:** Stark (Lead / Architect)  
**Datum:** 2026-03-28  
**Typ:** Aktualisierung  
**Dokument:** `docs/technologie-entscheidung.md` v3

### Kontext

Thomas hat festgestellt, dass v2 des Tech-Stack-Dokuments veraltete Versionsnummern aus Training-Data enthielt. v3 korrigiert dies durch individuelle `web_search`-Abfragen für **jede einzelne Technologie**.

### Änderungen v2 → v3

| Technologie | v2 (alt) | v3 (verifiziert) | Quelle |
|-------------|----------|-------------------|--------|
| **Flutter** | 3.35.4 | **3.41.5** | flutter.dev, GitHub CHANGELOG |
| **Dart** | 3.9.2 | **3.11.0** | dart.dev/changelog |
| **Flutter Impeller** | (nicht spezifiziert) | **Impeller 2.0** | Flutter 3.41 release notes |
| **.NET MAUI** | 10.0.50 | **10.0.5** | endoflife.date, Microsoft Support |
| **SignalR** | "Teil von ASP.NET Core 10" | **@microsoft/signalr 10.0.0** | npmjs.com |
| **flutter_blue_plus** | (nicht versioniert) | **1.34.5** | pub.dev |
| **Azure AI Vision** | (nicht spezifiziert) | **Image Analysis 4.0 GA** | learn.microsoft.com |
| **SQLite** | 3.51.3 | 3.51.3 (bestätigt, 3.52.0 zurückgezogen) | sqlite.org |

Alle anderen Versionen (PostgreSQL 18.3, Drift 2.32.1, Riverpod 3.3.1, pdfrx 2.2.24, etc.) wurden per Web-Suche **bestätigt** — keine Änderung nötig.

### Methodik

- 18 separate `web_search`-Aufrufe durchgeführt
- Jede Version mit Quell-URL und Datum dokumentiert
- Neuer Abschnitt "Versions-Referenz" mit Spalte "Verifiziert via" für Audit-Trail
- Kein Rückgriff auf Training-Data für Versionsnummern

### Empfehlung

Kernentscheidung (Flutter + ASP.NET Core + PostgreSQL) bleibt unverändert und bestätigt. Nur Versionsnummern aktualisiert.

**Status:** Zur Prüfung durch Thomas.

---

## Decision 2: Feature-Gap-Entscheidung: 18 Features übernommen

**Von:** Stark (Lead / Architect)  
**Datum:** 2026-03-28  
**Typ:** Feature-Adoption-Entscheidung  
**Status:** Umgesetzt — PR #2 offen

### Entscheidung

Thomas hat aus der Feature-Gap-Analyse (39 Gaps, Fury) **18 Features** zur Aufnahme in die Spezifikation freigegeben. Die restlichen Features bleiben im Backlog.

### Übernommene Features

| # | Feature | Meilenstein | Spec-ID |
|---|---------|:-----------:|---------|
| 0 | GEMA-/Verwertungsgesellschaft-Meldung | MS2 | F-VL-04 |
| 6 | Kalender-Sync bidirektional | MS2 | F-VL-03 (erweitert) |
| 8 | Zweiseitenansicht (Two-Up-Modus) | MS1 | F-SM-07 |
| 9 | Link Points für Wiederholungen | MS1 | F-SM-08 |
| 10 | Dirigenten-Mastersteuerung (Song-Broadcast) | MS2 | F-VL-05 |
| 11 | Dark Mode / Nachtmodus / Sepia | MS1 | F-SM-09 |
| 12 | Anwesenheitsstatistiken | MS2 | F-VL-06 |
| 13 | Register-basierte Benachrichtigungen | MS2 | F-VL-07 |
| 14 | Nachrichten-Board / Pinnwand | MS2 | F-VL-08 |
| 15 | Umfragen / Abstimmungen | MS2 | F-VL-09 |
| 22 | Media Links (YouTube/Spotify) | MS2 | F-NV-08 |
| 27 | Konzertprogramm mit Timing | MS2 | F-SL-03 |
| 29 | Platzhalter in Setlists | MS2 | F-SL-02 |
| 30 | Aufgabenverwaltung / To-Do-Listen | MS3 | F-VL-10 |
| 31 | Auto-Scroll / Reflow | MS3 | F-SM-10 |
| 34 | AI-Annotations-Analyse (Cross-Part) | MS4 | F-AI-01 |
| 35 | Face-Gesten für Seitenwechsel | MS5 | F-SM-11 |
| 40 | Inventarverwaltung (Instrumente) | MS5 | F-VL-11 |

### Nicht übernommene Features (Backlog)

Features #4, #5, #7, #16–#21, #23–#26, #28, #32–#33, #36–#39, #41 wurden **nicht** übernommen und bleiben im Backlog für spätere Betrachtung. Sie sind in `docs/feature-gap-analyse.md` mit 🔜 Backlog markiert.

### Auswirkungen auf Meilensteine

- **MS1** wächst um 3 Features (Zweiseitenansicht, Link Points, Dark Mode)
- **MS2** wächst am stärksten (+9 Features: GEMA, Dirigenten-Broadcast, Kommunikationsfeatures)
- **MS3** +2 Features (Auto-Scroll, Aufgabenverwaltung)
- **MS4** +1 Feature (AI Cross-Part Analyse)
- **MS5** +2 Features (Face-Gesten, Inventar)

**GEMA-Meldung** ist rechtlich kritisch (gesetzliche Pflicht in DACH) — Must-Priorität in MS2.

### Nächste Schritte

1. Thomas reviewed PR #2 und mergt
2. Scribe konsolidiert diese Inbox-Datei in decisions.md
3. Bei MS1-Planung die 3 neuen Spielmodus-Features einplanen
4. Bei MS2-Planung GEMA-Feature priorisieren (rechtliche Pflicht)
