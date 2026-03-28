# Project Context

- **Owner:** Thomas
- **Project:** Sheetstorm — Notenmanagement-App für Blaskapellen
- **Stack:** Flutter 3.41.5 + ASP.NET Core 10 LTS + PostgreSQL + SQLite
- **Phase:** Anforderungsanalyse abgeschlossen, Feature-Specs für MS1 starten
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

### 2026-03-28: GitHub Issues für MS1–MS3 erstellt

**Aufgabe:** GitHub Issues für Meilensteine 1, 2 und 3 erstellt — vollständige Issue-Struktur pro Feature (UX-Design, Feature-Spec, Implementierung, Tests).

**Ergebnis:** 80 Issues total erstellt:
- MS1: 36 Issues (3 Epics + 35 Feature-Issues) — 8 Features: Projekt-Setup, Auth, Kapellenverwaltung, Noten-Import, Spielmodus, Stimmenauswahl, Konfigurationssystem, Annotationen
- MS2: 24 Issues (1 Epic + 23 Feature-Issues) — 5 Features: Setlist, Konzertplanung, Kalender, Aushilfen-Zugang, Schichtplanung
- MS3: 20 Issues (1 Epic + 19 Feature-Issues) — 4 Features: Tuner, Metronom, Cloud-Sync, Annotationen-Sync

**Labels erstellt/genutzt:**
- Milesteine: `ms1`, `ms2`, `ms3`
- Typen: `ux-design`, `feature-spec`, `implementation`, `testing`, `type:epic`
- Squad: `squad:wanda`, `squad:hill`, `squad:stark`, `squad:romanoff`, `squad:banner`, `squad:parker`

**Struktur pro Feature:**
1. [UX] Wanda erstellt Wireframes und Flows
2. [Spec] Hill schreibt Feature-Spec mit Akzeptanzkriterien (Depends on UX)
3. [Dev] Romanoff (Frontend) / Banner (Backend) implementiert (Depends on Spec)
4. [Test] Parker schreibt Tests (Depends on Spec + Dev)

**Dependencies klar in Issue-Bodies referenziert** (z.B. "Depends on: #X").
Epic-Issues (#3, #4, #5) verlinken alle Child-Issues.

### 2026-03-28: Feature-Spec Auth & Onboarding (#10) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für Authentifizierung & Onboarding auf Basis von Wandas UX-Spec (#9).

**Ergebnis:** `docs/feature-specs/auth-onboarding-spec.md` erstellt (Branch `squad/10-auth-spec`):

1. **Feature-Überblick** — Login, Registrierung, Passwort-Reset, Onboarding-Wizard, Token-Management, Aushilfen-Deep-Link; Ziel: unter 3 Minuten von Installation bis erste Note
2. **4 INVEST-konforme User Stories** — Registrierung, Login, Passwort zurücksetzen, Onboarding-Wizard
3. **7 testbare Akzeptanzkriterien** — JWT nach Login, Refresh Token Rotation, Passwort-Mindestanforderungen, Onboarding überspringbar, Post-Onboarding Nutzer-State, Social Login Plattformlogik, Aushilfen-Deep-Link
4. **API-Contract (7 Endpunkte)** — POST /api/auth/register, /login, /refresh, /forgot-password, /reset-password, /social/google, /social/apple
5. **Datenmodell** — User, RefreshToken, PasswordResetToken, UserInstrument (bcrypt, Refresh Tokens gehashed)
6. **Edge Cases** — Auth-State-Machine-Grenzfälle, Registrierungs-Konflikte, Reset-Token-Ablauf, Onboarding-Abbruch, Sicherheitsszenarien (Brute Force, JWT-Manipulation, Reuse-Detection)
7. **Abhängigkeiten** — #7 (Backend), #8 (Frontend) blockierend; #9 (UX) abgeschlossen
8. **Definition of Done** — Funktional, Qualität (≥80% Coverage), UX/Accessibility, Sicherheit, Docs, Deployment

**Wichtigste Entscheidungen in der Spec:**
- Apple-Login nur iOS/macOS — kein Fake-Button auf Android
- Registrierung als Transaktion — kein halbfertiger Account bei Abbruch
- User-Enumeration bei "Passwort vergessen" verhindert (immer 200 OK)
- Refresh Token Reuse Detection: bei Wiederverwendung alle Sessions invalidieren
- `onboardingCompleted = true` auch wenn alle Schritte übersprungen

### 2026-03-28: Feature-Spec Kapellenverwaltung (#15) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für Kapellenverwaltung auf Basis von Wandas UX-Design (docs/ux-design.md §3.5, §4.3 — vollständige UX-Spec #14 noch ausstehend).

**Ergebnis:** `docs/feature-specs/kapellenverwaltung-spec.md` erstellt (Branch `squad/15-kapelle-spec`):

1. **Feature-Überblick** — Scope MS1 klar abgegrenzt (8 In-Scope, 8 Out-of-Scope-Items); Alleinstellungsmerkmal Multi-Kapellen und Registerführer-Rolle dokumentiert
2. **5 INVEST-konforme User Stories:**
   - US-01: Kapelle erstellen (Name, Beschreibung, Ort, Logo optional)
   - US-02: Mitglieder einladen (E-Mail + Einladungslink, 7-Tage-Default, konfigurierbar)
   - US-03: Rollen zuweisen (5 Rollen: Admin/Dirigent/Notenwart/Registerführer/Musiker; mehrere Rollen pro Mitglied)
   - US-04: Multi-Kapelle — Kapellen-Wechsel (max. 20 Kapellen, State wird gespeichert)
   - US-05: Instrument-Register verwalten (Vorlagen, Drag & Drop, Registerführer-Zuweisung)
3. **10 testbare Akzeptanzkriterien** — von E2E-Timing bis Cross-Kapellen-Isolation
4. **API-Contract (5 Endpunkt-Gruppen):** CRUD Kapelle, Mitglieder, Rollen, Einladungen, Register — vollständige Request/Response-Beispiele
5. **Datenmodell (6 Tabellen):** kapellen, mitgliedschaften, mitgliedschaft_rollen (Enum-Typ), einladungen (256-bit Token), register, audit_log — inkl. Indexes und Constraints
6. **Berechtigungsmatrix:** 5 Rollen × alle Aktionen, Server-side Enforcement als Kernprinzip
7. **8 Edge Cases:** Letzter Admin verlässt Kapelle (verwaist-Status, 90-Tage-Frist), doppelte Einladung (zwei Szenarien), Token-Kollision, abgelaufene Einladung, Mitglied online entfernt, Register mit Mitgliedern löschen
8. **Definition of Done:** 25 Checkboxen über Funktional/Qualität/UX/Technisch/Deployment

**Wichtigste Entscheidungen in der Spec:**
- Kein Auto-Promote zum Admin — explizite Entscheidung, keine stillen System-Aktionen
- Verwaiste Kapelle (letzter Admin löscht Account): 90-Tage-Frist, kein sofortiger Hard-Delete
- Doppelte Einladung ersetzt nie automatisch — Admin muss explizit bestätigen
- Server-side Enforcement als nicht-verhandelbar (Frontend blendet aus, Server erzwingt)
- Abgelaufener Einladungslink → 410 Gone (nicht 404, semantisch korrekt)
- Mitglied-Removal: Offline-Daten bleiben bis nächsten Sync — kein Hard-Delete vom Gerät
