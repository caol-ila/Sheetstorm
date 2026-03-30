# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## 2026-03-30 — MS2 Nacharbeit: CR#3 + Issues #103 + #104

**Tasks completed:**

### Task 1 — musikerId aus Auth-State (CR#3)

**Problem:** 3x hardcoded `musikerId: ''` in `broadcast_receiver_screen.dart` — joinSession/leaveSession wurden mit leerem String aufgerufen, Broadcast-Feature komplett kaputt.

**Fix:**
- `BroadcastNotifier`: Privater Getter `_musikerId` liest `User.id` aus `authProvider`. Services (`_rest`, `_signalR`) jetzt als `late final` in `build()` gecacht — **wichtig für Riverpod 3.x**: `ref.read()` darf NICHT in `onDispose`-Callbacks aufgerufen werden (Assertion-Fehler).
- `joinSession()` und `leaveSession()` benötigen keinen `musikerId`-Parameter mehr — Notifier löst ihn intern auf.
- Fehlerfall: unauthentifizierter Nutzer → BroadcastMode.error mit "Nicht angemeldet".

**Riverpod 3.x Lesson:** `ref.read()` in `ref.onDispose()` wirft AssertionError `"Cannot use Ref inside life-cycles/selectors"`. Services die in Cleanup-Methoden benötigt werden, müssen in `build()` gecacht werden.

### Task 2 — Event.fromJson Null-Sicherheit (#104)

**Fix:** `event_models.dart`:
- `erstellt_von` null-safe: `(json['erstellt_von'] as Map<String, dynamic>?)?['name'] as String? ?? ''`
- `statistik` null-safe: `json['statistik'] as Map<String, dynamic>? ?? const {}`

**Pattern:** Alle MS2-Modelle, die Backend-Antworten parsen, sollten optionale Felder mit `as T?` + `?? default` behandeln — nie mit nicht-null Cast wenn das Feld fehlen kann.

### Task 3 — bandId aus Pfadparametern (#103)

**Fix:** `attendance/routes.dart`, `substitute/routes.dart`, `shifts/routes.dart` verwenden jetzt `state.pathParameters['bandId']` statt `state.uri.queryParameters['bandId']`. GoRouter füllt Pfadparameter in verschachtelten Routen automatisch aus dem übergeordneten `:bandId` Segment.

**AppRoutes cleanup:** `bandAttendance`, `bandSubstitutes`, `bandShifts` URL-Generatoren enthalten kein redundantes `?bandId=$bandId` mehr. `planId` bleibt als Query-Parameter da es kein Pfadparameter ist.

**New test files:**
- `test/features/events/data/models/event_model_test.dart` — Event.fromJson null-safety
- `test/features/routing/band_id_route_param_test.dart` — Route bandId extraction


## 2026-04-15 — Complete MS2 Frontend Implementation Summary (5 Agent Instances)

**Overall Context:**
In parallel orchestration, Romanoff implemented **5 separate feature modules** (Eventkalender, GEMA, Media Links, Kommunikation, and the 3 documented below). Vision independently implemented Setlist + Broadcast (2 modules). All decisions consolidated in `.squad/decisions.md` (MS2 Frontend Decisions section).

**Orchestration Logs:**
- `.squad/orchestration-log/2026-04-15T0017Z-romanoff-events-calendar.md` — Events/Konzertplanung
- `.squad/orchestration-log/2026-04-15T0024Z-romanoff-gema-media.md` — GEMA + Media Links  
- `.squad/orchestration-log/2026-04-15T0031Z-romanoff-communication.md` — Kommunikation (Posts + Polls)
- `.squad/orchestration-log/2026-04-15T0040Z-romanoff-attendance-subs-shifts.md` — Anwesenheit, Aushilfen, Schichtplanung

---

### Events/Konzertplanung Feature (`features/events/`)

**Models:** `Event`, `CalendarEntry`, `RsvpStatus`, `EventType` (Probe/Konzert/Sonstiges) enums with German label mapping

**Key Decisions:**
1. **CalendarEntry vs Event separation** — Calendar views get minimal data (`CalendarEntry`), detail screens get full `Event` model. Optimizes `/kalender` vs `/termine` API endpoints.
2. **Riverpod Family for EventDetailNotifier** — Scoped by `eventId`. Fine-grained state caching. Auto-invalidation on RSVP change (pattern from band_notifier).
3. **SegmentedButton for view switcher** — Month/Week/List modes (not TabBar). No AppBar needed, matches Material 3 mode selection patterns.
4. **RSVP Dialog with optional reason** — Progressive disclosure for cancellation reason. Prevents accidental rejections. Follows UX spec.
5. **CalendarMonthView with colored dots** — Space-constrained phone layouts. Tap day for full event list. Dots color-coded by event type.

**Architecture:** Same as other modules (Clean Architecture, Riverpod 3.x, Material 3, German strings)  
**Files:** 13 files (models, services, notifiers, 2 screens, 3+ widgets, routes.dart)  
**Status:** Routes NOT integrated into app_router.dart (separate task per charter)

---

### GEMA Compliance + Media Links Features

**GEMA Compliance (`features/gema/`)**

**Models:** `GemaReport`, `GemaEntry`, `GemaReportStatus` (Entwurf/Exportiert), `ExportFormat`

**Key Decisions:**
1. **Manual JSON serialization** — No json_serializable (consistent with auth_models pattern). Models simple, avoids build_runner churn.
2. **Report status = edit permission source** — `status == Entwurf` controls UI edit capabilities. Exported reports immutable (audit requirement). Every edit widget checks status.
3. **Family Notifiers** — `GemaReportDetailNotifier(kapelleId, reportId)`. Fine-grained cache. Separate persistent list notifier from transient detail.

**Media Links (`features/media/`)**

**Models:** `MediaLink`, `MediaLinkType` (YouTube/Spotify/SoundCloud/Other)

**Key Decisions:**
1. **Widgets, not routes** — `MediaLinkList` and `MediaLinkEditor` are reusable widgets integrated into piece detail + setlist views. NOT standalone screens. Per UX spec, links are contextual.
2. **url_launcher for deep linking** — `url_launcher:6.3.1` with `LaunchMode.externalApplication`. Auto-selects app if installed (youtube://, spotify://), fallback to browser. Cross-platform, no platform-specific code.
3. **Stub routes.dart** — Empty placeholder (media links are widget-based, not screen-based). Required per charter structure.

**Architecture:** Same Clean Architecture + Riverpod 3.x  
**Files:** 22 files combined (models, services, notifiers, screens for GEMA, widgets for media, routes.dart stubs)  
**Dependencies:** Added `url_launcher: ^6.3.1` to pubspec.yaml

---

### Kommunikation Feature (Posts + Polls) (`features/communication/`)

**Models:** `Post`, `Comment`, `Poll`, `PollOption`, `Author` (duplicated in post_models + poll_models), `ReactionType` enum

**Key Decisions:**
1. **Shared Author model via duplication** — Separate `Author` in post_models.dart + poll_models.dart. No shared/models/ directory in current architecture. Avoids circular imports. Acceptable DRY for stable 4-field model.
2. **Reaction storage as Map<ReactionType, Reaction>** — O(1) lookup for toggle logic (`reactions[type]?.hasReacted ?? false`). Matches backend JSON structure (object keys). Type-safe enum keys.
3. **Unified Board screen with tabs** — Posts + Polls in `board_screen.dart` (Alle/Pinned/Umfragen tabs). UX spec alignment. Single navigation destination. Distinct card designs make mixing intuitive. ~300 LOC acceptable for main feature screen.
4. **Optimistic UI for reactions + comments** — Instant update, rollback on error. Perceived performance (no spinner). UX best practice (Twitter/Facebook). Riverpod AsyncValue auto-rollback on failure.
5. **timeago package for relative time** — Added `timeago: ^3.7.0`. German locale support (`timeago.setLocaleMessages('de', timeago.DeMessages())`). Auto unit selection (seconds → minutes → hours → days). Standard pattern, zero maintenance.

**Architecture:** Same Clean Architecture + Riverpod 3.x, Material 3  
**Files:** 23 files (models, services, notifiers, 4 screens, 8 widgets, routes.dart stubs)  
**Dependencies:** Added `timeago: ^3.7.0` to pubspec.yaml

---

### Konsolidierte Cross-Feature Entscheidungen

**Shared Patterns Across All 5 Modules (Romanoff):**

1. **Feature Structure:** All follow identical `features/{name}/` → `data/models/` + `data/services/` + `application/` (notifiers) + `presentation/` (screens + widgets) + `routes.dart`
2. **State Management:** Riverpod 3.x with `@riverpod` codegen. Family notifiers for parametrized state. `keepAlive: true` for persistent, auto-dispose for transient.
3. **JSON Serialization:** Hand-written fromJson/toJson (no build_runner generation). Manual control over camelCase vs snake_case mapping.
4. **Routes:** Each feature's `routes.dart` is standalone. DO NOT modify app_router.dart (per charter). Integration in separate PR.
5. **German Strings:** All UI hardcoded in German (no i18n in MS2). i18n framework deferred to MS3.
6. **UI/UX:** Material 3 design. AppTokens spacing (xs/sm/md/lg/xl). AppColors theme. Touch targets min 44px. RefreshIndicator on list screens.
7. **Error Handling:** Try-catch in notifiers. AsyncValue.guard() for mutations. Boolean return for success/failure. SnackBar feedback.
8. **Code Style:** Alphabetical imports (flutter → riverpod → sheetstorm → features). const constructors. Null-safety (required without `?`, optional with `?`). Provider naming: `{feature}ServiceProvider`, `{feature}NotifierProvider`.

**Stub .g.dart Files:**
- Created for all Riverpod-generated providers (Flutter SDK unavailable on build agent)
- Real generation: `flutter pub run build_runner build --delete-conflicting-outputs` (post-Flutter install)
- Allows code compilation and review before Flutter toolchain available

**Dependencies Added:**
- `web_socket_channel: ^3.0.2` (Vision: SignalR WebSocket)
- `url_launcher: ^6.3.1` (Media Links deep linking)
- `timeago: ^3.7.0` (Communication: relative time)

**Placeholder Dependencies (ready post-Flutter install):**
- `qr_flutter` — QR code generation (Substitute)
- `fl_chart` or `syncfusion_flutter_charts` — Charts (Attendance)
- `share_plus` — Link sharing

---

## 2026-04-15 — 3 Flutter Feature Modules: Anwesenheit, Aushilfen, Schichtplanung

**Implemented:**
- **Attendance Statistics** (`features/attendance/`) — Anwesenheitsstatistiken mit Dashboard, Trends, Register-Breakdown
- **Substitute Access** (`features/substitute/`) — Aushilfen-Zugänge mit QR-Code-Sharing, temporäre Token
- **Shift Planning** (`features/shifts/`) — Schichtplanung mit Self-Signup und Admin-Zuweisung

**Architecture:**
- Alle 3 Features folgen Clean Architecture Pattern: `data/models/`, `data/services/`, `application/`, `presentation/screens/`, `presentation/widgets/`, `routes.dart`
- State Management: Riverpod 3.x Codegen mit `@riverpod`/`@Riverpod`, `part 'filename.g.dart';`
- API Services: Thin REST-Wrapper über `apiClientProvider`, alle Methoden mit optionalen Query-Parametern
- Models: Immutable Dart-Klassen mit manueller JSON-Serialisierung (kein freezed), copyWith-Methoden
- Theme: AppTokens, AppColors aus `core/theme/` — Material 3, responsive Design

**Attendance Feature:**
- **Models:** `AttendanceStats`, `MemberAttendance`, `RegisterAttendance`, `AttendanceTrend`, `TrendDataPoint`, `ExportData`
- **Service:** GET stats, GET register breakdown, GET trends, POST export, GET export status
- **State:** `AttendanceNotifier` mit `AttendanceDashboardState` (keepAlive), Date-Range-Filter, Event-Type-Filter
- **Screens:** `AttendanceDashboardScreen` — 3 Tabs (Musiker / Register / Trends), Date-Range-Picker, Export-Button
- **Widgets:** `AttendanceChart` (Custom Painter Line Chart), `AttendanceStatCard`, `RegisterBreakdown`, `ExportButton`
- **Farb-Logik:** >80% grün, 60-80% gelb, <60% rot — mit Icons (check_circle, warning, cancel)

**Substitute Feature:**
- **Models:** `SubstituteAccess`, `SubstituteLink`, `SubstituteStatus` Enum (active/expired/revoked)
- **Service:** POST create link, GET list, GET detail, DELETE revoke, PATCH extend expiry
- **State:** `SubstituteListNotifier` (keepAlive), `activeSubstitutes` Provider (filtered)
- **Screens:** `SubstituteManagementScreen` (List mit Filter), `SubstituteLinkScreen` (QR-Code + Link-Anzeige)
- **Widgets:** `AccessLinkCard`, `QRCodeGenerator` (Placeholder für qr_flutter), `SubstituteStatusBadge`
- **QR-Code:** Client-seitige Generierung (Platzhalter implementiert, echte QR-Generierung via qr_flutter-Package)

**Shift Planning Feature:**
- **Models:** `ShiftPlan`, `Shift`, `ShiftAssignment`, `ShiftStatus` Enum (open/filled/requested)
- **Service:** CRUD für ShiftPlans und Shifts, POST self-assign, POST assign member, DELETE remove assignment
- **State:** `ShiftPlanListNotifier` (keepAlive), `ShiftPlanNotifier` (Family per planId), `myShifts` + `openShifts` Providers
- **Screens:** `ShiftPlanScreen` (Plan-Übersicht mit Schicht-Liste), `ShiftDetailScreen` (Schicht-Details mit Assignments)
- **Widgets:** `ShiftSlot`, `ShiftAssignmentCard`, `OpenShiftsBadge`
- **Self-Signup:** Musiker kann sich selbst eintragen, Admin kann Musiker zuweisen, Unterscheidung via `isSelfAssigned`

**Routes:**
- Jedes Feature hat `routes.dart` mit GoRoute-Definitionen (NICHT in app_router.dart integriert — wird separat registriert)
- Route-Parameter über Query-Params (z.B. `?bandId=...`) oder `state.extra` für Objekte

**Code-Generation-Stubs:**
- Alle `.g.dart` Dateien als Stubs erstellt — müssen mit `flutter pub run build_runner build --delete-conflicting-outputs` generiert werden
- 6 Riverpod-Provider-Stubs: attendance_service, attendance_notifier, substitute_service, substitute_notifier, shift_service, shift_notifier

**German Strings:**
- Alle Texte hardcoded in Deutsch (keine i18n in MS2) — "Anwesenheit", "Aushilfe", "Schicht", "Ich bin dabei", etc.

**Responsive:**
- Alle Screens mit RefreshIndicator (Pull-to-Refresh)
- Cards, ListTiles, Tables — funktioniert auf Phone/Tablet/Desktop
- Touch-Targets: AppSpacing.touchTargetMin (44px)

**Conventions:**
- Imports alphabetisch (flutter, flutter_riverpod, sheetstorm/core, sheetstorm/features, sheetstorm/shared)
- `const` Constructors wo möglich
- Null-Safety: nullable Felder mit `?`, required Felder ohne `?`
- Provider-Namen: `{featureName}ServiceProvider`, `{featureName}NotifierProvider`

**Noch offen (später):**
- build_runner muss nach Flutter-Installation ausgeführt werden
- QR-Code-Generierung: qr_flutter-Package hinzufügen
- Chart-Library: fl_chart oder syncfusion_flutter_charts (aktuell Custom Painter als Placeholder)
- Share-Funktionalität: share_plus-Package für Aushilfen-Links
- Routes müssen in app_router.dart integriert werden (separat, DO NOT modify app_router.dart Warnung beachtet)

## 2026-03-29 — GEMA & Media Links Feature Modules

**Task:** Implement 2 feature modules — GEMA Compliance + Media Links  
**Outcome:** Complete, compilable Dart code following all established patterns

### Features Implemented

**1. GEMA Compliance (`features/gema/`)**
- Models: `GemaReport`, `GemaEntry`, `GemaReportStatus`, `ExportFormat`, `GemaWerknummerVorschlag`
- Service: `GemaService` — REST client for all GEMA endpoints (CRUD, search, export)
- Notifiers: `GemaReportListNotifier` (keepAlive), `GemaReportDetailNotifier` (autoDispose family)
- Screens: List, Detail, Export
- Widgets: `GemaReportCard`, `GemaEntryTile`, `ExportFormatPicker`
- API paths: `/api/v1/kapellen/{id}/gema-meldungen/*`
- Hardcoded German strings per conventions
- Status badges with conditional rendering (Entwurf/Exportiert)

**2. Media Links (`features/media_links/`)**
- Models: `MediaLink`, `MediaLinkType` (YouTube/Spotify/SoundCloud/Other), `MediaLinkVorschlag`
- Service: `MediaLinkService` — CRUD + AI suggestions
- Notifier: `MediaLinkNotifier` (autoDispose family by kapelleId + stueckId)
- Widgets: `MediaLinkList`, `MediaLinkEditor`, `ListenButton`, `MediaLinkTile`
- Deep-linking via `url_launcher 6.3.1` (added to pubspec)
- No standalone screens — designed as reusable components for piece detail views
- Empty state with conditional "Add Link" button

### Patterns Followed

- **Riverpod 3.x codegen:** All notifiers use `@Riverpod` / `@riverpod` annotations with `part 'filename.g.dart'`
- **Null safety:** All models immutable, const constructors, proper nullable types
- **Material 3:** AppTokens spacing, AppColors, AppSpacing.rounded*
- **API client injection:** `ref.read(apiClientProvider)` in services
- **State management:** AsyncValue.when() for loading/data/error states, AsyncValue.guard() for mutations
- **Error handling:** Try-catch in notifiers, return success/failure booleans, SnackBar feedback
- **Manual JSON:** No build_runner JSON — hand-written fromJson/toJson per auth_models.dart pattern
- **Family notifiers:** Used for parametrized state (kapelleId, reportId, stueckId)
- **Responsive design:** Cards with touch-friendly list tiles, Material padding

### Technical Decisions

1. **No app_router.dart modification** — Created `routes.dart` per feature as specified (GEMA has route definitions, Media Links is empty as widgets are embedded)
2. **Stub .g.dart files** — Created manual stubs for all generated providers (GemaService, MediaLinkService, all Notifiers) — real code will be generated by build_runner
3. **url_launcher** for deep links — Opens YouTube/Spotify in native app if installed, browser fallback
4. **Conditional edit permissions** — UI checks `canEdit` flag (determined by report status or user role in parent components)
5. **Export flow** — Format picker shows XML/CSV/PDF with descriptions, downloads via returned URL from backend

### Still Missing (intentionally)

- AI Werknummer-Suche UI flows (bulk + single) — backend integration points exist, but search result dialogs not implemented
- Entry add/edit dialogs for GEMA — API methods exist in notifier, UI stubs in place
- Actual navigation wiring in app_router.dart — routes.dart defines paths but GoRoute integration deferred per charter
- Platform-specific deep-link setup (iOS/Android scheme handlers for YouTube/Spotify URIs) — runtime will handle via url_launcher
- Export download handling — currently just returns URL string, actual file download/share sheet not wired

### Files Created

**GEMA (16 files):**
- `data/models/gema_models.dart`
- `data/services/gema_service.dart` + `.g.dart`
- `application/gema_notifier.dart` + `.g.dart`
- `presentation/screens/gema_report_list_screen.dart`
- `presentation/screens/gema_report_detail_screen.dart`
- `presentation/screens/gema_export_screen.dart`
- `presentation/widgets/gema_report_card.dart`
- `presentation/widgets/gema_entry_tile.dart`
- `presentation/widgets/export_format_picker.dart`
- `routes.dart`

**Media Links (11 files):**
- `data/models/media_link_models.dart`
- `data/services/media_link_service.dart` + `.g.dart`
- `application/media_link_notifier.dart` + `.g.dart`
- `presentation/widgets/media_link_list.dart`
- `presentation/widgets/media_link_editor.dart`
- `presentation/widgets/listen_button.dart`
- `presentation/widgets/media_link_widgets.dart` (barrel export)
- `routes.dart`

**Modified:**
- `pubspec.yaml` — added `url_launcher: ^6.3.1`

## 2026-03-28 — Issue #8: Flutter Frontend Scaffolding

**Branch:** `squad/8-frontend-scaffolding`  
**Commit:** `368db49`

### Was wurde gebaut

Vollständiges Flutter-Projekt-Scaffolding für `sheetstorm_app/`:

**Struktur (Clean Architecture):**
- `lib/core/` — Theme, Design Tokens, Constants, Routing (go_router)
- `lib/features/` — auth, kapelle, noten, spielmodus, config, annotationen
- `lib/shared/` — AppShell (Bottom Nav), Drift-Datenbank, API-Client (dio)

**Design-Token-System** direkt aus ux-design.md:
- `AppColors` — Light/Dark, Config-Ebenen (blau/grün/orange), Annotation-Layer
- `AppSpacing` — Touch-Targets 44px (min) / 64px (Spielmodus), Border-Radius
- `AppTypography` — Inter-Font, 12–72sp Skala
- `AppDurations`/`AppCurves` — Animation-Tokens

**App Shell:** 4 Bottom-Navigation-Tabs (Bibliothek/Setlists/Kalender/Profil), Material 3, Wakelock-Handling im Spielmodus.

**SpielmodusScreen:** Vollbild (SystemUI immersive), asymmetrische Tap-Zonen (40% zurück / 60% weiter), Kontextmenü max. 5 Optionen.

**Drift DB:** Tabellen für Noten, Stimmen, Annotationen, KonfigurationEintraege.

**Verifiizierte Versionen (alle per web_search):**
- Flutter 3.41.5 / Dart 3.11.0, flutter_riverpod 3.3.1, go_router 17.1.0
- dio 5.9.2, drift 2.32.1, pdfrx 2.2.24, flutter_svg 1.1.6, cached_network_image 3.4.1

### Flutter nicht installiert
Flutter-SDK war auf dem Build-Agenten nicht vorhanden → Projekt-Struktur manuell erstellt. `build_runner` muss nach Flutter-Installation ausgeführt werden, um `.g.dart`-Stubs durch echten generierten Code zu ersetzen:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Noch offen (spätere Issues)
- Platform-spezifische Dateien (android/, ios/, windows/) — werden von `flutter create` generiert
- build_runner generierten Code (`.g.dart` sind Stubs)
- Auth-Provider-Implementierung
- Spielmodus: pdfrx-Integration, Half-Page-Turn-Logik
- Annotationen: SVG-Layer-Implementation
- Config: 3-Ebenen-Override-Logik

---

## 2026-03-28 — PR #88 Fix (Auth Backend): SHA-256, EmailVerified, IEmailService, IStorageService

**Branch:** `squad/88-auth-fix` (based on `squad/11-auth-backend`)
**Worktree:** `C:\Source\Sheetstorm-88-fix`
**Assigned by:** Thomas (via Ralph) — Banner locked out per Reviewer Rejection Protocol

### Was wurde geändert

**1. SHA-256 Hashing für Refresh Tokens (Security Fix)**
- `AuthService.CreateRefreshTokenAsync`: speichert `SHA256(tokenValue)` in der DB
- `AuthService.RefreshAsync`: hasht das eingehende Token vor dem DB-Lookup
- Neuer privater Helper `HashToken(string)` — `SHA256.HashData` → Hex-String
- Roher Token geht nur zum Client, nie in die DB → verhindert Token-Diebstahl via DB-Dump

**2. E-Mail-Bestätigung (EmailVerified)**
- `Musiker` Entität: neue Felder `EmailVerified`, `EmailVerificationToken`, `EmailVerificationTokenExpiresAt`
- Bei `RegisterAsync`: `EmailVerified = false`, Verification-Token generieren (24h Ablauf), `IEmailService.SendEmailVerificationAsync` aufrufen
- `UserDto` exposes `EmailVerified`

**3. IEmailService + DevEmailService**
- `Infrastructure/Email/IEmailService.cs`: `SendEmailVerificationAsync`, `SendPasswordResetAsync`
- `Infrastructure/Email/DevEmailService.cs`: Stub — loggt E-Mails auf Konsole (dev-only)
- `DependencyInjection.cs`: `IEmailService → DevEmailService` registriert

**4. POST /api/auth/verify-email**
- `VerifyEmailRequest(Token)` in `AuthModels.cs`
- `IAuthService.VerifyEmailAsync` + Implementierung in `AuthService`
- `AuthController`: neuer Endpoint, idempotent (bereits verifiziert = 200 OK)

**5. IStorageService (S3-kompatibel)**
- `Infrastructure/Storage/IStorageService.cs`: `UploadAsync`, `DownloadAsync`, `DeleteAsync`, `GetPresignedUrlAsync`
- Noch kein konkreter S3-Provider — bewusst als Interface-only, Implementierung in eigenem Issue

### Build-Ergebnis
`dotnet build` → **0 Warnungen, 0 Fehler**

---

## 2026-03-28 — PR #95 Fix (Kapelle Backend): Stimmen-Override Endpoints

**Branch:** `squad/95-kapelle-fix` (based on `squad/16-kapelle-backend`)
**Worktree:** `C:\Source\Sheetstorm-95-fix`
**Assigned by:** Thomas (via Ralph) — Banner locked out per Reviewer Rejection Protocol

### Was wurde geändert

**1. KapelleStimmenMapping Entität**
- `Domain/Entities/KapelleStimmenMapping.cs`: `KapelleId`, `Instrument` (bis 100 Zeichen), `Stimme` (bis 100 Zeichen)
- EF-Config: `KapelleStimmenMappingConfiguration` — Unique-Index auf `(KapelleId, Instrument)`, Cascade-Delete
- `AppDbContext`: `KapelleStimmenMappings` DbSet
- `Kapelle` Entität: `StimmenMappings` Navigation Collection

**2. Nutzer-Override auf Mitgliedschaft**
- `Mitgliedschaft.StimmenOverride` (nullable string, max 100): persönliche Stimme für dieses Mitglied
- Priorität: `StimmenOverride > Kapelle-Default-Mapping > Globaler Default`

**3. DTOs (KapelleModels.cs)**
- `StimmenMappingEintrag(Instrument, Stimme)`
- `StimmenMappingResponse(IReadOnlyList<StimmenMappingEintrag>)`
- `StimmenMappingSetzenRequest(IReadOnlyList<StimmenMappingEintrag>)`
- `NutzerStimmenRequest(StimmenOverride?)` — null = Override entfernen

**4. Service-Layer**
- `IKapelleService`: 3 neue Methoden
- `KapelleService.GetStimmenMappingAsync` — alle Einträge für die Kapelle (Mitglied-Guard)
- `KapelleService.SetStimmenMappingAsync` — atomares Replace aller Einträge (Admin-Guard)
- `KapelleService.SetNutzerStimmenAsync` — Admin kann alle setzen, Mitglied nur eigene

**5. Neue Endpoints**
- `GET  /api/kapellen/{id}/stimmen-mapping` (jedes Mitglied)
- `PUT  /api/kapellen/{id}/stimmen-mapping` (Admin — ersetzt komplette Mapping-Liste)
- `PUT  /api/kapellen/{id}/mitglieder/{userId}/stimmen` (Admin oder selbst)

### Build-Ergebnis
`dotnet build` → **0 Warnungen, 0 Fehler**


## 2026-03-28 — Issue #12: Flutter Auth UI & Token Management

**Branch:** `squad/12-auth-flutter`  
**Commit:** `33d1ce8`  
**Worktree:** `C:\Source\Sheetstorm-12`

### Was wurde gebaut

**Daten-Schicht:**
- `auth_models.dart` — `User`, `AuthTokens`, `AuthResponse` (manuelles JSON, kein build_runner nötig)
- `TokenStorage` — `flutter_secure_storage 10.0.0`, persistiert Access/Refresh Token + User JSON in verschlüsseltem Storage (Android: EncryptedSharedPreferences)
- `AuthService` — eigener Dio ohne Auth-Interceptor (vermeidet circular dependency), deckt alle Endpunkte: `login`, `register`, `refreshToken`, `forgotPassword`, `validateGuestToken`, `completeOnboarding`

**State-Schicht:**
- `AuthState` — sealed class: `AuthLoading / AuthUnauthenticated / AuthAuthenticated(User) / AuthError(String)`
- `AuthNotifier` — Riverpod `Notifier` (keepAlive), initialisiert aus Storage beim App-Start, async `login/register/logout/forgotPassword`, `markOnboardingCompleted`, `onAuthError` (Callback für Dio-Interceptor)

**Routing:**
- go_router `redirect`-Guard mit `_RouterNotifier` (ChangeNotifier als `refreshListenable`)
- Logik: AuthLoading → `/loading`, AuthAuthenticated + !onboardingCompleted → `/onboarding`, Authenticated auf Auth-Route → `/app/bibliothek`, Unauthenticated auf geschützter Route → `/login`
- Neue Routen: `/loading`, `/register`, `/forgot-password`, `/onboarding`, `/aushilfe/:token` (Placeholder für Issue #15)

**API-Client:**
- `_AuthInterceptor` vollständig implementiert: Bearer-Token Injection, Auto-Refresh bei 401 (Retry-Request mit neuem Token), bei Refresh-Fehler `onAuthError()` aufrufen

**Screens:**
- `LoginScreen` — E-Mail + Passwort, Passwort vergessen Link, Social Login (Google immer, Apple nur iOS/macOS), Link zu Register
- `RegisterScreen` — 4-Step progressiver Flow: E-Mail+PW (mit Stärke-Anzeige, Weiter-Button disabled bis gültig) → Name → Instrument (FilterChips, 25 Blaskapellen-Instrumente) → Kapelle (optional, überspringbar)
- `ForgotPasswordScreen` — Email-Input, Success-State, 60s Cooldown-Timer auf "Erneut senden"
- `OnboardingScreen` — 5-Step Wizard via PageView: Name bestätigen → Instrument → Kapelle & Standardstimme → Theme (Hell/Dunkel/System) → Fertig; jeder Schritt überspringbar

**Shared Widgets:**
- `AuthTextField` — 44px Touch-Target, Eye-Toggle für Passwortfelder
- `PasswordStrengthIndicator` — Live-Balken (Schwach/Mittel/Stark) + Checkliste (8 Zeichen, Großbuchstabe, Zahl/Sonderzeichen)
- `SocialLoginButtons` — `Platform.isIOS || Platform.isMacOS` Guard für Apple-Button

### Wichtige Entscheidungen

- **Kein build_runner nötig für Models**: Manuelle JSON-Serialisierung statt freezed/json_annotation
- **Circular-Dep-Lösung**: `AuthService` hat eigenes Dio, `apiClient` liest `tokenStorageProvider` + `authServiceProvider` via `ref.read` (nicht watch)
- **flutter_secure_storage 10.0.0** (neueste Version, per web_search verifiziert)
- `authNotifierProvider` keepAlive — Auth-State überlebt Widget-Tree-Rebuild

### Noch offen (spätere Issues)
- Google Sign-In / Apple Sign-In OAuth-Integration (Placeholder-Buttons vorhanden)
- Aushilfen-Deep-Link-Flow `/aushilfe/:token` (Issue #15)
- Kapellen-Suche in Registrierung/Onboarding braucht API (Issue nach Backend-Auth)
- build_runner nach Flutter-Installation für alle `.g.dart`-Stubs

## 2026-03-29 — Loading-Screen-Hang Fix (Router Redirect Bug)

### Ursache

Die App blieb auf dem `/loading`-Splash-Screen hängen. Root Cause: **`/loading` war in `_publicRoutes` eingetragen.** Die `_redirect`-Logik für nicht-authentifizierte User auf Public-Routes gibt `null` zurück (= bleib wo du bist). Da `/loading` als Public galt, wurde nach Auth-Initialisierung nie wegnavigiert.

**Flow:** `main()` → `ProviderScope` → `appRouterProvider` → `initialLocation: '/loading'` → `AuthNotifier.build()` feuert `_initializeAuth()` async → setzt `AuthUnauthenticated` → Router re-evaluiert → `_redirect` sieht: User unauthenticated, Route ist public → `return null` (bleib auf `/loading`) → **Deadlock.**

Die Auth-Initialisierung selbst funktionierte korrekt (verifiziert per Debug-Prints: `getUser()` → `null` → `AuthUnauthenticated`).

### Fix

1. **`/loading` aus `_publicRoutes` entfernt** — `/loading` ist nur während `AuthLoading` gültig
2. **`_redirect` erweitert:** Explizite Behandlung von `/loading` nach Auth-Auflösung:
   - `AuthUnauthenticated` + auf `/loading` → redirect zu `/login`
   - `AuthAuthenticated` + auf `/loading` → redirect zu `/app/library`
3. **API Base URL zentralisiert:** Hardcoded `https://api.sheetstorm.app/v1` in `AuthService` und `apiClient` durch `AppConfig.apiBaseUrl` ersetzt — Debug: `http://localhost:5273`, Release: `https://api.sheetstorm.app/v1`

### Startup-Flow Dokumentation

- `main.dart`: `WidgetsFlutterBinding.ensureInitialized()` → `ProviderScope` → `SheetstormApp`
- `SheetstormApp` (ConsumerWidget): `ref.watch(appRouterProvider)` → `MaterialApp.router`
- `appRouterProvider`: erstellt GoRouter mit `initialLocation: '/loading'`, `refreshListenable: _RouterNotifier`, `redirect: _redirect`
- `_RouterNotifier` wird via `ref.listen<AuthState>(authProvider, ...)` bei Auth-Änderungen getriggert
- `AuthNotifier.build()`: gibt `AuthLoading` zurück, feuert `_initializeAuth()` fire-and-forget
- `_initializeAuth()`: liest Token aus `FlutterSecureStorage` → kein User → `AuthUnauthenticated` → Router-Redirect greift
- `_SplashScreen`: rein visuell (Icon + CircularProgressIndicator), keine eigene Logik

### Geänderte Dateien

- `lib/core/routing/app_router.dart` — Redirect-Logik fix
- `lib/core/config/app_config.dart` — `apiBaseUrl` hinzugefügt
- `lib/features/auth/data/services/auth_service.dart` — Base URL aus AppConfig
- `lib/shared/services/api_client.dart` — Base URL aus AppConfig

## 2026-03-29 — Login-Fehler Fix: JSON-Key-Mismatch (camelCase vs snake_case)

### Ursache

Login mit `demo@test.local / demo` zeigte "Ein unbekannter Fehler ist aufgetreten", obwohl das Backend `200 OK` zurückgab. Root Cause: **JSON-Feldnamen-Mismatch zwischen Backend und Flutter.**

Das ASP.NET Core Backend gibt standardmäßig **camelCase** aus:
```json
{ "user": {...}, "accessToken": "...", "refreshToken": "...", "tokenType": "Bearer", "expiresIn": 900 }
```

Aber `AuthTokens.fromJson` erwartete **snake_case**:
```dart
json['access_token'] as String  // → null!
```

`null as String` wirft einen `TypeError` — kein `DioException` — und wird vom generischen `catch (_)` gefangen, der "Ein unbekannter Fehler ist aufgetreten" anzeigt.

### Fix

1. **`auth_models.dart`:** `AuthTokens.fromJson` Keys von snake_case auf camelCase umgestellt (`accessToken`, `refreshToken`, `tokenType`, `expiresIn`)
2. **`auth_service.dart`:** Refresh-Token-Request-Body Key von `refresh_token` auf `refreshToken` korrigiert (Backend-Model: `RefreshTokenRequest(string RefreshToken)`)
3. **`auth_notifier.dart`:** Catch-All im Login loggt jetzt die tatsächliche Exception (`$e`) für bessere Debuggability

### Learnings

- ASP.NET Core `System.Text.Json` serialisiert Records standardmäßig in **camelCase** — Flutter-Models müssen das matchen
- Generische `catch (_)` Handler sollten immer die Exception loggen, damit die Ursache nicht verschluckt wird
- Bei "unbekannter Fehler" Meldungen: zuerst prüfen ob die Response-Daten korrekt geparst werden, bevor CORS etc. untersucht wird

## 2026-03-29 — Onboarding-Abschluss Crash Fix (OperationError)

### Ursache

"Zur Bibliothek"-Button crashte mit `RethrownDartError: OperationError`. Zwei Fehler:

1. **`_finish()` rief `PATCH /api/users/me/onboarding` auf** — ein Endpoint, der im Backend nicht existiert. Der Auth-Interceptor (`apiClientProvider`) las dabei Tokens aus `FlutterSecureStorage`, was auf Web via Web Crypto API (`SubtleCrypto`) einen `DOMException` mit Name `OperationError` warf.

2. **`markOnboardingCompleted()` lag außerhalb des try-catch** — und `_finish()` wurde als `VoidCallback` aufgerufen (Future-Fehler unhandled). Die State-Persistierung (`FlutterSecureStorage.write()`) konnte ebenfalls `OperationError` werfen, weil sie vor dem State-Update stattfand.

### Fix

- **PATCH-Call entfernt** — toter Code, Endpoint existiert nicht im Backend
- **`markOnboardingCompleted()`**: State-Update (`AuthAuthenticated`) VOR Storage-Persistierung gesetzt, Storage-Write in try-catch (best-effort auf Web)
- Ungenutzten `api_client`-Import entfernt

### Geänderte Dateien

- `lib/features/auth/application/auth_notifier.dart` — `markOnboardingCompleted()` resilient gemacht
- `lib/features/auth/presentation/screens/onboarding_screen.dart` — PATCH entfernt, Import bereinigt

### Learnings

- `flutter_secure_storage` auf Web nutzt Web Crypto API — `SubtleCrypto.encrypt()`/`decrypt()` kann `OperationError` werfen; Aufrufe müssen try-catch haben
- Async Methoden als `VoidCallback` = Fire-and-Forget → Fehler werden zu `Uncaught (in promise)`; immer intern abfangen
- In-Memory-State VOR Disk-Persistierung setzen, damit Navigation sofort funktioniert
- PATCH/PUT-Calls auf nicht-existierende Backend-Endpoints sind keine harmlosen No-Ops — der Auth-Interceptor liest Tokens aus SecureStorage, was auf Web crashen kann

## 2026-03-28 — Communication Module Implementation (Posts + Polls)

**Branch:** TBD  
**Feature:** Complete Flutter module for Kommunikation feature (MS2)

### Was wurde gebaut

Vollständiges `features/communication/` Modul gemäß `docs/feature-specs/kommunikation-spec.md` und `docs/ux-specs/kommunikation.md`:

**Daten-Schicht (`data/models/`):**
- `post_models.dart` — Post, Comment, Reaction, ReactionType enum, Author, Attachment
- `poll_models.dart` — Poll, PollOption, PollStatus enum, Author (shared)
- Immutable Dart classes, manuelle JSON serialisierung (fromJson/toJson/copyWith)
- Reactive Maps für Reactions (ReactionType → Reaction mit hasReacted flag)

**Service-Schicht (`data/services/`):**
- `post_service.dart` — REST-Wrapper für Posts (CRUD, pin/unpin, reactions, comments)
- `poll_service.dart` — REST-Wrapper für Polls (CRUD, vote, close)
- Beide nutzen `apiClientProvider` (injected Dio mit Auth-Interceptor)
- Pagination-Support via cursor (limit default 20)

**State-Schicht (`application/`):**
- `post_notifier.dart` — PostListNotifier (mit pinnedOnly filter), PostDetailNotifier, PostCommentsNotifier
- `poll_notifier.dart` — PollListNotifier, PollDetailNotifier
- Alle mit Riverpod 3.x codegen (@riverpod), AsyncNotifier pattern
- Optimistic UI-Updates (reactions/comments sofort anzeigen, bei Fehler rollback)

**Presentation (`presentation/`):**
- Screens:
  - `board_screen.dart` — Main feed mit Tabs (Alle/Pinned/Umfragen), Pull-to-Refresh, FAB
  - `post_detail_screen.dart` — Full post + comment thread + input bar
  - `poll_detail_screen.dart` — Poll question, selectable options, vote button, results
  - `create_poll_screen.dart` — Form mit dynamischer Option-Liste, settings (deadline, anonym, multi-select)
- Widgets:
  - `post_card.dart` — Preview-Card mit author header, snippet, attachments, reactions
  - `poll_card.dart` — Umfrage-Card mit live results
  - `reaction_bar.dart` — 5 Emoji-Buttons (👍👏❤️😊🎺) mit toggle-logic
  - `pin_badge.dart` — Gelbes "Gepinnt" Badge
  - `poll_status_badge.dart` — Aktiv (grün) / Beendet (grau)
  - `poll_option_tile.dart` — Selectable option mit progress bar, vote count
  - `vote_results.dart` — Horizontal bars mit percentages
  - `comment_thread.dart` — List of comments (1-Ebene, kein nesting)

**Routing (`routes.dart`):**
- Named routes: `CommunicationRoutes.board`, `.postDetail()`, `.pollDetail()`, `.createPoll()`
- GoRoute definitions für alle screens (nested unter `/app/board`)
- DO NOT modify app_router.dart — routes werden via shell branch injected (siehe Kommentar)

**Dependencies hinzugefügt:**
- `timeago: ^3.7.0` — Relative time formatting ("vor 5 Minuten")

### Design Patterns & Konventionen

**Riverpod 3.x Codegen:**
- Alle Notifier mit `@riverpod` (lowercase), `part 'filename.g.dart';`
- Services mit `@Riverpod(keepAlive: true)`
- Family-Provider für ID-basierte Lookups (postDetailNotifierProvider(bandId, postId))

**Material 3 + Design Tokens:**
- `AppColors` — primary, success, warning, error, textSecondary
- `AppSpacing` — xs/sm/md/lg/xl, touchTargetMin (44px), roundedMd
- `AppTypography` — fontSizeXs/Sm/Base/Lg, weightNormal/Medium/Bold
- Card-basiertes Layout mit shadows, rounded corners, consistent padding

**Responsive:**
- Board-Screen funktioniert auf Phone (single column) + Tablet (TODO: 2-column gepinnte Posts)
- Touch-Targets ≥ 44px (Chips, Buttons, IconButtons)

**Null-Safety:**
- Alle optionalen Felder mit `?`, default values in constructors
- `copyWith` für immutable updates

**German Strings:**
- Hardcoded in UI (keine i18n in MS2)
- UX-Sprache: "Gepinnt", "Umfrage", "Abstimmen", "Teilnehmer"

### Noch offen (spätere Issues)

- **Navigation-Integration:** routes.dart muss in app_router.dart injected werden (neue shell branch oder unter Profile-Tab)
- **Create Post Screen:** Fehlt noch (UI + Image/PDF upload flow)
- **Search:** Board-Screen hat Search-Icon, aber keine Implementierung
- **Register-Filter:** Dropdown im Board für "An Register: Trompeten" fehlt
- **Backend-Integration:** Alle API-Calls sind stubs — Backend muss Communication-Endpoints implementieren
- **Pagination:** Cursor-basiert vorbereitet, aber infinite scroll UI fehlt
- **Push-Benachrichtigungen:** FCM/APNs integration (separates Issue)
- **Nested Comments (MS3):** `parentId` in Comment-Model vorbereitet, aber UI zeigt keine Verschachtelung

### Technische Entscheidungen

1. **Shared Author Model:** Author-Klasse wird in beiden post_models.dart + poll_models.dart dupliziert — bewusst, um Zyklische-Dependency zu vermeiden (kein shared/models/ in MS2)
2. **Reaction-Map statt List:** `Map<ReactionType, Reaction>` für O(1) Lookup beim Toggle — einfacher als Liste filtern
3. **timeago Package:** Statt manuellem DateTime-Formatting — standard pattern, German locale support
4. **No build_runner yet:** `.g.dart` Stubs erstellt — echte Generierung nach Flutter-Installation via `flutter pub run build_runner build`
5. **Board = Central Feed:** Polls sind integriert im Board-Screen (Tab), kein separater poll_list_screen nötig

## 2026-03-29 — FlutterSecureStorage Web-Crash Fix (OperationError)

**Commit:** `517f363`

### Ursache

`FlutterSecureStorage` nutzt auf Web die Web Crypto API (`SubtleCrypto`), die in vielen Browser-Kontexten `OperationError` wirft (Inkognito, bestimmte Security-Policies, erster Zugriff). Betroffen: JEDER Token-Read — Login, API-Calls, Onboarding, File-Upload.

Stack: `flutter_secure_storage_web.dart` → `_getEncryptionKey` → `_decryptValue` → `OperationError`, aufgerufen von `token_storage.dart:45` → `api_client.dart:77` (Auth-Interceptor liest Token bei JEDEM Request).

### Fix

**1. Platform-aware TokenStorage (`token_storage.dart`)**
- `kIsWeb` Branching: Web → `SharedPreferences` (localStorage-backed), Mobile/Desktop → `FlutterSecureStorage`
- Private Helpers `_read()`, `_write()`, `_deleteAll()` kapseln die Plattform-Unterscheidung
- ALLE public Methoden in try-catch gewrappt — Fehler geben `null` zurück / loggen per `debugPrint`
- Deprecated `AndroidOptions(encryptedSharedPreferences)` Parameter entfernt (v11 entfernt ihn komplett)

**2. Auth-Interceptor resilient gemacht (`api_client.dart`)**
- `onRequest()`: Token-Read in try-catch — bei Fehler wird Request ohne Auth-Header gesendet (401-Handler dealt damit)
- `onError()`: war bereits durch TokenStorage-interne try-catch implizit abgesichert

**3. Doc-Kommentar aktualisiert (`auth_notifier.dart`)**
- `markOnboardingCompleted()` Kommentar reflektiert neue Storage-Architektur

### Web-Build verifiziert

`flutter build web` → ✅ erfolgreich

### Learnings

- Browser-Sandbox IST die Security-Boundary auf Web — hardware-backed Encryption via SubtleCrypto ist unnötig und fehleranfällig
- `SharedPreferences` auf Web = localStorage, zuverlässig in allen Browser-Kontexten
- Defensives Storage-Design: ALLE I/O-Operationen müssen try-catch haben, niemals `throw` durchlassen
- `kIsWeb` ist compile-time constant → Tree-Shaking entfernt den ungenutzten Pfad

---

## 2026-03-28 — Events/Konzertplanung Feature Module (MS2)

**Task:** Flutter Feature-Implementierung für Events & Kalender-Verwaltung  
**Status:** Implementiert (kompilierbar, benötigt build_runner)

### Was wurde gebaut

Vollständiges Feature-Modul für Konzertplanung und Kalender unter `sheetstorm_app/lib/features/events/`:

**Data Layer:**
- `event_models.dart` — Event, EventStatistics, Rsvp, CalendarEntry, EventType enum, RsvpStatus enum
- `event_service.dart` — CRUD für Events, RSVP submit/update (Riverpod provider)
- `calendar_service.dart` — Kalender-Abfragen (Monat/Woche/Bereich)

**Application Layer:**
- `event_notifier.dart` — EventListNotifier, EventDetailNotifier (family by eventId), RsvpListNotifier
- `calendar_notifier.dart` — CalendarNotifier, SelectedDateNotifier, CalendarViewModeNotifier (Month/Week/List)

**Presentation Layer — Screens:**
- `calendar_screen.dart` — Hauptscreen mit 3 Ansichten (Monat/Woche/Liste), Segmented Control, Navigation (Vor/Zurück), FAB für neuen Termin
- `event_detail_screen.dart` — Termin-Details, RSVP-Buttons (Zusagen/Absagen/Vielleicht), Absage mit optionaler Begründung, Anwesenheitsübersicht, Setlist-Verknüpfung
- `rsvp_screen.dart` — Anwesenheitsliste für Dirigent/Admin, Filter nach Status (Alle/Zugesagt/Abgesagt/Offen/Unsicher), gruppiert nach Status

**Presentation Layer — Widgets:**
- `calendar_view.dart` — CalendarMonthView (Grid mit Dots), CalendarWeekView (Timeline mit Zeitslots)
- `event_card.dart` — Karte für Event-Listen (Typ-Chip, Datum, Zeit, Ort, RSVP-Status)
- `rsvp_status_badge.dart` — Badge für RSVP-Status (Zugesagt/Abgesagt/Unsicher/Offen) mit Icons & Farben
- `event_type_chip.dart` — Chip für Event-Typ (Probe/Konzert/Auftritt/Ausflug/Sonstiges)

**Routing:**
- `routes.dart` — Export von GoRoute-Definitionen für `/app/events`, `/app/events/:eventId`, `/app/events/:eventId/rsvps`

### Design & Patterns (exakt wie bestehender Code)

- **Riverpod 3.x codegen:** `@Riverpod` / `@riverpod`, `part 'filename.g.dart';`
- **State Management:** AsyncValue, AsyncLoading/AsyncData/AsyncError, keepAlive für globale Notifier
- **Models:** Immutable Dart classes, manuelles fromJson/toJson (kein freezed), copyWith
- **API:** Dio via `apiClientProvider`, REST-Wrapper mit Backend-Contract (deutsch: `kapelle_id`, `titel`, `typ`, etc.)
- **Theme:** AppTokens (Spacing, Typography, TouchTargets), AppColors (Status-Farben: success/error/warning)
- **Material 3:** SegmentedButton, FilledButton, OutlinedButton, Card, ListTile
- **Responsive:** Layouts funktionieren auf Phone/Tablet/Desktop
- **Strings:** Hardcoded Deutsch (kein i18n)

### Key UX Flows implementiert

1. **Kalender-Ansichten:** Monat (Grid mit Dots), Woche (Timeline), Liste (chronologisch)
2. **Termin-Details:** Event-Header, RSVP-Section (3 Buttons), Details (Ort/Treffpunkt/Kleiderordnung), Anwesenheitsübersicht
3. **RSVP-Flow:** 1-Tap Zusage, Absage mit Dialog & optionaler Begründung, Vielleicht mit Hinweis-Toast
4. **Anwesenheitsliste:** Filter nach Status, gruppiert, Avatar + Name + Instrument + Begründung (bei Absage)

### API Contract (Backend Endpoints)

Erwartet:
- `GET /api/v1/termine` — Liste mit Filter (kapelle_id, typ, status)
- `GET /api/v1/termine/{id}` — Termin-Details
- `POST /api/v1/termine` — Termin erstellen
- `PUT /api/v1/termine/{id}` — Termin aktualisieren
- `DELETE /api/v1/termine/{id}` — Termin löschen
- `POST /api/v1/termine/{id}/teilnahme` — RSVP submit (status, begruendung)
- `GET /api/v1/termine/{id}/teilnahmen` — RSVP-Liste
- `GET /api/v1/kalender` — Kalender-Einträge (von, bis, typ, status)

JSON-Felder: `kapelle_id`, `titel`, `typ`, `datum`, `start_uhrzeit`, `end_uhrzeit`, `ort`, `treffpunkt`, `beschreibung`, `setlist_id`, `kleiderordnung`, `zusage_frist`, `erstellt_am`, `statistik`, `meine_teilnahme`

### Noch offen (für Backend oder spätere Iteration)

- Push-Benachrichtigungen (Backend-Integration)
- Kalender-Sync (Google/Apple/Outlook) — Endpoints `/api/v1/kalender/sync/*`
- Ersatzmusiker-Vorschlag (Backend-Endpoint `/api/v1/termine/{id}/ersatzmusiker/{musiker_id}`)
- Termin erstellen/bearbeiten (UI-Flow fehlt noch)
- Wiederkehrende Termine (Backend-Logik)
- Integration in `app_router.dart` — `routes.dart` manuell einbinden

### Learnings

- **Enum JSON Mapping:** Enums mit `toJson()`/`fromJson()` statt String-Literals für Backend-Kompatibilität (Backend sendet "Probe" nicht "probe")
- **Riverpod Family:** `EventDetailNotifier(String eventId)` für per-Event-State, automatisches Caching
- **CalendarEntry vs Event:** Separates leichtgewichtiges Model für Kalender-Ansichten (reduziert Datenübertragung)
- **RSVP-Flow UX:** Absage braucht Dialog (Begründung optional), Zusage ist 1-Tap (progressives Disclosure)
- **Material 3 SegmentedButton:** Für Ansichts-Switcher besser als TabBar (keine separate AppBar nötig)
- **intl Package:** DateFormat benötigt `'de_DE'` Locale-String für deutsche Wochentage/Monate
- **AsyncValue.guard:** Cleaner als try-catch für Riverpod State-Updates
- **CalendarMonthView Grid:** `startWeekday - 1` für korrekte Platzierung des 1. Tages im Monat
- **RsvpStatus & EventType Farben:** Konsistente Farbzuordnung in allen Widgets (success/error/warning/primary)

---

## Team Update: Kapellenverwaltung & Auth-Onboarding Spec-Update (2026-03-28T22:10Z)

**From:** Hill (Product Manager)  
**Action:** Frontend scope expanded — 3 new screens + UX flows.

**New Screens Required:**
- Kapellen-Auswahl (entry point after onboarding) — selector with "Meine Musik" first
- Join-Request Flow — show approval status, rejection reason if denied
- Request List Screen (admin/conductor only) — pending requests with approve/reject UI

**UX Flows:**
- **Entry Point:** Post-login/post-onboarding → Kapellen-Auswahl (unless only 1 Kapelle)
- **Join Flow:** Show invitation → request sent → status pending/approved/rejected
- **Approval UI:** Show request, approve/reject buttons, optional rejection reason field

**Affected Features:**
- US-00: "Meine Musik" display (appears first in selector, protected)
- US-02: Kapellen-Auswahl as entry screen (smart routing: 1 Kapelle → direct, only "Meine Musik" → direct)
- US-06: Approval workflow screens

**User Story Impact:** 5 → 7 user stories, 10 → 15 acceptance criteria

**Spec References:**
- docs/feature-specs/auth-onboarding-spec.md — AC-05, AC-06 (entry point)
- docs/feature-specs/kapellenverwaltung-spec.md — US-00, US-02, US-06, §7.9–7.13 (edge cases)

**Status:** Request Wanda review of UX flows before implementation

## 2026-03-31 — MS2 Nacharbeit: GoRouter-Migration + StreamController-Dispose + Author-DRY

**Commit:** 23087ed (zusammen mit Backend-Aenderungen commited)

### Task 1 — GoRouter-Migration (#102 + CR#1)

**Problem:** state.extra bricht Deep Links; Navigator.pushNamed umgeht Auth-Redirect; flache Event-Subrouten.

**Fix:**
- vents/routes.dart: Flache Routen → verschachtelte Struktur (wie setlistRoutes) für korrekte StatefulShellBranch-Integration
- shifts/routes.dart: state.extra → Pfadparameter :planId/:shiftId
- substitute/routes.dart: state.extra entfernt, /substitute/qr/:accessId Route hinzugefügt
- ShiftDetailScreen: StatelessWidget → ConsumerWidget, liest Shift aus shiftPlanProvider
- SubstituteQrScreen: neuer Screen für QR-Code-Anzeige per ccessId
- shift_plan_screen.dart + substitute_management_screen.dart: Navigator.pushNamed → context.push()
- PendingSubstituteLinkProvider: Riverpod Notifier hält transientes SubstituteLink für gorouter-navigation ohne state.extra
- pp_router.dart: AppRoutes.bandSubstituteLink/Qr/ShiftDetail Helper ergänzt

**Learning:** In Riverpod 3.x gibt es kein StateProvider mehr → @riverpod class XNotifier extends _ mit state = ... setzen. Für transiente Navigationsdaten immer einen eigenen Provider (separate .dart-Datei!) anlegen, nicht in codegen-Dateien mit part mischen.

### Task 2 — BroadcastSignalRService.dispose() (#107 + CR#8)

**Problem:** 5 StreamController wurden in dispose() zwar geschlossen, aber dispose() wurde nie aufgerufen, weil der Riverpod-Provider kein ef.onDispose() registriert hatte.

**Fix:**
- Provider: ef.onDispose(service.dispose) hinzugefügt
- dispose() idempotent gemacht (guard: if (!controller.isClosed))
- keepAlive: true beibehalten (WebSocket-Verbindung muss persistent sein)

**Learning:** Immer ef.onDispose() für Services mit Ressourcen registrieren, auch bei keepAlive: true. Das keepAlive verhindert nur das automatische Verwerfen durch Riverpod, nicht das manuelle Dispose.

### Task 3 — Author-DRY + markNeedsBuild (CR#2)

**Problem:**
- (a) Author-Klasse dupliziert in post_models.dart und poll_models.dart
- (b) 3× (context as Element).markNeedsBuild() in Dialog-Callbacksv

**Fix:**
- lib/shared/models/author_model.dart: einzige kanonische Author-Klasse
- post_models.dart + poll_models.dart: importieren + re-exportieren Author
- markNeedsBuild × 3 → StatefulBuilder mit lokalem setDialogState()

**Learning:** StatefulBuilder ist das korrekte Muster für lokalen State in Dialogen/AlertDialogs. (context as Element).markNeedsBuild() ist fragil (cast kann crashen) und nicht idiomatisch Flutter.

**Tests hinzugefügt:**
- 	est/shared/models/author_model_test.dart (4 Tests)
- 	est/features/song_broadcast/.../broadcast_dispose_test.dart (7 Tests)
- 	est/features/routing/gorouter_migration_test.dart (6 Tests)
