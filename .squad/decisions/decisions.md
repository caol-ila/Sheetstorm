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

---

## Decision 3: Password Reset Tokens Should Also Be Hashed

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-03-28  
**Context:** Auth backend fix (squad/88-auth-fix)  
**Status:** Follow-up issue (not blocking)

### Observation

While fixing email verification token hashing, observed that `PasswordResetToken` in `ForgotPasswordAsync` and `ResetPasswordAsync` is still stored and looked up in plaintext. This is inconsistent with the SHA-256 hashing pattern now applied to both refresh tokens and email verification tokens.

### Recommendation

Apply the same `HashToken()` pattern to password reset tokens in a follow-up PR:
- `ForgotPasswordAsync`: store `HashToken(token)`, send raw token in email
- `ResetPasswordAsync`: hash incoming token before DB lookup

This is low-risk, follows the existing pattern, and closes the last plaintext-token gap.

### Priority

Follow-up issue — not blocking current PR.

---

## Decision 4: DomainException Layer Separation

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-03-28  
**Context:** Kapelle backend fix (squad/95-kapelle-fix)  
**Status:** Implemented in squad/95-kapelle-fix

### Decision

Introduced `DomainException` in `Sheetstorm.Domain.Exceptions` to separate domain errors from auth errors. The middleware now catches both `DomainException` and `AuthException`.

**Rule:** `AuthException` is ONLY for actual authentication/authorization failures (FORBIDDEN/403). All domain errors (not-found, conflict, validation) use `DomainException` with appropriate HTTP status codes.

This prevents the Flutter auth interceptor from misinterpreting domain errors as auth failures (which triggered token refresh or logout).

### Impact

All future services should follow this pattern. Any new domain error codes go through `DomainException`, not `AuthException`.

---

### 2026-03-30 — MS2 Nacharbeit Batch 2: Orchestration Completion

**From:** Scribe  
**Date:** 2026-03-30  
**Type:** Session Summary & Orchestration Log  
**Status:** Completed — All 4 agents done

#### Batch Composition

Four agents executed in parallel:
1. **Romanoff** (Frontend): GoRouter migration, SubstituteQrScreen, BroadcastSignalRService, Author DRY, markNeedsBuild
2. **Banner** (Backend): PostService soft-delete consistency
3. **Strange** (Principal Backend): IBandAuthorizationService DRY extraction from 12 services
4. **Parker** (QA): Post-Reply tests, Setlist tests, provider override migration

#### Results Summary

| Agent | Output | Tests | Status |
|-------|--------|-------|--------|
| Romanoff | 17 new tests, 0 regressions | Flutter | ✅ Complete |
| Banner | PostService refactor, migration | 858 pass | ✅ Complete |
| Strange | IBandAuthorizationService, 145 lines removed | 882 pass | ✅ Complete |
| Parker | 35 backend + 54 Flutter, 8 empty-state | 89 new/updated | ✅ Complete |

#### Cross-Agent Dependencies (All Resolved)

- Romanoff's GoRouter paths → Parker's navigation assertions updated
- Banner's soft-delete → Strange's authorization preserved at query time
- Strange's IBandAuthorizationService → Parker's test mocks use centralized service
- Romanoff's Author DRY → Parker's communication notifiers use shared model

#### No Merge Conflicts

All agents worked on independent subsystems (frontend UI patterns, backend soft-delete, auth service extraction, test coverage). Clean merge to main expected.

---

## Decision 10: Cloud-Sync Frontend — Architekturentscheidungen (MS3)

**Von:** Romanoff (Frontend Engineer)  
**Datum:** 2026-04-16  
**Branch:** squad/ms3-implementation  
**Feature:** Cloud-Sync (Persönliche Sammlung) Flutter Frontend  
**Status:** Architecture locked; implementation complete

### Entscheidungen

#### 1. `Notifier<SyncState>` statt `AsyncNotifier`

**Entscheidung:** `SyncNotifier` ist ein plain `Notifier<SyncState>` (nicht `AsyncNotifier<SyncState>`).

**Begründung:**
- Der Sync-State ist ein lokales Zustandsobjekt (Status, Timestamps, Konfliktliste)
- Async-Methoden (`sync()`, `push()`, `pull()`) mutieren den State manuell mit `copyWith()`
- Das gibt feinere Kontrolle über Zwischenzustände (z.B. `SyncStatus.syncing` während des API-Calls)
- `AsyncNotifier` wäre falsch, weil der State selbst nicht async geladen wird

**Auswirkung:** Alle anderen Teams (Banner, Stark) müssen `syncProvider` als `Notifier` referenzieren, nicht als `AsyncNotifier`.

#### 2. Konflikt-Auflösung ist Client-seitiges Dismiss

**Entscheidung:** `resolveConflict(entityId)` entfernt den Konflikt nur aus der lokalen Liste. Kein separater API-Call.

**Begründung:**
- LWW (Last-Write-Wins) wird bereits auf dem Server angewendet
- Das Backend liefert Konflikte nur zur Information (was überschrieben wurde)
- Der Client bestätigt das Lesen des Konflikts — kein State zu ändern

**Wenn anders gewünscht:** Backend müsste `POST /api/sync/conflicts/{entityId}/ack` anbieten. Dann sollte `SyncService` eine `acknowledgeConflict()` Methode bekommen und `resolveConflict()` im Notifier sollte awaitable sein.

#### 3. Widget-only Feature — keine Screens

**Entscheidung:** Cloud-Sync hat keine eigenen Screens. Nur Widgets (`SyncStatusIndicator`, `SyncConflictDialog`) die in andere Features eingebettet werden.

**Begründung:**
- Per UX-Spec ist der Sync-Status contextual (AppBar Badge, Refresh-Trigger)
- Kein eigenes Navigation-Destination nötig
- `routes.dart` ist leer (stub für Konsistenz)

**Integration:** Teams die `SyncStatusIndicator` einbinden:
```dart
import 'package:sheetstorm/features/cloud_sync/presentation/widgets/sync_status_indicator.dart';

// Im AppBar actions:
Consumer(builder: (context, ref, _) {
  final syncState = ref.watch(syncProvider);
  return SyncStatusIndicator(status: syncState.status);
})
```

#### 4. Riverpod Test Pattern: `ProviderContainer(overrides: [...])`

**Entscheidung:** In Tests immer Overrides im Konstruktor übergeben, nicht via `updateOverrides()`.

**Begründung:**
- Riverpod 3.x verbietet `updateOverrides()` wenn Container ohne initiale Overrides erstellt wurde
- `updateOverrides()` darf nur bestehende Overrides aktualisieren (gleiches Objekt, neuer Wert)
- Korrekte Variante: `ProviderContainer(overrides: [serviceProvider.overrideWithValue(mock)])`

**Betroffene Teams:** Parker (Tests), alle die Riverpod-Tests schreiben

#### 5. API-Endpunkte (camelCase, /api/ Prefix)

**Entscheidung:** Sync-Endpunkte folgen dem etablierten Muster:
- `GET /api/sync/state` → `SyncStateResponse`
- `GET /api/sync/pull?since=<ISO8601>` → `{ deltas: SyncDelta[] }`
- `POST /api/sync/push` → Body: `{ deltas: SyncDelta[] }`

**JSON Keys:** camelCase (`lastSyncAt`, `pendingChanges`, `entityType`, `vectorClock`, etc.)

**Betroffene Teams:** Stark (Backend-Implementierung), Banner (API-Integration)

---

## Decision 11: Auth Flutter Client Alignment

**By:** Vision (Principal Frontend Engineer)  
**Date:** 2026-03-29  
**Branch:** squad/93-auth-flutter-fix  
**Commit:** 8531deb  
**Status:** Implemented and merged to main

### Context

The auth Flutter fix (PR #93) was unanimously rejected by all 3 reviewers. After Strange fixed the backend contracts on squad/88-auth-fix, the Flutter client needed to align.

### Changes Made

1. **Endpoint prefix**: All auth endpoints changed from `/auth/` to `/api/auth/` to match backend routing.
2. **verify-email contract**: Changed from `POST /auth/email-verify/$token` (token in URL) to `POST /api/auth/verify-email` with JSON body `{ "token": "..." }`.
3. **Resend button removed**: Backend has no resend-verification endpoint. UI button removed; TODO added for follow-up.
4. **Refresh race condition fixed**: Added `Completer<void>`-based mutex in `_AuthInterceptor` — only one refresh in flight at a time, concurrent callers wait for result. Prevents family-based rotation reuse detection.
5. **completeOnboarding Dio instance fixed**: Now uses `apiClientProvider` (with auth interceptor) instead of `AuthService._dio` (bare, no Bearer token).
6. **Async storage writes awaited**: `onAuthError()` and `markOnboardingCompleted()` now properly `await` storage writes to prevent stale-state race conditions.

### Follow-up Needed

- **Strange**: Add `POST /api/auth/resend-verification` endpoint so we can re-enable the resend button in the email verification screen.
- **build_runner**: The `.g.dart` files need regeneration once Flutter SDK is available in the build environment.

### Team Impact

- Frontend now fully aligned to Strange's backend API contracts on squad/88-auth-fix.
- The Completer mutex pattern should be reused in any future interceptor that handles token rotation.

---

## Decision 6: Final Merge Decisions — Re-Review Round (All 3 Branches)

**Author:** Stark (Lead / Architect)  
**Date:** 2026-03-29  
**Status:** All 3 branches merged to main

### squad/88-auth-fix — ✅ MERGED

**Vote:** 2/3 APPROVE (Opus ✅, GPT ✅, Sonnet ❌)

**Sonnet's rejection dismissed.** Primary claim ("IStorageService not removed") was factually wrong — Opus confirmed removal in commit ed44824. Secondary concerns are valid but non-blocking:
- **Raw token in DevEmailService logs:** Dev-only service, acceptable for development. FOLLOW-UP: strip tokens before production.
- **Registration returns tokens to unverified users:** Design decision, not a bug. Many apps grant partial access pre-verification.
- **No rate limiting on verify-email:** Already designated as FOLLOW-UP item.

**Merged** into main. No conflicts.

### squad/93-auth-flutter-fix — ✅ MERGED

**Vote:** 3/3 APPROVE (unanimous)

All three reviewers approved. Noted follow-ups (non-blocking):
- Interceptor path guard hardening
- Base URL duplication cleanup
- JSON key format (snake_case vs camelCase) — verify against backend response format

**Merged** into main. No conflicts.

### squad/95-kapelle-fix — ✅ MERGED

**Vote:** 2/3 APPROVE (Sonnet ✅, Opus ✅, GPT ❌)

**GPT's rejection dismissed after code verification.** GPT claimed admin A can remove admin B leaving zero admins. **This is incorrect.** Verified in `KapelleService.MitgliedEntfernenAsync`:

1. To remove another member, the caller **must be an admin** (`requester.Rolle != MitgliedRolle.Administrator` → 403)
2. Therefore if admin A removes admin B, admin A still exists → at least 1 admin remains
3. Self-removal guard correctly counts ALL admins via `CountAsync` and blocks if `adminCount <= 1`
4. `RolleAendernAsync` has a parallel guard preventing demotion of the last admin

The logic is sound. GPT's concern represents a misunderstanding of the code flow.

**Minor items noted by Opus (non-blocking FOLLOW-UPs):**
- `AuthException` coupling in domain layer — consider `DomainException` instead
- Typo `VorgeseheRolle` → should be `VorgeseheneRolle` (consistent typo, functional, cosmetic fix)

**Merged** into main. One conflict in `DependencyInjection.cs` (both #88 and #95 added service registrations) — resolved by keeping both: `IEmailService` + `IKapelleService`.

### Summary

| Branch | Decision | Conflicts | Status |
|--------|----------|-----------|--------|
| squad/88-auth-fix | MERGE | None | ✅ Merged |
| squad/93-auth-flutter-fix | MERGE | None | ✅ Merged |
| squad/95-kapelle-fix | MERGE | 1 (resolved) | ✅ Merged |

All three branches merged to main and pushed to origin.

### FOLLOW-UP Items (Future Issues)

1. Strip tokens from DevEmailService logs before production deployment
2. Rate limiting on verify-email endpoint
3. Flutter auth interceptor path guard hardening
4. Base URL duplication cleanup in Flutter
5. Verify JSON key format consistency (snake_case vs camelCase) between backend and Flutter
6. Add `POST /api/auth/resend-verification` endpoint (blocking resend button re-enable)
7. Fix typo `VorgeseheRolle` → `VorgeseheneRolle` (cosmetic)
8. Password reset token hashing (follow-up PR, low priority)

---

## Decision 7: MS2 Backend Architecture — Feature-First Structure

**By:** Banner (Backend Developer)  
**Date:** 2026-03-28  
**Context:** MS2 Backend Implementation — 5 CRUD Features  
**Status:** Implemented in squad/ms2-banner-backend

### Decisions Made

#### 1. Feature-First Directory Structure
Each feature gets its own namespace:
- Domain: `Sheetstorm.Domain.{Feature}/{Feature}Models.cs`
- Infrastructure: `Sheetstorm.Infrastructure.{Feature}/I{Feature}Service.cs` + `{Feature}Service.cs`

**Rationale:** Clean separation, avoids namespace conflicts, makes feature ownership clear.

#### 2. Enums Stored as Strings in Database
All enums (`SetlistType`, `MediaLinkType`, `AttendanceStatus`) stored as strings via EF:
```csharp
builder.Property(e => e.Type)
    .HasConversion<string>()
    .HasMaxLength(30)
    .IsRequired();
```
**Rationale:** Future-proof (enum values can change without breaking DB), human-readable, easier debugging.

#### 3. Service-Level Authorization (Not Policy-Based)
Role checks via `MemberRole` enum in Service layer:
```csharp
if (membership.Role != MemberRole.Administrator && 
    membership.Role != MemberRole.Conductor)
    throw new DomainException("FORBIDDEN", "...", 403);
```
**Rationale:** Roles are band-specific, not global. Flexible for multi-band scenarios. No JWT claims needed.

#### 4. DomainException Standardization
All business logic errors use standardized format:
```csharp
throw new DomainException("ERROR_CODE", "Human message", httpStatusCode);
```
Error codes: `NOT_FOUND` (404), `FORBIDDEN` (403), `CONFLICT` (409), `VALIDATION_ERROR` (400)

**Rationale:** Consistent API error structure, middleware handles centrally, no HTTP leakage in business logic.

#### 5. MediaLinkType Auto-Detection
URL-based recognition in `MediaLinkService.DetermineMediaLinkType()`:
- `youtube.com` / `youtu.be` → YouTube
- `spotify.com` → Spotify
- `soundcloud.com` → SoundCloud
- `music.apple.com` → AppleMusic
- Fallback → Other

**Rationale:** Reduces user error, better UX.

#### 6. Post Reactions: 1 Per User (Toggle)
One user = one reaction per post. Re-reaction overwrites old.

**Rationale:** Simplified UI, prevents spam, standard pattern (Discord, Slack).

#### 7. Poll Votes: Overwrite Pattern
New vote deletes old votes and adds new.

**Rationale:** User can change opinion, no "Undo" button needed, matches UX expectations.

#### 8. Attendance Rate Formula
`AttendanceRate = (Present / Total) * 100`  
**Late counts as NOT present** — only explicit `Present` status.

**Rationale:** Statistical accuracy, fair comparison between musicians.

#### 9. Shared Files Not Modified
`AppDbContext.cs`, `DependencyInjection.cs`, `Program.cs` left untouched by Banner.

**Rationale:** Avoid conflicts with parallel work (Strange agent). Follow-up agent adds DbSets/services centrally.

### Features Implemented
- Setlist Management (create, update, delete with timing)
- Media Links (YouTube, Spotify, SoundCloud, AppleMusic auto-detection)
- Communication/Posts (bulletin board with reactions)
- Polls (band decision voting)
- Attendance Tracking (presence stats)

### Build Status
✅ Infrastructure layer compiles cleanly. 43 new files created.

---

## Decision 8: MS2 Backend Architecture — Complex Features & Services

**By:** Strange (Principal Backend Engineer)  
**Date:** 2026-03-28  
**Context:** MS2 Backend Implementation — 5 Complex Features  
**Status:** Implemented in squad/ms2-strange-backend

### Decisions Made

#### 1. Service Independence Over Shared Base
Each service has its own `RequireMembershipAsync` / `RequireConductorOrAdminAsync` helpers rather than extracting shared base class.

**Rationale:** Keeps services independent and testable without tight coupling. Few lines of duplication preferable to inheritance complexity.

#### 2. Substitute Token Security Model
- Token generation: `RandomNumberGenerator.GetBytes(32)` → Base64Url encode  
- Storage: SHA-256 hash only (raw token never stored)
- Validation: `[AllowAnonymous]` endpoint (substitutes lack JWT accounts)

**Rationale:** Follows same pattern as password reset tokens — one-way hash, compare on validation.

#### 3. SongBroadcast as Pure SignalR (No DB Persistence)
SongBroadcastHub uses `ConcurrentDictionary` for in-memory state. No database entity for broadcast sessions.

**Rationale:** Sessions are ephemeral (< 2 hours). DB persistence adds latency. Server restart ends sessions — acceptable for real-time music broadcasting.

#### 4. GEMA Export Formats
- CSV: Semicolons (DACH standard) with UTF-8 BOM for Excel
- XML: Simplified GEMA-Meldung schema
- PDF: Deferred to MS3 (returns 400 until library added)

**Rationale:** DACH region standards, future extensibility.

#### 5. Files Not Modified
`AppDbContext.cs`, `DependencyInjection.cs`, `Program.cs` left untouched. Follow-up integration agent will:
- Add DbSets for all entities to AppDbContext
- Register all new services in DependencyInjection
- Map `SongBroadcastHub` in Program.cs

**Rationale:** Avoid conflicts with Banner's parallel work. Centralized merge in final step.

#### 6. Role-Based Access Pattern
Conductor OR Admin can manage events, GEMA reports, substitutes, shifts. Regular musicians: read access + self-signup.

**Rationale:** Matches existing BandService pattern, clear authority model.

### Features Implemented
- Events/Konzertplanung (RSVP, concert planning)
- GEMA Compliance (export for copyright societies)
- Song-Broadcast (real-time conductor-to-musicians via SignalR)
- Aushilfen/Substitute Access (temporary non-member invites)
- Schichtplanung (shift planning with self-signup)

### Build Status
✅ Infrastructure layer compiles cleanly. 35 new files created.

---

## Decision 9: AI Development Standards — Superpowers Adoption

**By:** Stark (Lead / Architect)  
**Date:** 2026-03-28  
**Context:** Elevate Squad development practices  
**Status:** Adopted and documented in `.github/copilot-instructions.md`

### Standards Adopted

#### 1. Test-Driven Development (TDD)
Red-Green-Refactor mandatory for new features and bugfixes. No production code without failing test first.

#### 2. Systematic Debugging (4-Phase Process)
1. Root-Cause Analysis
2. Pattern Identification
3. Hypothesis Formation
4. Fix Implementation

No fixes without root-cause analysis. 3+ failed fixes → re-examine architecture.

#### 3. Verification Before Completion
No feature marked done without fresh evidence:
- `flutter test` for Flutter features
- `dotnet test` for .NET features
- Build check (`dotnet build` / `flutter build`)

### Rationale
Superpowers standards are proven, language-agnostic, and complement existing policies (3-reviewer, UX review) without conflicts.

### Documentation
Created `.github/copilot-instructions.md` as project-wide Copilot guidance (previously missing).

# Romanoff — Tuner Frontend: Architektur-Entscheidungen

**Datum:** 2026-03-31  
**Feature:** Stimmgeraet (Tuner), MS3  
**Agent:** Romanoff (Frontend)

---

## Entscheidung 1: A-basierte Piano-Nummerierung (A0=1, A4=49)

**Problem:** Task-Spec enthielt eine inkonsistente Formel: 
oteNumber + 49 aber ["C","C#",...]-Array. Bei A4=49 ergibt (49-1)%12=0 → "C" statt "A".

**Loesung:** Array auf A-Basis ausgerichtet: ['A','A#','B','C','C#','D','D#','E','F','F#','G','G#']. Formel bleibt 
oteNumber = 12*log2(f/ref) + 49.

**Begruendung:** Mathematisch korrekt und durch alle 78 Tests verifiziert. Ergibt A4→A, C4→C, B4→B. Keine Auswirkung auf Backend oder andere Teams.

---

## Entscheidung 2: Transpositionswerte (Eb = +9, nicht +3)

**Problem:** Feature-Spec §6.4 nennt "+3 Halbtöne" fuer Eb, aber §6.4-Beispiel zeigt "C4 → Eb3 klingend" was +9 Halbtöne Verschiebung ergibt. Widerspruch in der Spec.

**Loesung:** +9 Halbtöne implementiert (Konzert A4 → Anzeige F#5). Das entspricht der Musiktheorie: Alt-Sax ist eine grosse Sexte tiefer als notiert → angezeigte Note ist grosse Sexte (9 Halbtöne) hoeher als Concert-Ton.

**Empfehlung an Hill/Stark:** Spec §6.4 Eb-Zeile korrigieren: "+9 Halbtöne" (oder "kleine Terz abwaerts = grosse Sexte aufwaerts").

---

## Entscheidung 3: 5. Navigations-Tab "Werkzeuge"

**Problem:** UX-Spec nennt "Werkzeuge-Tab", aber AppShell hatte nur 4 Tabs.

**Loesung:** 5. StatefulShellBranch mit /app/tuner Route hinzugefuegt. AppShell um 5. NavigationDestination (Icons.tune, "Werkzeuge") erweitert.

**Auswirkung:** Wanda sollte UX fuer den Werkzeuge-Tab definieren (welche weiteren Tools gehen dort rein — Metronom?).

---

## Entscheidung 4: AudioAnalyzer — Nur Interface, kein Platform Channel

**Problem:** Platform Channels fuer CoreAudio/Oboe/WASAPI sind komplex und plattformspezifisch.

**Loesung:** Abstraktes AudioAnalyzer-Interface + MockAudioAnalyzer fuer Tests. udioAnalyzerProvider ist ueberladbar. Vision implementiert PlatformAudioAnalyzer.

**Konvention:** udioAnalyzerProvider in Production-Code durch PlatformAudioAnalyzer ersetzen. Tests weiterhin MockAudioAnalyzer via overrideWithValue.
