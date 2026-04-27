# 06 — Roadmap (priorisiert)

Reihenfolge nach Mehrwert, nicht Zeitschätzung. Jede Iteration
endet mit grünen Playwright-E2E-Tests.

## Iteration 0 — Foundation (Tooling läuft)

**Ziel**: `dotnet run --project apphost` startet alles, leere App
antwortet, E2E-Smoketest grün.

* Aspire 13.2 AppHost mit PostgreSQL + MailHog + MinIO
* Sheetstorm.Api (Minimal API) mit `/health`
* Sheetstorm.Web (Blazor WASM Hosted) mit Login-Seite (UI-only)
* CI: GitHub Actions baut, Tests laufen
* Playwright-Setup, ein Smoke-Test: Startseite lädt, Titel
  „Sheetstorm" sichtbar.

## Iteration 1 — Identität & Mitgliedschaft (höchste Priorität)

**Mehrwert**: Ohne Login + Vereine ist der Rest sinnlos.

* User-Registrierung mit E-Mail-Bestätigung
* Login / Logout / Passwort-Reset
* Profil bearbeiten (Display-Name, Avatar)
* Verein erstellen (User wird Owner)
* Mitglieder einladen per E-Mail + Beitritts­code
* Beitritt akzeptieren/ablehnen (Admin-View)
* Rollen vergeben/entziehen
* Aktiven Verein wechseln (Verein-Switcher in der Topbar)
* **Stimm-Taxonomie** initial seeded (Standard-Blasmusik-Stimmen)
* Bevorzugte Stimme pro Mitgliedschaft setzen

**E2E-Tests** (Playwright, Pflicht):
1. „Neuer Nutzer registriert sich, bestätigt E-Mail (MailHog),
   loggt ein, sieht leeres Dashboard."
2. „Owner erstellt Verein und sieht ihn als aktiv."
3. „Owner lädt zweiten Nutzer per E-Mail ein. Eingeladener
   registriert sich über Link, sieht Verein in Liste, Owner sieht
   ihn als aktives Mitglied."
4. „Beitritt per Code: Owner generiert Code, anderer Nutzer gibt
   Code ein, Owner approved, Mitgliedschaft ist aktiv."
5. „Admin entzieht Rolle ‚Dirigent', Mitglied verliert Zugang zur
   Setlist-Erstellung."
6. „Mitglied wählt Klarinette 1 in B als bevorzugte Stimme,
   Auswahl wird beim nächsten Login persistiert."

## Iteration 2 — Notenmanagement-Kern (zweithöchste Priorität)

**Mehrwert**: Werke und Stimmen verwalten + anzeigen ist die
Kernfunktion. OMR kommt erst danach (Mehrwert für Initial-Befüllung
ist groß, aber wir brauchen erst die Datenstruktur).

* Werk anlegen (Metadaten-Form, Cover-Upload)
* Stimme anlegen pro Werk, PDF hochladen
* Werk-Liste mit Filter, Suche, Sortierung
* Werk-Detail: Stimmen-Liste, Stimm-Wahl-Dropdown (mit
  Bevorzugt-Logik)
* PDF-Anzeige im Browser (PDF.js), Vor-/Zurück-Blättern, Zoom
- Werk löschen (soft) / wiederherstellen
* Sammlungen anlegen, Werke zuordnen
* Berechtigung: nur `Mitglied`+ aufwärts darf lesen,
  `Dirigent`/`Admin` darf editieren

**E2E-Tests**:
1. „Admin lädt PDF einer Stimme hoch, Mitglied sieht Stimme im
   Werk."
2. „Mitglied öffnet Werk → bevorzugte Stimme wird automatisch
   geladen."
3. „Mitglied wechselt Stimme über Dropdown."
4. „Suche nach Komponist findet Werk; Filter ‚Hat meine Stimme'
   blendet Werke ohne passende Stimme aus."
5. „Sammlung erstellen, Werk hinzufügen, Sammlung navigieren."

## Iteration 3 — Setlists & Termine

**Mehrwert**: Der Brückenschlag zu Konzertmeister-Funktionalität.
Ermöglicht Konzert-Vorbereitung End-to-End.

* Termin anlegen (alle 4 Typen), Wiederholung
* Anwesenheit melden (Yes/No/Maybe), Statistik
* Setlist erstellen, Werke zuordnen, Reihenfolge
* Setlist an Konzert/Probe koppeln
* Konzert-Modus: vereinfachte UI, schneller Sprung zwischen
  Werken der Setlist
* iCal-Export

**E2E-Tests**:
1. „Dirigent erstellt Probe-Termin, Mitglied bestätigt Anwesenheit,
   Dirigent sieht Bestätigung."
2. „Setlist mit 3 Werken, gekoppelt an Konzert. Konzert-Modus
   öffnet erstes Stück, ‚Weiter' navigiert zum zweiten."
3. „iCal-Feed liefert kommende Termine."

## Iteration 4 — Conductor Sync (Web Bluetooth + Fallback)

**Mehrwert**: Killer-Feature, das uns von Konzertmeister abhebt.
Vor OMR weil Live-Konzert-Mehrwert > Bibliotheks-Bequemlichkeit.

* Sync-Session starten (Schlüsselpaar im Browser)
* Public-Key-Verteilung an Mitglieder
* Dirigenten-Broadcast (BLE) implementiert (Chrome/Edge)
* Empfänger-Pop-up mit Stimm-Wahl
* SignalR-Fallback für iOS/non-BLE
* Pedal-Support (Keyboard-Mode + optional Web HID)

**E2E-Tests**:
1. „SignalR-Pfad: Dirigent öffnet Stück → zweite Browser-Session
   empfängt Pop-up und kann Stimme öffnen."
2. „Pedal (simuliert via Keyboard-Event ‚PageDown') blättert
   nächste Seite."
3. „Pop-up zeigt sortierte Stimm-Liste mit bevorzugter ganz oben."
4. „Replay-Schutz: alter Broadcast wird nicht erneut angezeigt."

(Echter BLE-E2E ist im Headless-Browser nicht testbar — wir testen
Logik gegen Mock-Adapter und SignalR-Pfad, dokumentieren manuelles
Testprotokoll für BLE.)

## Iteration 5 — OMR / Digitalisierung

* Audiveris-Sidecar im Aspire
* Upload-Pipeline mit Hangfire-Job
* Stimm-Erkennung-Vorschau und manuelle Korrektur
* Bulk-Import aus PDF mit allen Stimmen
* AI-Tagging (Phase 2: LLM-basiert; Phase 1: regex/heuristics)

**E2E-Tests**:
1. „User lädt PDF hoch, sieht Job-Status ‚Queued' → ‚Done',
   bestätigt vorgeschlagene Stimm-Zuordnung."

## Iteration 6 — Annotationen + Offline

* Canvas-Annotation pro Stimme
* Offline-Markierung („Auf diesem Gerät verfügbar")
* Service Worker + IndexedDB-Cache für Werke + Stimmen
* Sync nach Reconnect (LWW)

**E2E-Tests**:
1. „Annotation zeichnen, Reload, Annotation noch da."
2. „Offline-Modus (Network throttled offline): Werk lädt aus
   Cache."

## Iteration 7+ — Polish & Phase 2

* Arbeitseinsatz-Schichten
* Push-Benachrichtigungen
* AI-Tagging mit LLM
* iOS-Companion für BLE
* Geteilte Annotationen
* Sub-Ensembles
* i18n (EN, FR, IT)

## Querschnitt: Definition of Done pro Iteration

* Backend-Tests (xUnit) > 80% für neue Code­pfade
* Playwright-Tests grün für Happy-Path und 1 Edge-Case je User-Story
* OpenAPI-Spec aktualisiert, generierte Clients gebaut
* `docs/` aktualisiert wenn Architektur/Verträge sich ändern
* CI grün auf Linux + Windows
* Manuelle Smoke-Test-Checklist für Plattformen (Chrome Win,
  Chrome Android, Safari iOS) — nur Phase 1 vereinfacht
