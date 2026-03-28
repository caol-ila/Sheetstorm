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

### 2026-03-28: Feature-Spec Noten-Import & Labeling (#20) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für Noten-Import & Labeling auf Basis von Wandas UX-Spec (#19, Branch `squad/14-19-kapelle-import-ux`).

**Ergebnis:** `docs/feature-specs/noten-import-spec.md` erstellt (Branch `squad/20-import-spec`):

1. **Feature-Überblick** — Kernproblem klar benannt: Import ist Existenz-kritisch für die App. Scope MS1 abgegrenzt (Cloud-Picker, MIDI, Audio Out of Scope).
2. **5 INVEST-konforme User Stories:**
   - US-01: PDF/Bild-Upload (Drag & Drop, Dateidialog, Share-Sheet)
   - US-02: Kamera-Scan (mehrseitig, Phone/Tablet)
   - US-03: Seiten-Labeling (Stückgrenzen, Drag & Drop, Metadaten)
   - US-04: AI-Metadaten-Korrektur (Konfidenz-Anzeige, manuelle Überschreibung)
   - US-05: Persönliche Sammlung (Musiker ohne Kapellen-Rolle)
3. **17 testbare Akzeptanzkriterien** — AC-01 bis AC-17: Dateiformate, Batch, Fortschritt, PDF-Extraktion, Kamera, Share-Sheet, Labeling, Stückgrenzen, AI-Vorschläge, Isolation
4. **API-Contract (5 Endpunkte):** POST /upload (multipart), POST /labeling, POST /metadata (AI-Trigger), PUT /metadata (manuelle Korrektur), POST /stimmen — jeweils mit Request/Response-Beispielen
5. **Datenmodell (7 Tabellen):** stuecke (persönlich via musiker_id), notenblaetter (AI-Felder + konfidenz JSONB), seiten (multi-resolution), stimmen, stimm_zuordnungen, uploads, upload_dateien
6. **AI-Integration:** Dual-Key (User→Kapelle→keine AI), Adapter-Pattern (AzureAIVisionAdapter MS1), Konfidenz-Schwellen, Key-Verschlüsselung AES-256
7. **Berechtigungsmatrix:** 5 Rollen × alle Upload/Labeling-Aktionen; konfigurierbar per Kapelle
8. **8 Edge Cases:** große Dateien (>20MB), schlechte Qualität, mehrere Lieder pro Dokument, Duplikate (SHA-256), Verbindungsabbruch (Retry + State-Resume), passwortgeschützte PDFs, unbekannte Stimmen, Labeling nach Pause
9. **Definition of Done:** 25 Checkboxen (Funktional, Qualität ≥80% Coverage, UX, Technisch/Deployment)

**Wichtigste Entscheidungen in der Spec:**
- AI-Vorschläge sind immer Vorausfüllung, nie automatische Übernahme — Nutzer bestätigt explizit
- `felder_bestaetigt`-Mechanismus: manuell korrigierte Felder werden nie durch AI überschrieben
- Persönliche Sammlung = stueck mit musiker_id (kein separates System — Architektur-Entscheidung Stark)
- Labeling-State bleibt 7 Tage erhalten — kein Datenverlust bei Pause
- Duplikat-Warnung statt automatischer Ablehnung — Nutzer entscheidet
- Seiten-Extraktion läuft asynchron; App ist während Extraktion nutzbar (persistenter Banner)

### 2026-03-28: Feature-Spec Spielmodus (#25) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für den Spielmodus (Performance Mode) — das wichtigste Feature der App. Wanda's UX-Spec (#24) war zu diesem Zeitpunkt noch in Arbeit; Basis: `docs/ux-design.md` §3.1, §5.2, §5.3, §6.1, §6.4.

**Ergebnis:** `docs/feature-specs/spielmodus-spec.md` erstellt (Branch `squad/25-29-spielmodus-stimmen-spec`):

1. **Feature-Überblick** — Focus-First-Prinzip klar benannt: Spielmodus ist das Kernprodukt. Scope MS1 (8 In-Scope) und Out-of-Scope (Auto-Scroll, Face-Gesten) klar abgegrenzt.
2. **6 INVEST-konforme User Stories:**
   - US-01: Ablenkungsfreie Notenansicht (Vollbild, Wake Lock, UI-Lock)
   - US-02: Seiten blättern (Tap 40/60, Swipe, Tastatur, Mausrad)
   - US-03: Half-Page-Turn (50/50 default, konfigurierbar, Animation ≤200ms)
   - US-04: Fußpedal (AirTurn, PageFlip, iRig; HID-Kalibrierungsschritt)
   - US-05: Nacht-/Bühnenmodus (echte Invertierung, kein CSS-Filter, Sepia als dritter Modus)
   - US-06: Stimme wechseln im Spielmodus (Bottom-Sheet, temporäres Override)
3. **64 testbare Akzeptanzkriterien** (AC-01 bis AC-64)
4. **Rendering-Spec:** pdfrx + CustomPainter Canvas-Layer; Pre-Caching ±2 Seiten; Seitenwechsel < 16ms; Auto-Zoom Algorithmus 5 Schritte; Auto-Rotation asynchron
5. **Kontextuelle Einstellungen (max. 5):** Half-Page-Turn, Nachtmodus, Annotations-Layer, Helligkeit, Zoom
6. **Responsive Verhalten:** Phone Hochformat (Half-Page-Turn), Tablet Querformat (2-Seiten), Desktop (2-Seiten + Sidebar)
7. **6 Edge-Case-Gruppen:** Sehr große PDFs (>50MB), Orientation Change (AC-57–60), erste/letzte Seite, Offline, Stück ohne Stimme, Mid-Range Performance (Snapdragon 665)
8. **Definition of Done:** Funktional, Performance (< 16ms, < 150MB), UX/Accessibility (WCAG AAA), Technisch (Memory Leak Test), Tests (Parker #26)

**Wichtigste Entscheidungen in der Spec:**
- Seitenwechsel < 16ms (ein Frame @60fps) — nicht verhandelbar für Mid-Range-Tablets
- Tap-Zonen asymmetrisch: 40% zurück / 60% weiter (Ergonomie — rechts häufiger)
- Nachtmodus: echte Invertierung, kein CSS-Filter — kontrolliertes Rendering
- Overlay verschwindet automatisch nach 4 Sekunden — Focus-First
- Pre-Caching-Strategie: aktuelle Seite ±2 Seiten, Max 20MB Cache

### 2026-03-28: Feature-Spec Stimmenauswahl & Fallback-Logik (#29) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für Stimmenauswahl und den Fallback-Algorithmus. Wanda's UX-Spec (#28) war noch in Arbeit; Basis: `docs/ux-design.md` §3.1 (Bottom Sheet), `docs/anforderungen.md` §1.1a.

**Ergebnis:** `docs/feature-specs/stimmenauswahl-spec.md` erstellt (Branch `squad/25-29-spielmodus-stimmen-spec`):

1. **Feature-Überblick** — Kernprinzip: Musiker muss nichts konfigurieren — App wählt intelligent vor. Scope klar (kein Stimmenneuverteilung, kein Aushilfen-Flow).
2. **5 INVEST-konforme User Stories:**
   - US-01: Standard-Stimme festlegen (pro Kapelle, sofortige Wirkung, kein App-Neustart)
   - US-02: Automatische Vorauswahl beim Stück öffnen (synchron, kein Dialog nötig)
   - US-03: Fallback-Logik (vollautomatisch, transparent, immer irgendwas sichtbar)
   - US-04: Stimme wechseln im Spielmodus (temporäres Override, kein Profil-Update)
   - US-05: Mehrere Instrumente (1..n, je eine Standard-Stimme pro Kapelle)
3. **Fallback-Algorithmus (6 Schritte, vollständig testbar):**
   - Schritt 1: Exakte Übereinstimmung (case-insensitive, normalisiert)
   - Schritt 2: Gleiche Familie, niedrigste Nummer (z.B. 2. Klar. → 1. Klar.)
   - Schritt 3: Generische Stimme desselben Instruments (z.B. „Klarinette")
   - Schritt 4: Verwandte Instrument-Familie (Holzbläser, Blechbläser, etc.)
   - Schritt 5: Erste verfügbare Stimme
   - Schritt 6: Kein Fallback — klare Fehler-UI, kein leerer Bildschirm
4. **Normalisierungs-Algorithmus:** Trim, Case-insensitive, Numero-Normalisierung (2. = II = zweite = 2), Abkürzungs-Mapping
5. **API-Contract (4 Endpunkte):** GET /stimmen (mit `vorausgewaehlt`-Feld), GET /nutzer/instrumente, PUT /nutzer/instrumente, GET /stimmen/{id}/seiten
6. **Datenmodell (3 Tabellen):** nutzer_instrumente, stimme_vorauswahl, stimmen (mit instrument_typ für Fallback)
7. **6 Edge Cases:** keine passende Stimme, leeres Stück, Kapellenwechsel, Instrument-Wechsel (Einspringer), Schreibvarianten, Tie-Breaking
8. **Definition of Done:** 34 Akzeptanzkriterien, Fallback Unit Tests, API-Korrektheit, Parker Tests (#30)

**Wichtigste Entscheidungen in der Spec:**
- Fallback-Algorithmus läuft vollständig client-seitig (offline-fähig, < 5ms)
- Stimme wechseln im Spielmodus = temporäres Override — nie stille Änderung der Standard-Stimme
- `vorausgewaehlt`-Feld im API-Response transparent dokumentiert welchen Schritt der Fallback genommen hat
- Normalisierung behandelt mindestens: 2. = II = zweite = 2; Klar. = Klarinette
- Tie-Breaking deterministisch (alphabetisch) — kein Random, keine Abfrage

### 2026-03-28: Feature-Spec Setlist-Verwaltung (MS2) erstellt

**Aufgabe:** Vollständige Feature-Spezifikation für Setlist-Verwaltung (MS2) auf Basis von `docs/meilensteine.md` MS2-Deliverables. UX-Spec von Wanda noch ausstehend.

**Ergebnis:** `docs/feature-specs/setlist-spec.md` erstellt:

1. **Feature-Überblick** — Kernwert klar: Konzertprogramme digital durchspielbar machen. Scope MS2 abgegrenzt (GEMA-Export, Dirigenten-Sync, Templates Out of Scope).
2. **8 INVEST-konforme User Stories:**
   - US-01: Setlist erstellen (Name, Typ: Konzert/Probe/Marschmusik, Datum, Startzeit)
   - US-02: Stücke zur Setlist hinzufügen (Picker, mehrfach verwendbar, mehrere Setlists)
   - US-03: Platzhalter-Einträge (ohne Stück-Referenz, für noch nicht digitalisierte Stücke)
   - US-04: Drag & Drop Umsortierung (Touch + Desktop, Auto-Save, Undo-Toast)
   - US-05: Konzertprogramm mit Timing (geschätzte Dauer, Start-/Endzeiten berechnet, Gesamtdauer, Pauseneinträge)
   - US-06: Setlist-Modus im Player (nahtloser Übergang, Preloading < 200ms, Vor/Zurück)
   - US-07: Setlist bearbeiten/duplizieren/löschen (CRUD-Operationen, Audit-Log)
   - US-08: Setlist-Übersicht (Filter, Suche, Sortierung, Cursor-Pagination)
3. **15 testbare Akzeptanzkriterien** (AC-01 bis AC-15)
4. **API-Contract (12 Endpunkte):** GET/POST/PATCH/DELETE Setlists, Einträge hinzufügen/bearbeiten/löschen, Positionen batch-update, Duplizieren, Platzhalter-in-Stück-umwandeln, Spielmodus-Metadaten mit Preload-URLs
5. **Datenmodell (3 Tabellen):** setlists (name, typ enum, datum, startzeit, beschreibung), setlist_entries (position, typ enum: stueck/platzhalter/pause, piece_id nullable, platzhalter_felder, pause_felder, geschaetzte_dauer), setlist_audits (JSONB details)
6. **Berechtigungsmatrix:** 5 Rollen × alle Aktionen; Notenwart darf nur Metadaten fremder Setlists ändern, nicht Einträge
7. **10 Edge Cases:** Stück während Erstellung gelöscht (ON DELETE SET NULL, wie Platzhalter behandeln), leere Setlist spielen, nur Platzhalter, Timing mit fehlenden Dauer-Angaben, Drag & Drop Netzwerkfehler, Concurrent Editing (Last-Write-Wins + Reload-Hinweis), 100+ Einträge (Virtualisierung), Platzhalter-Umwandlung bei gelöschtem Stück, Stimme nicht verfügbar (Fallback-Logik), Timing über Mitternacht
8. **Abhängigkeiten:** MS1 (Kapellenverwaltung, Notenbank, Spielmodus, Stimmenauswahl), MS2 parallel (Konzertplanung, GEMA, Dirigenten-Mastersteuerung)
9. **Definition of Done:** Funktional (17 Checkboxen), Testing (Unit/Integration/Widget/E2E/Performance), Dokumentation (Swagger, DB-Migrationen, UX-Spec), NFRs (Responsive, Touch + Keyboard, Dark Mode, i18n, Offline-Cache, WCAG 2.1 AA), Deployment

**Wichtigste Entscheidungen in der Spec:**
- Platzhalter als First-Class-Citizen: Titel + Komponist + Notizen, visuell unterscheidbar, im Spielmodus übersprungen
- Timing-Kalkulation: Startzeit + Dauer → berechnete Start-/Endzeiten pro Eintrag, stoppt bei fehlender Dauer mit "?"
- Pauseneinträge: Spezialtyp für Timing (kein Stück/Platzhalter), nur für Konzertprogramm-Planung
- Setlist-Modus: Preloading nächster 3-5 Seiten, Übergang < 200ms (NFR), Platzhalter automatisch übersprungen mit Toast
- Stücke mehrfach verwendbar: Ein Piece kann in mehreren Setlists und mehrfach in derselben Setlist sein (z.B. Zugabe)
- ON DELETE SET NULL für piece_id: Wenn Stück gelöscht wird, bleibt Eintrag als "Stück nicht verfügbar" (kein CASCADE)
- Berechtigungen: Notenwart darf fremde Setlists nur Metadaten ändern (nicht Einträge) — Dirigenten planen Programme
- API-Muster: Cursor-Pagination, JWT Bearer Auth, /api/v1/kapellen/{id}/setlists, Batch-Update für Positionen

### 2026-03-28: Spec-Update — „Meine Musik", Kapellen-Auswahl, Genehmigungs-Flow

**Aufgabe:** Drei grundlegende Änderungen an den bestehenden Feature-Specs kapellenverwaltung-spec.md und auth-onboarding-spec.md auf Anweisung von Thomas.

**Ergebnis:**

1. **„Meine Musik" (Persönliche Bibliothek):**
   - Neue US-00 in Kapellenverwaltung-Spec eingefügt
   - Datenmodell: `ist_persoenlich` Boolean auf kapellen-Tabelle, Unique Index pro Nutzer
   - Berechtigungsmatrix: Alle Manipulationsversuche (Löschen, Verlassen, Einladen, Rollen ändern) → 403
   - Edge Case 7.9 deckt alle Schutzszenarien ab

2. **Kapellen-/Band-Auswahl als Einstiegsscreen:**
   - Auth-Spec: US-02 (Login) und US-04 (Onboarding) aktualisiert — nach Login/Onboarding → Kapellen-Auswahl statt Bibliothek
   - Auth-Spec: AC-05 erweitert um „Meine Musik"-Erstellung bei Registrierung
   - Kapelle-Spec: US-04 AC-7 und AC-11 aktualisiert für neuen Einstiegsscreen
   - Ausnahme-Logik: Nur eine Kapelle + „Meine Musik" → direkt zur letzten aktiven Kapelle

3. **Genehmigungs-Flow (kein Auto-Join):**
   - US-02 komplett überarbeitet: Einladungslink/E-Mail → Beitrittsanfrage → Genehmigung
   - Neue US-06: Beitrittsanfrage genehmigen/ablehnen (Admin, Dirigent, Registerführer)
   - §4.4 API komplett überarbeitet: 7 Endpunkte inkl. POST beitrittsanfrage, GET/PUT beitrittsanfragen
   - §5.4 Datenmodell erweitert: neue `beitrittsanfragen`-Tabelle, `einladung_status` geändert ('angenommen' → 'verwendet')
   - Berechtigungsmatrix: 3 neue Zeilen für Beitrittsanfragen (Admin ✅, Dirigent ✅, Registerführer ✅)
   - 5 neue Edge Cases (7.9–7.13)

**Quantitative Änderungen:** 5→7 User Stories, 10→15 ACs, 8→13 Edge Cases, DoD aktualisiert

**Wichtigste Entscheidungen:**
- „Meine Musik" nutzt `ist_persoenlich`-Flag, kein separates System — Architektur-Konsistenz
- `einladung_status` verliert 'angenommen', gewinnt 'verwendet' — Einladungen sind nicht mehr das Endstück
- Beitrittsanfragen haben eigene Tabelle mit Partial Unique Index (`WHERE status = 'ausstehend'`)
- Registerführer darf Beitrittsanfragen genehmigen — Rollen-Konsistenz mit bestehender Verantwortung
- Abgelehnte Nutzer können erneut anfragen, aber nur über neuen Link — kein Spam-Vektor

**Betroffene Dateien:**
- `docs/feature-specs/kapellenverwaltung-spec.md`
- `docs/feature-specs/auth-onboarding-spec.md`
- Decision: `.squad/decisions/inbox/hill-meine-musik-genehmigungs-flow.md`
