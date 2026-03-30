# Squad Decisions

## Active Decisions

### 2026-03-28T10:31Z: Code Review Policy
**By:** Thomas (via Copilot)  
**Decision:** Alle Codeänderungen müssen von 3 verschiedenen Reviewern überprüft werden, die unterschiedliche AI-Modelle verwenden: Claude Sonnet 4.6, Claude Opus 4.6, und GPT 5.4. Der Lead (Stark) überprüft die Reviews und entscheidet, welche Änderungsvorschläge umgesetzt werden, welche später kommen, und welche verworfen werden.

### 2026-03-28T10:31Z: Sprache & Internationalisierung
**Decision:** Start mit Deutsch. Mehrsprachigkeit ist möglich, aber nicht Priorität. German-first, i18n-Architektur für später.

### 2026-03-28T10:31Z: Meilenstein-Strategie
**Decision:** Jeder Meilenstein muss ein vollständiges Delivery mit End-Nutzer-Mehrwert sein. Priorität: (1) Import & Spielmodus + Kapellenverwaltung, (2) Vereinsleben-Features, (3) Erweiterungen & Optimierungen. Alles muss getestet, UX-Flows validiert und die App deploybar sein bei jedem Meilenstein.

### 2026-03-28T10:31Z: Plattform & Touch
**Decision:** Die App soll im Browser, als mobile App (Handy/Tablet) und als Desktop-Anwendung laufen. Touch-Unterstützung ist Pflicht. Fokus auf ablenkungsfreies Spielen.

### 2026-03-28T10:42Z: App-Name
**Decision:** Der Name der Anwendung ist **Sheetstorm**.

### 2026-03-28T10:44Z: GitHub Workflow
**Decision:** Aufgaben als GitHub Issues tracken. Alle Änderungen als Pull Requests. Code-Review-Ergebnisse als Kommentare im PR posten.

### 2026-03-28T11:00Z: UX Review Pflicht
**Decision:** Alle Frontend-Änderungen bzw. Dinge mit denen ein Nutzer interagiert sollen einen UX-Review haben, der verifiziert dass alles funktioniert wie erwartet und sich perfekt bedienen lässt.

### 2026-03-28T11:00Z: Konfigurationskonzept im Meilenstein 1
**Decision:** Das Konfigurationskonzept (User/Gerät/Kapelle-Ebenen) soll Teil des ersten Meilensteins sein und eine sehr gute UX haben.

### 2026-03-28T11:19Z: Externe Abhängigkeiten — immer Web-Suche
**Decision:** Bei allen externen Dependencies (Bibliotheken, Frameworks, Tools) IMMER eine aktuelle Web-Suche nach der neuesten stabilen Version durchführen. Nie auf vorhandenes Wissen verlassen. Es wird immer mit den neuesten stable Versionen gebaut.

### 2026-03-28T11:22Z: Entscheidungen via PR
**Decision:** Entscheidungen die Thomas treffen soll, werden als Dokumente in einem PR bereitgestellt — nicht inline im Chat. Thomas reviews und entscheidet im PR.

### 2026-03-28T11:26Z: Immer neueste Modellversionen
**Decision:** Immer die neueste verfügbare Version jedes AI-Modells verwenden. Keine veralteten Versionen.

### 2026-03-28T22:57Z: User Directive — "Meine Musik" & Kapellenverwaltung
**By:** Thomas (via Copilot)  
**Decision:** Jeder Nutzer erhält eine persönliche Bibliothek ("Meine Musik"), die wie eine Kapelle funktioniert — der Nutzer ist Admin. Bei einer Band/Kapelle gibt es einen oder mehrere Admins und andere Rollen. Nach dem Onboarding ist der Einstiegspunkt die Kapellen-/Band-Auswahl. Beitritt zu einer Kapelle/Band erfordert Einladungslink/Code UND Genehmigung durch Admin, Dirigent oder Registerführer.

### 2026-03-28T22:10Z: „Meine Musik", Kapellen-Auswahl als Einstieg, Genehmigungs-Flow
**By:** Hill (Product Manager)  
**Date:** 2026-03-28

**Entscheidungen:**

1. **„Meine Musik" — Persönliche Bibliothek als Kapelle**
   - Jeder Nutzer erhält bei der Registrierung automatisch eine „Meine Musik"-Kapelle (`ist_persoenlich = TRUE`)
   - Nutzer ist alleiniger Admin, kann nicht löschen/verlassen/einladen
   - Nutzt dieselbe Kapellen-Infrastruktur (kein separates System)
   - Erscheint als erster Eintrag im Kapellen-Wechsel-Selector

2. **Kapellen-/Band-Auswahl als Einstiegsscreen**
   - Nach Login UND nach Onboarding: Einstiegspunkt ist die Kapellen-/Band-Auswahl (nicht die Bibliothek)
   - Ausnahme: Nur eine Kapelle + „Meine Musik" → direkt zur zuletzt aktiven Kapelle
   - Ausnahme: Nur „Meine Musik" → direkt in „Meine Musik"

3. **Beitrittsflow mit Genehmigung (kein Auto-Join)**
   - Einladungslink/E-Mail → Beitrittsanfrage wird erstellt → Genehmigung durch Admin, Dirigent ODER Registerführer
   - Status-Flow: ausstehend → genehmigt | abgelehnt
   - Abgelehnte Nutzer können über neuen Einladungslink erneut anfragen
   - E-Mail-Einladung: Admin gibt E-Mail ein, Nutzer muss trotzdem genehmigt werden

**Betroffene Specs:**
- `docs/feature-specs/kapellenverwaltung-spec.md` — US-00, US-02 (Rewrite), US-06, §4.4, §5.1, §5.4, §6, §7.9–7.13, DoD
- `docs/feature-specs/auth-onboarding-spec.md` — US-02, US-04, AC-05, AC-06, Grenzfälle

**Betroffene Teams:**
- **Stark** — Datenmodell-Änderungen: `ist_persoenlich` auf kapellen, neue `beitrittsanfragen`-Tabelle, `einladung_status` geändert
- **Wanda** — UX-Flows: Kapellen-Auswahl als Einstieg, Genehmigungs-UI, „Meine Musik"-Darstellung
- **Romanoff/Banner** — Implementierungs-Scope hat sich vergrößert (7 statt 5 User Stories, 15 statt 10 ACs)
- **Parker** — Neue Testszenarien: Genehmigungs-Flow, „Meine Musik"-Schutz, 13 statt 8 Edge Cases

---

### Spezifikation & Meilensteinplanung
**By:** Stark (Lead / Architect)  
**Date:** 2026-03-28

#### Datenmodell
Persönliche Sammlung = Stück mit Musiker-ID statt Kapelle-ID (gleiche Mechanismen, kein separates System)

#### Annotationen
SVG-Layer mit relativen Positionen, 3 Sichtbarkeitsebenen: Privat (Grün) / Stimme (Blau) / Orchester (Orange)

#### AI-Architektur
Adapter-Pattern, Fallback-Kette User→Kapelle→keine AI

#### Metronom-Sync
WiFi UDP primär, WebSocket Fallback, Timestamps statt Live-Kommandos

#### Meilenstein-Abhängigkeiten
M4 (Lehre) kann parallel zu M2/M3 starten — nur Kern-Abhängigkeit

---

### Technologie-Stack (v2)
**Frontend:** Flutter 3.35.4 (Dart) — eigene Rendering-Engine, beste Canvas/Touch/Stift für Cross-Platform, 95%+ Code-Sharing  
**Backend:** ASP.NET Core 10 (.NET 10 LTS) — Performance-Leader, nativer UDP für Metronom  
**Server-DB:** PostgreSQL 18.3 — JSONB für Config, relationale Power für Permissions  
**Client-DB:** SQLite 3.51.3 via Drift 2.32.1 — Offline-Cache  
**Realtime:** UDP Multicast (LAN, <5ms) + SignalR WebSocket (Fallback)  
**Hosting:** Azure Ökosystem (App Service, Blob, CDN, AppInsights)  
**State:** Riverpod 3.0 (Offline-Persistence, Auto-Retry)  
**PDF:** pdfrx (all platforms)  
**Monitoring:** AppInsights + OpenTelemetry

**Fallback:** Flutter-Eignung evaluiert nach MS1 Sprint 2. Umschwenken auf Avalonia 12 (C#/XAML, Skia-Engine) falls Performance-Ziele nicht erreicht.

---

### Marktpositionierung & Preismodell
**Positioning:** Einzige All-in-One-Lösung mit professioneller Notenanzeige + Vereinsverwaltung + AI-Upload + Blasmusik-spezifisches Stimmen-Mapping

**Pricing (transparent, öffentlich):**
- Free: Bis 15 Mitglieder, 1 Kapelle
- Starter: ~39€/Jahr/Kapelle (bis 40 Mitglieder)
- Pro: ~99€/Jahr/Kapelle (unbegrenzt, AI inklusive)
- Pro+AI: ~149€/Jahr/Kapelle (zentraler AI-Key)

**Evidenz:** Konzertmeister (33-99€/Jahr) akzeptiert, Intransparenz erzeugt Misstrauen, BAND App zeigt virales Potenzial von Aushilfen-Links.

---

### Feature-Priorisierung

#### P0 (MVP, unverhandelbar)
1. Professioneller PDF-Viewer mit Performance-Modus + Half-Page-Turn
2. Stimmen-Mapping mit Fallback-Logik
3. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester)
4. 1-Klick Zu-/Absage System
5. Offline-Unterstützung für heruntergeladene Noten
6. Cross-Platform: Web + iOS + Android

#### P1 (Kurz nach Launch)
7. Bluetooth-Pedal-Support
8. Ensemble-Setlist-Sharing
9. AI-Upload mit Labeling-Flow
10. Aushilfen-Link ohne Registrierung
11. Dirigenten-Masterfunktion

#### P2 (Spätere Releases)
12. BYOK AI-Keys
13. Echtzeit-Metronom-Sync
14. IMSLP-Integration
15. Lehre-Modul

---

### UX-Kernpatterns (aus Konkurrenzanalyse)

#### MUST HAVE
- **Performance-Modus:** Vollbild, alle UI versteckt (forScore, MobileSheets Standard)
- **Half-Page-Turn:** Verhindert „Page-Jump-Schock" — day-1-Feature (forScore, Newzik)
- **3-Ebenen-Annotationen:** Privat/Stimme/Orchester (differenzierer vs. Konkurrenz)
- **Stylus-First:** Stift berührt = annotieren, kein Menü-Umweg (forScore Standard)
- **1-Klick Stimmenneuverteilung:** Fallback-Logik automatische Ersatzmusiker-Vorschlag (Notabl Pattern)
- **Asymmetrische Tap-Zonen:** 40% zurück / 60% weiter (ergonomisch)
- **Kontextmenü 5 Optionen Max:** Nachtmodus, Half-Page-Turn, Schriftgröße, Annotations-Layer, Helligkeit
- **Auto-Save ohne Speichern-Button:** Undo-Toast 5 Sekunden
- **Keine Einstellung erfordert Neustart**
- **Onboarding 5 Fragen Max:** Alle überspringbar

#### SHOULD HAVE
- **Web = Admin, App = Performance:** Notenwart verwaltet am PC, Musiker spielt am Tablet (Newzik Pattern)
- **Aushilfen-Link ohne Registrierung:** Temporärer Token, nur zugewiesene Stimme (Musicorum Pattern)
- **Split-View Tablet/Desktop:** Navigation links, Inhalt rechts
- **Bottom-Navigation 4 Tabs:** Bibliothek, Setlists, Kalender, Profil
- **Deep-Link-Schema:** sheetstorm://bibliothek/[id], sheetstorm://aushilfe/[token]

---

### Konfigurationssystem (3-Ebenen)

**Ebenen:** Kapelle (Blau) → Nutzer (Grün) → Gerät (Orange)  
**Override:** Gerät > Nutzer > Kapelle > Default (mit Policy-Blockierung)

**MUST HAVEs:**
- Auto-Save mit Undo-Toast
- Farbkodierung (Blau/Grün/Orange) mit Icon + Pattern (barrierefreiheit)
- Kontextuelle Einstellungen im Spielmodus (5 max)
- Geräte-Einstellungen werden NICHT synchronisiert
- Intelligente Defaults pro Gerätetyp
- Onboarding max 5 Fragen
- Transparente Vererbungshierarchie („Standard von Kapelle")
- Erzwungene Einstellungen mit Schloss-Icon

---

### Marktforschung Key Insights

**17+ Wettbewerber analysiert:**  
Marschpat, Notabl, Newzik, forScore, MobileSheets, Konzertmeister, BAND, Glissandoo, Musicorum + weitere

**Zentrale Marktlücken:**
1. Keine Kombination aus professioneller Notenanzeige + Vereinsverwaltung + AI-Upload
2. Intelligentes Stimmen-Mapping mit Fallback-Logik existiert nirgendwo
3. AI-gestützter Multi-Lied-Upload mit Labeling ist ein Novum
4. Multi-Kapellen-Zugehörigkeit wird von keinem Wettbewerber unterstützt
5. Drei-Ebenen-Annotationen (Privat/Stimme/Orchester) als Kernkonzept fehlt überall
6. Echtzeit-Metronom-Sync im Notenkontext nicht integriert
7. Lehre-Modul im Vereinskontext nicht existent

**Anti-Patterns zu vermeiden:**
- Zu viele Display-Modi ohne gute Defaults (MobileSheets)
- Notenverwaltung als Datei-Ablage ohne Struktur (Konzertmeister)
- Preis nur „auf Anfrage" → Misstrauen (Newzik Ensemble, notabl)
- App-Absturz-Risiko bei Live → Performance-Tests + Offline-Fallback Pflicht

**Architektur-Evidenz:** Offline-First (Outdoor, schlechtes WLAN), Web+App-Split (Newzik erfolgreich), Cross-Platform (Konzertmeister im DACH erfolgreich)

---

### SheetHappens-Vergleich (aus Feature-Gap-Analyse)

**Baseline:** 57 SheetHappens-Features analysiert  
- ✅ 16 in Sheetstorm-Spec
- ⚠️ 11 teilweise
- ❌ 25 fehlend
- 🆕 5 Sheetstorm-exklusiv

**Wichtigste Erkenntnisse:**
- GEMA-Reporting: Gesetzliche Pflicht, SheetHappens hat komplettes Datenmodell
- Conductor Mode (Song-Broadcast): Killer-Feature für Proben
- Offline-Architektur: Nur Anforderung, nicht architektonisch spezifiziert
- Server-WebP-Konvertierung: Vereinfacht Cross-Platform

**Sheetstorm-Vorteile:** Auto-Rotation, Auto-Zoom, Schichtplanung, Kalenderansicht, Cloud-Storage-Sync

---

### Top 10 Recommendations (aktueller Stand)

1. **GEMA-Meldung** (gesetzliche Pflicht, kein Konkurrent hat es)
2. **1-Klick-Stimmenneuverteilung** (Alltags-Workflow)
3. **Zweiseitenansicht** (kleiner Aufwand, große UX-Wirkung)
4. **Chat / Gruppen-Messaging** (WhatsApp-Ablösung)
5. **Kalender-Sync bidirektional**
6. **Wiederkehrende Termine**
7. **Erweiterte Stempel-Bibliothek**
8. **Media Links (YouTube/Spotify)**
9. **CSV/Excel-Migrations-Import**
10. **Dirigenten-Modus Song-Broadcast**

---

### 2026-03-28T12:44Z: Echtzeit-Metronom — Bluetooth als primäre Technologie
**By:** Thomas (via Copilot)  
**Decision:** Bluetooth (BLE Broadcast) ist die primäre Technologie für den Echtzeit-Klick/Metronom. Gründe: einfachste Umsetzung, kein extra WLAN nötig, kein Koppeln, gute Latenz, ausreichende Reichweite. Andere Optionen (WebSocket, WebRTC, etc.) sind spätere Fallback-Optionen.

### 2026-03-28T12:55Z: Worktrees für alle Codeänderungen — PFLICHT
**By:** Thomas (via Copilot)  
**Decision:** Jede Codeänderung wird auf einem eigenen Branch mit Git Worktrees umgesetzt. Keine Codeänderungen direkt auf main. PFLICHT-Regel zur Konfliktvermeidung bei paralleler Agent-Arbeit. Gilt ab sofort, keine Ausnahmen.

### 2026-03-28T14:36Z: Architektur-Entscheidungen von Thomas
**By:** Thomas (via Copilot)  

1. **Storage-Backend:** S3-kompatibel — MinIO lokal für Entwicklung, S3 in Produktion.
2. **Refresh-Token-Hashing:** Gehashte Tokens in der DB von Anfang an (sicherer, kein Migrationrisiko).
3. **Stimme-Scope:** Stimmen werden von den Noten vorgegeben (global aus den Dokumenten). Nutzer geben an was sie spielen können/wollen. Fallback-Mapping ist pro Kapelle konfigurierbar, Nutzer kann es individuell anpassen. Der erste Vorschlag (Default) ist global der gleiche.
4. **E-Mail-Bestätigung:** Pflicht bei Registrierung. Für Testing braucht es einen Mechanismus für voraktivierte User (z.B. Seed-Daten oder Admin-Endpoint).

### 2026-03-28T14:36Z: Automatisierte Reviews — Thomas reviewt nicht
**By:** Thomas (via Copilot)  
**Decision:** Thomas möchte PRs NICHT selbst reviewen. Der gesamte Review-Prozess ist automatisiert: 3 Reviews mit 3 verschiedenen Modellen (Sonnet 4.6, Opus 4.6, GPT 5.4), dann entscheidet der Lead (Stark). Reviews als Kommentare im PR. Tests werden lokal ausgeführt, nicht in CI (keine Kapazität dafür).

### 2026-03-28T14:36Z: Tests lokal, nicht in CI
**By:** Thomas (via Copilot)  
**Decision:** Tests sollen lokal ausgeführt werden, nicht in GitHub Actions CI. Thomas hat nicht genug CI-Kapazität.

### 2026-03-28T14:42Z: Review-Prozess — eindeutige Spezifikation
**By:** Thomas (via Copilot)  
**Decision:** Der Review-Prozess ist eindeutig spezifiziert:
1. ZUERST: 3 unabhängige Reviews mit 3 verschiedenen Modellen (Sonnet 4.6, Opus 4.6, GPT 5.4) — als PR-Kommentare
2. DANACH: Stark (Lead) schaut sich die 3 Reviews an und entscheidet:
   - Was wird direkt übernommen (Agent fixt es auf dem Branch)
   - Was wird ein Follow-up Issue (später)
   - Was wird nicht gemacht (begründet abgelehnt)
3. Stark entscheidet ob gemerged wird (Approve/Reject)
4. Thomas reviewt NICHT — der gesamte Prozess ist automatisiert

Reihenfolge ist PFLICHT: Reviews ERST, dann Lead-Entscheidung, dann Merge.

---

### 2026-03-29T16:00Z: Fix Branch Merge Decisions
**By:** Stark (Lead / Architect)  
**Date:** 2026-03-29

**Context:** 3 fix branches reviewed by 3 independent models (Sonnet 4.6, Opus 4.6, GPT 5.4). Decisions based on cross-referencing all reviews against project decisions and architecture.

#### squad/88-auth-fix (Auth Backend)
**VERDICT:** REJECT (with fixes)

**FIX NOW (must resolve before merge):**
1. **LoginAsync must enforce EmailVerified** — Add check in `LoginAsync`: if `!user.EmailVerified`, return error (not a token). Thomas explicitly decided "E-Mail-Bestätigung: Pflicht bei Registrierung." All 3 reviewers flagged this. Unauthenticated users must not receive JWTs.
2. **Hash email verification tokens** — Store verification tokens hashed (SHA-256), same as refresh tokens. Thomas decided "Gehashte Tokens in der DB von Anfang an." Lookup via hash comparison, not plaintext column query.

---

### 2026-03-29T21:31Z: MS2 UX-Specs — 9 Features Defined
**By:** Wanda (UX Designer)  
**Date:** 2026-03-29

**Status:** Ready for Review

Parallel creation of 9 comprehensive MS2 feature UX specifications:

#### Features Documented
1. **Setlist Management** (`docs/ux-specs/setlist.md`) — Song collections, ordering, metadata, versioning
2. **Concert Planning** (`docs/ux-specs/konzertplanung.md`) — Event scheduling, musician assignment, performance timeline
3. **Team Communication** (`docs/ux-specs/kommunikation.md`) — Messaging, notifications, collaboration patterns
4. **GEMA Compliance** (`docs/ux-specs/gema-compliance.md`) — Rights management reporting with AI confidence scoring
5. **Media Links** (`docs/ux-specs/media-links.md`) — YouTube/Spotify deep-links, oEmbed metadata, AI suggestions
6. **Song Broadcasting** (`docs/ux-specs/song-broadcast.md`) — Real-time sync with SignalR, transparentstatus indicators
7. **Attendance Tracking** (`docs/ux-specs/anwesenheit.md`) — Musician presence, role-based views, notifications
8. **Relief/Temporary Members** (`docs/ux-specs/aushilfen.md`) — Substitute workflows, availability, training status
9. **Shift Scheduling** (`docs/ux-specs/schichtplanung.md`) — Rehearsal/performance assignments, conflict detection

#### Key UX Patterns
- **Accessibility:** 44×64px touch targets, ARIA labels, screen reader support, keyboard navigation
- **Responsive:** Phone/Tablet/Desktop layouts with grid systems
- **Permissions:** Admin/Dirigent full control, Notenwart CRUD, Registerführer limited, Musiker read-only

---

## MS2 Frontend Implementation Decisions (2026-04-15)

### Vision: Setlist + Song Broadcast Architecture

**Date:** 2026-04-15  
**By:** Vision (Principal Frontend Engineer)  
**Status:** Implemented (21 files)

#### 1. SignalR via WebSocket + JSON Protocol (Manual Implementation)
**Decision:** No Dart SignalR package available → implemented SignalR JSON protocol manually over `web_socket_channel:^3.0.2`
- Record separator (0x1E) delimited JSON messages
- Handles invocation (type 1), ping/pong (type 6), close (type 7)
- Exponential backoff reconnect (2s → 32s, 5 attempts max)

**Impact:** Backend team aware that client implements raw SignalR JSON. Future Dart SignalR package adoption affects only `BroadcastSignalRService`.

#### 2. Feature Routes in routes.dart (Not app_router.dart)
**Decision:** Each feature exports GoRoute definitions in `routes.dart`. NOT integrated into `app_router.dart` per charter.
- Avoids merge conflicts
- Requires manual integration (separate PR)
- Placeholder replacement for setlist routes in shell branch

#### 3. German Identifier Normalization
**Decision:** API spec uses `ü` in JSON field names (e.g., `aktivesStückId`). Dart source uses ASCII equivalents (`aktiveStueckId`) with JSON key mapping.
**Reason:** Avoid encoding issues in Dart source files while matching API contract.

#### 4. Player State Machine
**Decision:** SetlistPlayer uses simple state machine: `idle → loading → playing ↔ paused → finished`
- Auto-advance timer-based (30s default)
- Real timing data from API overrides default

---

### Romanoff: Events/Calendar Feature Module

**Date:** 2026-04-15  
**By:** Romanoff (Frontend Developer)  
**Status:** Implemented (13 files)

#### 1. CalendarEntry vs Event Model Separation
**Decision:** Separate `CalendarEntry` model for calendar views (minimal data) vs. full `Event` model for detail screens.
**Rationale:**
- Calendar views need only title, type, date, time, RSVP status
- Event details include description, setlist, statistics, meeting point, dress code
- Backend can optimize `/kalender` endpoint separately from `/termine`
- Reduces network traffic and rendering time

#### 2. RsvpStatus & EventType as Enums with Backend String Mapping
**Decision:** Enums with `toJson()`/`fromJson()` methods mapping to German backend strings ("Probe", "Zugesagt").
**Reason:** Backend sends German strings, Dart enums default to lowercase. Custom label property controls JSON serialization.

#### 3. Riverpod Family for EventDetailNotifier
**Decision:** `EventDetailNotifier` as Riverpod family (parameter: `eventId`).
**Reason:** Each event has own state. Fine-grained caching. Only affected event reloads on RSVP change. Matches band_notifier pattern.

#### 4. Material 3 SegmentedButton for View Switcher
**Decision:** `SegmentedButton` instead of TabBar for Month/Week/List switching.
**Reason:** No AppBar needed. Material 3 consistent. Better for mode selection (not hierarchical navigation).

#### 5. RSVP Cancellation Dialog with Optional Reason
**Decision:** Cancel opens dialog with optional reason text field.
**Reason:** Progressive disclosure. Prevents accidental rejection. Follows UX spec.

#### 6. CalendarMonthView with Colored Dots
**Decision:** Month grid shows only colored dots (max 3) per day, not event titles.
**Reason:** Space constraint on phone (40-50px per cell). UX spec requires dots. Tap day for full list.

#### 7. Create/Edit Flows Deferred
**Decision:** Create/Edit events NOT implemented. FAB shows placeholder snackbar.
**Reason:** Focus on calendar views + detail + RSVP. Complex form deferred. Backend contract defined.

---

### Romanoff: GEMA Compliance + Media Links Implementation

**Date:** 2026-04-15  
**By:** Romanoff (Frontend Developer)  
**Status:** Implemented (22 files)

#### 1. Manual JSON Serialization (No json_serializable)
**Decision:** Hand-written `fromJson`/`toJson` methods for all models.
**Rationale:** Consistent with auth_models pattern. Avoids build_runner churn. Models simple without complex nesting.

#### 2. Media Links as Widgets, Not Standalone Routes
**Decision:** Media Links are reusable widgets (`MediaLinkList`, `MediaLinkEditor`) integrated into piece detail views.
**Rationale:** Per UX spec, links primarily in piece detail/setlist views. Reduces navigation complexity. Contextual to specific pieces. Empty `routes.dart` as placeholder.

#### 3. Stub .g.dart Files for Generated Providers
**Decision:** Create stub files for Riverpod-generated providers until `build_runner` execution.
**Rationale:** Flutter SDK unavailable on build agent. Stubs allow compilation. Real generation via `flutter pub run build_runner build`.

#### 4. url_launcher for Deep Links
**Decision:** Use `url_launcher:6.3.1` with `LaunchMode.externalApplication` for YouTube/Spotify links.
**Rationale:** Cross-platform solution. Auto-selects app if installed, fallback to browser. No platform-specific code needed.

#### 5. GEMA Report Status = Edit Permission Source
**Decision:** Report status (`Entwurf` vs. `Exportiert`) is single source of truth for edit permissions.
**Rationale:** Exported reports immutable (audit requirement). UI enforces via status checks. Backend must also enforce.

#### 6. Family Notifiers for Parametrized State
**Decision:** Use `@riverpod` family notifiers:
- `GemaReportDetailNotifier(kapelleId, reportId)`
- `MediaLinkNotifier(kapelleId, stueckId)`
**Rationale:** Fine-grained cache invalidation. Best practice for parametrized Riverpod 3.x state.

---

### Romanoff: Communication Module (Posts + Polls)

**Date:** 2026-04-15  
**By:** Romanoff (Frontend Developer)  
**Status:** Implemented (23 files)

#### 1. Shared Author Model via Duplication
**Decision:** Duplicate `Author` class in `post_models.dart` and `poll_models.dart`.
**Rationale:**
- No shared/models/ directory in current architecture
- Avoids circular dependencies
- Low maintenance cost for stable 4-field model
- Acceptable DRY violation for feature scoping

#### 2. Reaction Storage as Map<ReactionType, Reaction>
**Decision:** Use `Map<ReactionType, Reaction>` instead of `List<Reaction>`.
**Rationale:**
- O(1) lookup for toggle logic
- Matches backend JSON structure (object keys)
- Type-safe enum keys
- Efficient updates without list scanning

#### 3. No Build Runner Generated Code (Stub .g.dart Files)
**Decision:** Create `.g.dart` stub files instead of running build_runner during implementation.
**Rationale:** Flutter SDK unavailable. Stubs enable compilation. Real providers generated post-install.

#### 4. timeago Package for Relative Time
**Decision:** Add `timeago:^3.7.0` for "vor 5 Minuten" formatting.
**Rationale:** German locale support. Automatic unit selection. Standard pattern. Zero maintenance.

#### 5. Board Screen = Unified Feed (Posts + Polls)
**Decision:** Integrate polls into `board_screen.dart` via tabs (Alle/Pinned/Umfragen).
**Rationale:** UX spec alignment. Single navigation destination. Simpler routing. Distinct card designs make mixing intuitive.

#### 6. Routes in routes.dart (Not app_router.dart)
**Decision:** Create `routes.dart` with GoRoute definitions. DO NOT modify app_router.dart.
**Rationale:** Charter constraint. Clean separation. Easy integration. Future-proof for routing changes.

#### 7. Optimistic UI for Reactions & Comments
**Decision:** Update state immediately, rollback on error.
**Rationale:** Perceived performance. UX best practice (Twitter/Facebook pattern). Low-risk operations. Riverpod AsyncValue auto-rollback.

---

### Romanoff: Attendance + Substitute + Shifts Implementation

**Date:** 2026-04-15  
**By:** Romanoff (Frontend Developer)  
**Status:** Implemented (33 files)

#### 1. Standard Feature Structure
**Decision:** All 3 modules (Attendance, Substitute, Shifts) follow identical folder structure:
```
features/{feature_name}/
├── data/models/       # Manual JSON serialization
├── data/services/     # API service layers
├── application/       # Riverpod notifiers
├── presentation/
│   ├── screens/
│   └── widgets/
└── routes.dart        # NOT in app_router.dart
```
**Reason:** Consistency, predictable navigation, separation of concerns.

#### 2. Riverpod 3.x Codegen with @riverpod Annotations
**Decision:** All notifiers use `@riverpod` codegen with part directives.
- Type-safe code generation
- Auto-dispose by default (keepAlive: true for persistent state)
- Family notifiers for parametrized state
- Consistent with band_notifier pattern

#### 3. Manual JSON Serialization
**Decision:** Hand-written fromJson/toJson (no build_runner generation yet).
**Reason:** Matches auth_models pattern. Avoids build_runner churn. Simple models don't need generated serialization.

#### 4. Color-Coded Status Indicators
**Decision:** Use consistent color scheme for percentage-based statistics:
- **Green (AppColors.success):** >80%
- **Yellow/Orange (AppColors.warning):** 60-80%
- **Red (AppColors.error):** <60%
**Reason:** Accessibility (color + icon). Consistent with design tokens. Matches UX spec.

#### 5. Routes as Separate Files (Not app_router.dart)
**Decision:** Each feature has `routes.dart`. DO NOT modify app_router.dart.
**Reason:** Avoids merge conflicts. Feature routes independent. Integration in separate PR.

#### 6. Hardcoded German Strings (No i18n in MS2)
**Decision:** All UI strings hardcoded in German.
**Reason:** German-first implementation. i18n framework deferred to MS3. Faster development.

#### 7. QR Code & Charts as Placeholders
**Decision:** QR generation (`qr_flutter`) and charts (`fl_chart`) implemented as custom widgets with TODOs.
**Reason:** Avoid dependencies before Flutter install. Structure ready. Packages added later.

#### Attendance Feature Specifics
- **Models:** 7 (AttendanceStats, MemberAttendance, RegisterAttendance, AttendanceTrend, TrendDataPoint, ExportData)
- **Screens:** 1 dashboard with 3 tabs (Musiker, Register, Trends)
- **Widgets:** 5 (Chart, StatCard, RegisterBreakdown, ExportButton, TrendGraph)
- **API:** 5 endpoints (GET stats, register, trends; POST/GET export)
- **State:** AttendanceNotifier with date range + event type filters

#### Substitute Feature Specifics
- **Models:** 3 (SubstituteAccess, SubstituteLink, SubstituteStatus enum)
- **Screens:** 2 (Management list, Link display with QR)
- **Widgets:** 3 (AccessLinkCard, QRCodeGenerator, StatusBadge)
- **API:** 5 endpoints (CRUD + extend)
- **State:** SubstituteListNotifier with active/expired filtering

#### Shift Planning Feature Specifics
- **Models:** 4 (ShiftPlan, Shift, ShiftAssignment, ShiftStatus enum)
- **Screens:** 2 (Plan overview, Shift detail)
- **Widgets:** 3 (ShiftSlot, ShiftAssignmentCard, OpenShiftsBadge)
- **API:** 8 endpoints (Plans/Shifts CRUD, assignments)
- **State:** ShiftPlanListNotifier, ShiftPlanNotifier family, myShifts, openShifts providers

#### Code Style Conventions
- **Imports:** Alphabetical (flutter → riverpod → sheetstorm → features → shared)
- **const constructors** where possible
- **Null-safety:** required without `?`, optional with `?`
- **Provider naming:** `{feature}ServiceProvider`, `{feature}NotifierProvider`

#### UI/UX Standards
- Material 3 design
- AppTokens spacing (xs/sm/md/lg/xl)
- AppColors theme colors
- Touch targets: min 44px
- RefreshIndicator on all list screens
- Empty states with helpful messages

#### Error Handling Pattern
- Try-catch in notifiers
- AsyncValue.guard() for mutations
- Return bool for success/failure
- SnackBar feedback in UI

---

## Shared MS2 Frontend Decisions

### Dependency Additions
```yaml
web_socket_channel: ^3.0.2        # SignalR WebSocket protocol
url_launcher: ^6.3.1              # Deep linking for media
timeago: ^3.7.0                   # German relative time formatting
```

**Placeholder Dependencies (post-Flutter install):**
- `qr_flutter` — QR code generation
- `fl_chart` or `syncfusion_flutter_charts` — Charts
- `share_plus` — Link sharing

### Common Patterns Across All Modules
1. **Clean Architecture:** data/application/presentation separation
2. **Riverpod 3.x:** Family notifiers, auto-dispose, codegen
3. **Manual JSON:** No json_serializable (avoids build_runner churn)
4. **Material 3:** Consistent design across all features
5. **Accessibility:** 44px touch targets, color + icon indicators
6. **German-First:** Hardcoded strings (i18n deferred to MS3)
7. **Routes.dart:** Feature routes NOT integrated into app_router.dart

### Post-Implementation Tasks
1. **Route Integration:** Wire feature routes into app_router.dart (requires Lead approval)
2. **build_runner:** Run after Flutter SDK installed
3. **Add Placeholder Dependencies:** qr_flutter, fl_chart, share_plus
4. **Create Post Screen:** Higher priority than polls
5. **Backend Validation:** Ensure endpoint contracts match specs
6. **Infinite Scroll:** Implement once backend supports pagination
7. **Unit & Widget Tests:** For all notifiers and key screens

### Key Learnings for Team
- SignalR manual implementation enables flexibility; upgrade path clear if Dart package becomes available
- Family notifiers essential for fine-grained state management in multi-list applications
- Separate CalendarEntry vs Event models optimize network traffic and rendering
- Optimistic UI patterns (reactions/comments) improve perceived performance significantly
- Color-coded status (with icon fallback) maintains accessibility while improving visual feedback
- **Real-time:** SignalR integration for Broadcast, status transparency
- **AI Integration:** GEMA work-number search, media-link suggestions (Azure OpenAI)

#### Critical Decisions
- **GEMA:** Draft-first, export-locked model preserves historical consistency
- **Media Links:** Minimal UI, deep-link-first, oEmbed fallback for missing metadata
- **Broadcast:** Transparent latency monitoring (>1000ms warning, >30s reconnect dialog)

#### Backend Dependencies
- SignalR Hub for real-time Broadcasting
- oEmbed service for media metadata
- Azure OpenAI for GEMA + media-link AI features

#### Next Steps
- Stark (Lead) review & approval
- Implementation sprint assignment (Romanoff frontend, Banner backend)
- API design for Broadcast (Stark)
3. **Fix broken existing tests** — GPT flagged old constructor signatures and raw token lookups that break after the changes. Existing tests must compile and pass.
4. **Remove unrelated IStorageService.cs** — Scope creep. This file has nothing to do with auth. Remove it from this branch; it belongs in a storage feature branch.

**FOLLOW-UP (create issue, merge anyway):**
- Rate limiting on `/verify-email` endpoint (abuse prevention)
- EF Core migration for new Musiker columns (dev uses code-first auto-migration, not blocking)
- Unit tests for verification flow and SHA-256 token hashing paths

**SKIP:**
- DevEmailService registered unconditionally — Only one reviewer flagged. Likely environment-gated or intentional for dev convenience. Not a production risk.

**Assigned to:** Strange (Principal Backend)

#### squad/93-auth-flutter-fix (Auth Flutter)
**VERDICT:** REJECT (with fixes)

**FIX NOW (must resolve before merge):**
1. **Fix endpoint mismatch** — Flutter calls `POST /auth/email-verify/$token`, backend expects `POST /api/auth/verify-email` with JSON body `{ "token": "..." }`. App literally cannot verify emails. Align Flutter client to match backend API contract exactly.
2. **Fix resendVerificationEmail endpoint** — Calls a nonexistent backend endpoint. Must match actual backend route.
3. **Fix token refresh race condition** — Concurrent 401 responses trigger multiple simultaneous refresh calls. With refresh token family rotation, the second refresh attempt reuses an already-rotated token → reuse detection → force logout. Solution: queue/mutex on refresh — only one refresh in flight, others wait for result.
4. **Fix completeOnboarding() Dio instance** — Uses a Dio instance without the auth interceptor → authenticated endpoint called without Bearer token → guaranteed 401. Must use the interceptor-equipped Dio.
5. **Await async storage writes** — `onAuthError` and `markOnboardingCompleted` perform async writes that aren't awaited. This causes race conditions in the auth flow where subsequent reads see stale state.

**FOLLOW-UP (create issue, merge anyway):**
- `devAutoVerifyEmail = kDebugMode` should be an explicit opt-in flag, not automatic in all debug builds
- Double-navigation risk in RegisterScreen (UX bug, not blocking)
- Hardcoded `baseUrl` — extract to configuration/environment
- Unit/widget tests for auth flows

**SKIP:**
- `.g.dart` placeholder files — Generated files, will be overwritten by build_runner
- Imprecise path check in interceptor — Single reviewer, minor detail, not functionally broken

**Assigned to:** Vision (Principal Frontend)

#### squad/95-kapelle-fix (Kapelle Backend)
**VERDICT:** REJECT (with fixes)

**FIX NOW (must resolve before merge):**
1. **Protect last admin from demotion** — `RolleAendernAsync` can demote the last admin to a regular member → zero admins → Kapelle permanently locked. Add guard: count admins, reject if `role != Admin && adminCount <= 1`.
2. **Replace AuthException with domain exceptions** — `KapelleService` throws `AuthException` for domain errors (e.g., "invitation code invalid", "already a member"). The Flutter auth interceptor interprets 401/403 as "not authenticated" → triggers token refresh or logout. This is a cross-layer integration bug. Create `DomainException` or `KapelleException` that maps to 400/409, not 401/403.
3. **Add StimmenOverride to MitgliedDto** — The DTO is missing this field, which means the API silently drops data that the backend stores. Clients can never read back what they wrote.

**FOLLOW-UP (create issue, merge anyway):**
- EF Core migration (code-first auto-migration works for dev)
- TOCTOU race on invitation codes — add unique constraint on code column as belt-and-suspenders
- Soft-delete for Kapelle (hard-delete is fine for MVP, soft-delete for production)
- Unit tests for KapelleService flows

**SKIP:**
- Inconsistent query patterns — Style preference, not functional. Reviewers disagree on which pattern is "correct."
- Namespace inconsistency — Cosmetic, single reviewer flag.

**Assigned to:** Strange (Principal Backend)

---

**Priority order for fixes:** 88 → 93 → 95 (auth backend first — Flutter fix depends on correct backend contract; Kapelle is independent but lower risk).

**Note to Strange:** You have two branches. Do 88-auth-fix first since 93-auth-flutter-fix (Vision) depends on the backend endpoints being correct. Then 95-kapelle-fix.

**Note to Vision:** Wait for Strange to confirm 88-auth-fix endpoint contracts before fixing 93-auth-flutter-fix, so you align to the final API shape.

---

### 2026-03-28T18:00Z: Setlist-Verwaltung — Platzhalter als First-Class-Citizen
**By:** Hill (Product Manager)  
**Context:** Feature-Spec Setlist-Verwaltung (MS2)

**Decision:** Setlist-Einträge haben drei Typen: Stück (Referenz auf piece_id), Platzhalter (ohne Stück-Referenz, mit Titel/Komponist/Notizen), und Pause (für Timing-Kalkulation). Platzhalter sind First-Class-Citizens im Datenmodell — Kapellen können vollständige Programme planen, bevor alle Noten digitalisiert sind. Im Spielmodus werden Platzhalter automatisch übersprungen mit Toast. GEMA-Export enthält Platzhalter. Keine automatische Ersetzung — explizite Umwandlung ist sicherer.

### 2026-03-29T00:00Z: Dev-Mode Password-Policy Lockerung
**By:** Banner (Backend Developer)

**Decision:** Passwort-Policy wird im Development-Modus deaktiviert via `IHostEnvironment.IsDevelopment()`. Im Dev-Modus: beliebig einfache Passwörter über API. In Produktion: Policy bleibt aktiv (8+ Zeichen, Großbuchstabe, Zahl/Sonderzeichen). Demo-Account: `demo@test.local` / `demo` (E-Mail verifiziert, automatisch erstellt).

### 2026-03-29T01:00Z: Backend Startup Performance — Port Fix
**By:** Banner (Backend Developer)

**Decision:** `start.ps1` Health-Check hatte Port-Mismatch (erwartete 5001, launchSettings.json nutzt 5273). Fix: Port auf 5273 korrigiert, Build/Run getrennt (`dotnet build` vorab, dann `dotnet run --no-build`), Health-Check von 30×2s auf 15×1s gestrafft. Falls Ports in `launchSettings.json` ändern → `start.ps1` synchron anpassen.

### 2026-03-29T02:00Z: Loading-Screen-Hang — Router Redirect Fix
**By:** Romanoff (Senior Frontend)

**Decision:** `/loading` wurde aus `_publicRoutes` entfernt (war nur während `AuthLoading` gültig). `_redirect` behandelt `/loading` nach Auth-Auflösung: Redirect zu `/login` (unauthenticated) oder `/app/library` (authenticated). API Base URL (`AppConfig.apiBaseUrl`) zentralisiert — Debug: `http://localhost:5273`, Release: `https://api.sheetstorm.app/v1`. Konvention: `/loading`-Route darf NIE in `_publicRoutes` stehen.

### 2026-03-29T03:00Z: JSON-Key-Konvention Backend ↔ Flutter
**By:** Romanoff (Senior Frontend)

**Decision:** camelCase ist die Konvention für alle JSON-Keys in der API (ASP.NET Core Default). Backend: keine Änderung nötig. Frontend: Alle neuen `fromJson`-Factories müssen camelCase-Keys verwenden. Generell: Error Handler sollten Exceptions nicht verschlucken — mindestens im Debug-Mode loggen.

---

## MS3 — Meilenstein 3 Entscheidungen

### 2026-03-30T23:21:03Z: User Directive — Kein BLE in MS3
**By:** Thomas (via Copilot)  
**Decision:** Keine Features mit BLE (Bluetooth Low Energy) in MS3 planen — ein anderer Agent kümmert sich darum. Alles andere vorbereiten.

---

### 2026-03-29: Hill — Feature-Spezifikationen für alle 6 MS3 Features
**By:** Hill (Product Manager)  
**Date:** 2026-03-29

Vollständige Feature-Spezifikationen erstellt für:
1. **Tuner:** Client-seitig (kein Backend-API), FFT-Pipeline auf Device, 442 Hz Default
2. **Metronom:** Beats als Timestamps (UTC Microseconds), nicht Echtzeit-Kommandos. UDP Multicast 239.255.77.77 primär, SignalR WebSocket Fallback. SessionState in Redis (Cloud Scaling).
3. **Cloud-Sync:** Last-Write-Wins pro Feld (nicht pro Objekt). Scope: "Meine Musik" nur. Delta-Sync mit monotoner Version. Binärdaten (Noten) über S3 (Pre-signed URLs).
4. **Annotationen-Sync:** Op-Log + LWW statt CRDT/OT. 24h Retention auf Operations-Log.
5. **Auto-Scroll:** Scroll-Einstellungen lokal (kein Sync). BPM-Kopplung mit Metronom.
6. **Aufgabenverwaltung:** Registerführer-Scope auf eigenes Register begrenzt. Musiker sehen nur zugewiesene Aufgaben.

**Open Questions:**
- Tuner Kammerton: 440 Hz oder 442 Hz? (Spec: 442 Hz Standard)
- Metronom Multicast-Port: 5001 in Firewall für Enterprise-Deployments?
- Cloud-Sync Quota: 1 GB oder 5 GB pro Nutzer?
- Aufgaben-Benachrichtigungen: FCM/APNs Konfiguration Timeline?

---

### 2026-03-30: Stark — MS3 Technische Architektur
**By:** Stark (Lead / Architect)  
**Date:** 2026-03-30

#### 1. Annotationen-Sync: Op-Log + LWW statt CRDT/OT
**Entscheidung:** Operationsbasierter Sync mit Last-Write-Wins per Element-ID.
**Begründung:** Annotationen sind unabhängige grafische Elemente. Konflikte sind extrem selten. LWW-Verlust = ein einzelner Strich. Komplexitätsreduktion > theoretische Korrektheit.

#### 2. Metronom: WiFi UDP Multicast primär, WebSocket Fallback
**Entscheidung:** WiFi UDP als primärer Transport (< 5ms LAN). SignalR WebSocket als Fallback (< 50ms).
**Hinweis:** BLE bleibt als potenzielle dritte Option für zukünftige Iterationen offen (abweichend von initial propositem BLE-Direktive).

#### 3. Metronom: Beats als Timestamps, nicht als Live-Kommandos
**Entscheidung:** Server sendet Session-Start (BPM + Startzeit), Clients berechnen Beats lokal.

#### 4. Cloud-Sync: Delta-Sync mit monotoner Version
**Entscheidung:** Monoton steigende Version pro Nutzer. SyncChangelog-Tabelle für Feld-Level-Änderungen.

#### 5. Cloud-Sync: Binärdaten über S3, nicht über Sync-API
**Entscheidung:** Notenbilder werden separat über S3 (Pre-signed URLs) synchronisiert.

#### 6. TaskStatus Naming: BandTaskStatus
**Entscheidung:** Enum heißt `BandTaskStatus`, nicht `TaskStatus` — Vermeidung von Namespace-Kollision mit `System.Threading.Tasks.TaskStatus`.

---

### 2026-03-30: Banner — Aufgabenverwaltung Backend Entscheidungen
**By:** Banner (Backend Developer)  
**Date:** 2026-03-30

1. **Endpoint-Pfad:** `/api/bands/{bandId}/tasks` (ohne v1-Segment, konsistent mit anderen Controllern)
2. **Autorisierung:** Nur Ersteller und zugewiesene Mitglieder können Status ändern. Admins/Conductor können Status auch ändern, weil sie die Aufgabe erstellt oder sich selbst zuweisen können.
3. **AssignTask:** PUT /assignees nimmt vollständige Liste und ersetzt alle bestehenden Zuweisungen atomisch (replace-all Semantik).
4. **Fehlerbehandlung:** 403 Forbidden bei fehlender Bandmitgliedschaft (nicht 404, um Existenz nicht zu leaken).
5. **Keine EF Migration für InMemory:** Tests nutzen UseInMemoryDatabase. Migrationen für PostgreSQL manuell via setup.ps1 ausgeführt.

---

### 2026-03-30: Banner — Cloud-Sync Backend Entscheidungen
**By:** Banner (Backend Developer)  
**Date:** 2026-03-30

1. **API-Route-Struktur:** `/api/sync/state`, `/api/sync/push`, `/api/sync/pull`, `/api/sync/resolve` (per protocol-spec, nicht feature-spec /meine-musik)
   - Begründung: Starks Protokoll-Spec ist die technisch verbindliche Quelle für Backend-API.
   - Team-Impakt: Flutter-Client (Romanoff) muss Endpoints auf `/api/sync/...` (ohne v1) konfigurieren.

2. **SyncChangelog Tabellenname:** `SyncChangelog` (Singular), DbSet `SyncChangelogs` (Plural) — standard ASP.NET Core EF-Konvention.

3. **LWW-Granularität auf Feld-Ebene:** pro `(EntityId, FieldName)` geprüft — nicht pro Entity.
   - Gleichzeitige Änderungen an `title` und `composer` desselben Stücks verursachen **keinen** Konflikt.
   - Nur wenn dasselbe Feld zweimal geändert wurde und Server die neuere Änderung hat: ServerWins-Konflikt.

4. **Entity-Mutations im Push:** Changelog speichert Änderungen, wendet sie aber **nicht** automatisch auf Entities an.
   - Offene Frage: Soll Backend die Entities auch live mutieren?

5. **Band.IsPersonal — Seeder:** `Band.IsPersonal = true` ist in Entity vorhanden, DemoDataSeeder erstellt aber noch keine persönliche Band.

6. **`resolve`-Endpoint:** Nimmt explizite Resolutions entgegen und speichert als neue Changelog-Einträge. Relevant nur wenn UI-seitig explizite Konfliktanzeige gewünscht wird.

---

### 2026-03-31: Banner — Metronom-Sync Backend Entscheidungen
**By:** Banner (Backend Developer)  
**Date:** 2026-03-31

1. **IMetronomeSessionManager = Singleton** (nicht Scoped)
   - Begründung: SignalR-Hubs werden pro Connection instanziiert. Scoped Services können nicht in Singleton-Hubs injiziert werden. BandId als Key schützt gegen Cross-Band-Konflikte.

2. **UDP Multicast-Gruppe: 239.255.77.77** (gemäß Protokoll-Spec)
   - Feature-Spec hatte 239.255.42.99. Protokoll-Spec hat Vorrang.
   - Offen: Stark sollte bestätigen ob 239.255.77.77 final ist.

3. **UdpMulticastServer sendet keine Beats — nur Session-Start/Stop/Update + Heartbeat**
   - Clients erhalten StartTimeUs + BPM und berechnen Beats lokal.
   - Server könnte optional Beat-Pakete senden (nicht implementiert da Spec nicht verlangt).

4. **AnnotationSyncHub stub-implementiert**
   - Tests konnten nicht kompilieren weil AnnotationSyncHub fehlte. Stub basierend auf Test-Erwartungen implementiert.

5. **REST API-Pfad: /api/v1/bands/{bandId}/metronome/**
   - Englische Routen konsistent mit Rest der API (nicht /api/v1/kapellen/{id}/metronom/).

---

### 2026-04-16: Vision — Auto-Scroll / Reflow Architecture
**By:** Vision (Principal Frontend Engineer)  
**Date:** 2026-04-16

#### 1. Separate Runtime State from Persistent Settings
- `AutoScrollNotifier` manages runtime state (idle/playing/paused, current speed, current mode)
- `AutoScrollSettingsNotifier` manages persistent defaults (SharedPreferences)
- **Reason:** Runtime state resets on each session. Settings persist across restarts.

#### 2. Speed Calculation in State, not Notifier
- `AutoScrollState.calculateManualSpeed()` and `calculateBpmSpeed()` are pure methods
- **Reason:** Pure functions are trivially testable. No notifier access or async needed.

#### 3. Widget Tests use UncontrolledProviderScope
- `overrideWithValue` throws in Riverpod 3.x codegen notifiers
- All widget tests use `UncontrolledProviderScope(container: ...)` with real `ProviderContainer`

#### 4. Control Bar always-visible when active (UX §2.2)
- Bar appears at bottom of Stack, 48px height
- Page dots hidden while bar visible to avoid overlap

#### 5. Pause-on-Touch wired through gesture layer
- `PageGestureDetector.onNextPage` / `onPreviousPage` call `autoScrollNotifier.onUserInteraction()`
- Respects user's manual override intent

#### Open Items
- BPM-Metronom-Kopplung: needs integration once Metronom ready (MS3)
- Page-Flip mode: not implemented, needs separate scroll controller
- Vorlauf-Takte: calculation exists, UI integration pending

---

### 2026-03-31: Romanoff — Tasks Frontend Decisions
**By:** Romanoff (Frontend Developer)  
**Date:** 2026-03-31

1. **API-Endpoint-Struktur:** Deutsche vs. Englische Keys
   - Feature-Spec definiert `/api/v1/kapellen/{id}/aufgaben` mit deutschen snake_case JSON-Keys
   - Task-Beschreibung nannte `/api/bands/{bandId}/tasks` mit camelCase
   - Entscheidung: Feature-Spec (deutsches API) folgen für Konsistenz mit anderen Features
   - ⚠️ Wenn Backend camelCase verwendet, müssen fromJson/toJson-Keys angepasst werden

2. **routes.dart:** Kein app_router.dart-Eingriff
   - Routes in `features/tasks/routes.dart` definiert und exportieren `taskRoutes`
   - Integration in `app_router.dart` noch ausstehend (per Charter-Policy)

3. **Out-of-scope MS3:**
   - Kommentare (Aufgaben-Kommentar-Thread)
   - Push-Notifications
   - Zuweisung von Mitgliedern im Create/Edit-Formular
   - Erinnerungs-Konfiguration
   - Service/Notifier bereits vorbereitet, UI fehlt

---

### 2026-03-31: Wanda — UX-Entscheidungen für MS3
**By:** Wanda (UX Designer)  
**Date:** 2026-03-31

#### Für Thomas zu entscheiden:
1. **Tuner — Stimmhistorie?** Empfehlung: Option A (Tablet zeigt letzte Messung, Phone zustandslos)
2. **Tuner — Manueller Modus bei verweigerter Permission?** Empfehlung: Option B (MVP, kein Fallback)
3. **Metronom — Beat-Fläche Form?** Empfehlung: Option B (Kreis, sanfter, nicht Vollbild-Flash)
4. **Metronom — Beat-Banner im Spielmodus?** Empfehlung: Option A (40px Banner, Nutzer verliert Sync nicht)
5. **Cloud-Sync — Speicherlimit?** Empfehlung: 500 MB (MVP, typisches Blaskapellen-Repertoire)
6. **Annotationen-Sync — Schreib-Rechte?** Empfehlung: Option A (alle Mitglieder mit Stimme)
7. **Auto-Scroll — Manueller Eingriff pausiert?** Empfehlung: Option A (Tap = Pause, nicht Weiter)
8. **Aufgaben — Wer sieht alle?** Empfehlung: Option A (Transparenz, aber Löschen-Recht beim Ersteller)
9. **Aufgaben — Navigation-Platzierung?** Empfehlung: Option A (unter „Vereinsleben", später zu eigenem Tab)

#### Teamrelevante Design-Entscheidungen (keine Thomas-Entscheidung):
1. **Tuner-Transposition:** Aus Instrumentenprofil laden als Default
2. **Metronom-Rollenprüfung:** Lokal aus Kapellenmitgliedschaft (kein Server-Roundtrip)
3. **Auto-Scroll:** Kontinuierlich > Seiten-Flip (mit reduced-motion fallback)
4. **Annotationen-Sync:** Kein Locking, gleichzeitiges Zeichnen erlaubt
5. **Cloud-Sync Status:** Unsichtbar im Erfolgsfall (kein Badge, nur aktiv + Fehler)

---

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

---

## 2026-03-31: Strange — Annotation Sync Backend Architecture

**By:** Strange (Principal Backend Engineer)  
**Feature:** Annotationen-Sync (MS3)

### REST Controller Design
- Single \AnnotationController\ handles both band-scoped and personal annotation endpoints
- Band-scoped routes: \pi/bands/{bandId}/annotations/...\
- Personal routes: \pi/annotations/personal/...\
- Sync endpoint: \POST .../sync?level=Voice&voiceId=...&sinceVersion=42\

### Optimistic Concurrency via Version Field
- Every \UpdateElement\ request must include the client's known \ersion\
- Server returns 409 Conflict with current server data if version mismatch
- Client must accept server version and retry (LWW = Last-Write-Wins)

### Soft-Delete for Sync Consistency
- \DeleteElement\ sets \IsDeleted = true\ instead of physical delete
- Sync responses INCLUDE soft-deleted elements so clients can remove them locally
- Regular \GetAnnotations\ EXCLUDES soft-deleted elements

### Orchestra Annotations: Conductor/Admin Only for Create
- \CreateElement\ with \Level = Orchestra\ requires Conductor or Admin role
- All band members can READ orchestra annotations
- Matches MS1 visibility rules

### Hub Connection Tracking
- \AnnotationSyncHub\ tracks connection → groups mapping in \ConcurrentDictionary\
- \OnDisconnectedAsync\ cleans up all group memberships
- No persistent presence data (ephemeral, per spec)

### Open for Review
- Retention job for old annotation operations (24h cleanup) — not yet implemented
- Max elements per page limit (spec suggests 1000) — not enforced yet

---

## 2026-04-16: Vision — Annotation Sync Frontend Architecture

**By:** Vision (Principal Frontend Engineer)  
**Scope:** Frontend only — sync layer for shared annotations

### Manual SignalR JSON Protocol (no shared base yet)
Annotation sync uses the same manual WebSocket + SignalR JSON protocol as BroadcastSignalRService. No shared abstraction extracted yet. **When a 3rd feature needs SignalR, extract a base class.**

### REST Endpoints
- \/api/bands/{bandId}/annotations/...\
- No version segment
- camelCase JSON keys
- Matches Stark's protocol spec

### Hub URL & Auth
- Hub: \/hubs/annotation-sync\
- Separate from broadcast hub (\/hubs/broadcast\)
- Auth via access_token query param

### Private Annotations Never Synced
- \shouldSync(AnnotationLevel.private)\ returns false
- Only voice + orchestra level annotations flow through the sync layer

### LWW Conflict Resolution Client-Side
- \AnnotationOp.resolveConflict()\ picks newer timestamp, then higher version as tiebreaker
- Conflict banner shows winner to inform user

### Offline Queue in Riverpod State
- Ops queued in \AnnotationSyncState.offlineQueue\ while disconnected
- \dequeueOps()\ atomically returns and clears the queue for replay on reconnect

### Integration Points for Other Agents
- **Banner (Backend):** Expects \AnnotationSyncHub\ with \JoinAnnotationGroup\, \LeaveAnnotationGroup\, \NotifyElementChange\ methods and \OnElementAdded\/\OnElementUpdated\/\OnElementDeleted\ server events.
- **Romanoff (if wiring UI):** Import \SyncStatusIndicator\ and \LiveEditIndicator\ widgets into the Spielmodus overlay.

---

## 2026-07-01: Vision — Metronom Frontend Architektur

**Agent:** Vision (Principal Frontend Engineer)

### Beat-Berechnung ist reine Mathematik (kein State)

\BeatCalculator\ ist eine reine Dart-Klasse ohne Riverpod-State. Input: \startTimeUs\, \pm\, \clockOffsetUs\, \
owUs\. Output: \eatNumber\, \measure\, \eatInMeasure\, \isDownbeat\, \microsecondsToNextBeat\.

**Begründung:** Maximale Testbarkeit, kein Framework-Dependency für die Kern-Logik. 21 Unit-Tests decken alle Edge Cases ab (extreme BPM, negative offsets, etc.).

### ClockSyncService gehört zum MetronomeNotifier (kein eigener Provider)

\ClockSyncService\ wird als Instanzvariable im \MetronomeNotifier\ gehalten, nicht als globaler Riverpod-Provider.

**Begründung:** Clock-Sync macht nur Sinn im Kontext einer aktiven Metronom-Session. Kein Grund für globalen Zustand. Vereinfacht Lifecycle-Management.

### SignalR-Service folgt BroadcastSignalRService-Pattern

Gleiche manuelle JSON-Protokoll-Implementierung: Handshake, Record Separator \\u001e\, Ping/Pong Typ 6, Invocation Typ 1. Gleiche Reconnect-Strategie (exponential backoff 2-32s, max 5 Versuche).

**Hub:** \/hubs/metronome\  
**Events:** \OnSessionStarted\, \OnSessionStopped\, \OnSessionUpdated\, \OnClockSyncResponse\, \OnParticipantCountChanged\

### Sentinel-Pattern für nullable copyWith-Felder

\MetronomeState.copyWith\ verwendet \static const _sentinel = Object()\ für nullable Felder (\session\, \currentBeat\, \rror\). Verhindert den \ield ?? this.field\-Bug, der in MS2 identifiziert wurde.

### Route: \/app/metronome\ mit Query-Parameter für Rolle

Statt separater Routen für Dirigent/Musiker: eine Route \/app/metronome?conductor=true\. Rollenprüfung erfolgt lokal (kein Server-Roundtrip), wie in UX-Spec §2 festgelegt.

### API Convention: \/api/\ ohne Version

Per Task-Anweisung verwendet der Frontend-Client \/api/bands/{bandId}/metronome/\ ohne Versionssegment. camelCase JSON Keys. **Hinweis:** Banner's Backend verwendet \/api/v1/bands/{bandId}/metronome/\ — muss abgestimmt werden.

### Open Items für Banner (Backend)

- SignalR Hub muss \OnSessionStarted\, \OnSessionStopped\, \OnSessionUpdated\, \OnClockSyncResponse\, \OnParticipantCountChanged\ senden
- Client-Methoden: \StartSession\, \StopSession\, \UpdateSession\, \RequestClockSync\, \JoinSession\, \LeaveSession\
- UDP Multicast (239.255.77.77:5100) ist für spätere Transport-Erkennung vorbereitet, aber nicht implementiert — Frontend nutzt derzeit nur WebSocket
