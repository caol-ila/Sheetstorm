# Project Context

- **Owner:** Thomas
- **Project:** Notenmanagement-App für eine Blaskapelle — Verwaltung von Musiknoten, Stimmen, Besetzungen und Aufführungsmaterial für Blasorchester
- **Stack:** TBD (wird in der Spezifikationsphase festgelegt)
- **Phase:** Anforderungsanalyse, Marktrecherche, Spezifikation, UX Design
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. Each entry is something lasting about the project. -->

## 2026-03-30 — MS2 Nacharbeit Batch 2: PostService Soft-Delete Consistency

**Task:** Orchestration Batch 2 parallel execution (Romanoff, Banner, Strange, Parker)  
**Scope:** #110 PostService soft-delete consistency  
**Result:** Done, 858 tests pass, 0 regressions

### Soft-Delete Implementation

1. **Database Schema Changes**
   - Added `IsDeleted` (bool, default: false) to `Posts` table
   - Added `DeletedAt` (nullable datetime) to `Posts` table
   - Both fields included in EF Core configuration
   - Created backward-compatible EF Core migration

2. **Service-Layer Logic**
   - `GetPostAsync()` now filters out deleted posts by default
   - `GetPostsAsync()` (list queries) filter `IsDeleted == false`
   - Explicit `GetDeletedPostsAsync()` for admin/audit scenarios (if needed)
   - Delete operation: sets `IsDeleted = true, DeletedAt = DateTime.UtcNow` (soft-delete)
   - Hard delete: available internally for compliance/GDPR if needed

3. **Consistency Patterns**
   - All post-related services filter soft-deleted posts
   - Comments on deleted posts: also soft-delete cascade (or hide)
   - Reactions on deleted posts: soft-delete cascade
   - Related features (PostService, PostReactionService) aligned to soft-delete behavior

### Cross-Team Context

**Integration with Strange:**
- Strange's `IBandAuthorizationService` extraction includes Post authorization patterns
- Service-layer delete logic now consistently uses `DomainException` for errors
- Auth checks happen before soft-delete operation (security first)

**Integration with Parker:**
- Parker's Post-Reply tests (#115) cover soft-delete cascading behavior
- Test fixtures updated to verify deleted posts don't appear in queries
- Empty-state tests verify proper handling of all-deleted scenario

### Test Results

- 858 tests pass (verified fresh run)
- No regressions introduced
- Migration applies cleanly to any existing database

### Key Learnings

- Soft-delete consistency requires filtering at EVERY query point (not just main list)
- Comments & reactions on deleted posts must cascade (design decision: soft or hard?)
- Soft-delete audit trail (`DeletedAt`) useful for compliance/debugging
- Pattern: combine `IsDeleted` flag with `DeletedAt` timestamp for full audit trail

---

### 2026-03-29 — Demo-Account-Seeder & Auth-System-Details

**Auth-System:** Kein ASP.NET Identity — Custom AuthService mit BCrypt.Net-Next 4.1.0 für Passwort-Hashing, SHA-256 für Token-Hashing (Refresh + Email-Verifikation), JWT für Access Tokens.

**Passwort-Policy:** `ValidatePasswordStrength()` in `AuthService.cs` — 8+ Zeichen, Großbuchstabe, Zahl/Sonderzeichen. Im Development-Modus komplett deaktiviert via `IHostEnvironment.IsDevelopment()`.

**Demo-Seeder:** `DemoDataSeeder` in `Sheetstorm.Infrastructure.Seeding` — erstellt User `demo@test.local` / `demo` beim Startup (nur Development). Bypass: Direkt BCrypt-Hash in DB, keine Service-Layer-Validierung. Idempotent (prüft ob User existiert).

**Registrierung in Program.cs:** `DemoDataSeeder` als `Scoped` registriert, `SeedAsync()` wird in `IsDevelopment()`-Block mit eigener Service-Scope ausgeführt.

**Flutter-Bug:** `auth_service.dart` hatte Methode `sections()` die `POST /api/auth/sections` aufrief — Backend erwartet `/api/auth/register`. Gefixt: Methode → `register()`, URL → `/api/auth/register`. Aufrufer in `auth_notifier.dart` und `register_screen.dart` mitangepasst.

**Key Files:**
- `src/Sheetstorm.Infrastructure/Seeding/DemoDataSeeder.cs` — Demo-User-Seeder
- `src/Sheetstorm.Infrastructure/Auth/AuthService.cs` — Auth-Service (BCrypt, JWT, Password-Policy)
- `src/Sheetstorm.Api/Program.cs` — Seeder-Registrierung im Startup
- `sheetstorm_app/lib/features/auth/data/services/auth_service.dart` — Flutter Auth-HTTP-Layer

### 2026-03-29 — Backend Startup Performance Analyse

**Problem:** Backend-Start über `start.ps1` dauerte ~60 Sekunden.

**Root Cause (Hauptgrund):** Port-Mismatch in `start.ps1`:
- Script prüfte Health-Check auf `https://localhost:5001`
- Backend lauscht tatsächlich auf `http://localhost:5273` (launchSettings.json "http" Profil) bzw. `https://localhost:7034` ("https" Profil)
- Health-Check lief 30 × 2s = 60 Sekunden ins Leere → immer Timeout

**Weitere Faktoren:**
- `dotnet run` ohne `--no-build` → bei jedem Start erneuter Build (~1.7s)
- Health-Check Intervall 2s mit 30 Versuchen war unnötig lang

**Fix angewendet (in `start.ps1`):**
1. `$BackendUrl` korrigiert auf `http://localhost:5273` (passend zum Default-Profil)
2. Build vorab (`dotnet build`), dann `dotnet run --no-build` → Build-Feedback sofort sichtbar, Server startet schneller
3. Health-Check optimiert: 15 × 1s statt 30 × 2s (15s statt 60s Timeout)

**Backend-Code selbst ist performant:**
- DI: Alle Services sind `Scoped` (lazy), kein eager init
- EF Core: 15 Konfigurationen, `ApplyConfigurationsFromAssembly` — normal, kein Problem
- S3 Client: Singleton, aber Constructor ist leichtgewichtig
- Keine DB-Migration bei Startup (nur manuell via setup.ps1)
- Middleware-Pipeline: 2 Custom-Middlewares, beide leichtgewichtig

**Key Files:**
- `start.ps1` — Dev-Start-Script (Hauptursache des Problems)
- `src/Sheetstorm.Api/Properties/launchSettings.json` — Port-Definitionen
- `src/Sheetstorm.Api/Program.cs` — Backend-Startup-Code
- `src/Sheetstorm.Infrastructure/DependencyInjection.cs` — Service-Registrierungen

### 2026-03-28 — Issue #11: Auth Backend (JWT, Refresh, Reset)

**Branch:** `squad/11-auth-backend`  
**Worktree:** `C:\Source\Sheetstorm-11`  
**Base:** `squad/7-backend-scaffolding`

**Was gebaut:**
- `AuthController` mit 5 Endpoints: `/register`, `/login`, `/refresh`, `/forgot-password`, `/reset-password`
- `AuthService` + `IAuthService` in `Sheetstorm.Infrastructure.Auth`
- `RefreshToken` Entity mit Family-basierter Rotation und Reuse-Detection (ganzes Token-Family wird revoked bei Wiederverwendung)
- `Musiker` Entity erweitert: `Instrument`, `OnboardingCompleted`, `PasswordResetToken`, `PasswordResetTokenExpiresAt`, `PasswordResetRequestedAt`
- EF Konfigurationen: `MusikerConfiguration`, `RefreshTokenConfiguration` (Unique-Indizes)
- `AuthExceptionMiddleware` für strukturierte JSON Fehler-Responses
- Rate Limiting: 10 Requests / 15 Minuten pro IP auf allen Auth-Endpoints (built-in ASP.NET Core)
- BCrypt.Net-Next 4.1.0 für Password-Hashing

**Architektur-Entscheidung:** DTOs in `Sheetstorm.Domain.Auth` statt `Sheetstorm.Api.Models.Auth`, damit `Infrastructure` sie ohne zirkuläre Referenz nutzen kann. Api-Layer bekommt die Types via global using.

**Pakete hinzugefügt:**
- `BCrypt.Net-Next` 4.1.0 → Infrastructure
- `Microsoft.AspNetCore.Authentication.JwtBearer` 10.0.5 → Infrastructure (für JWT-Generierung)

---

### 2026-03-28 — Issue #16: Kapellenverwaltung — Backend REST-API

**Branch:** `squad/16-kapelle-backend`  
**Worktree:** `C:\Source\Sheetstorm-16`  
**Base:** `squad/11-auth-backend`

**Was gebaut:**
- `KapelleController` mit 6 Endpoints: `POST /api/kapellen`, `GET /api/kapellen`, `GET /api/kapellen/{id}`, `PUT /api/kapellen/{id}`, `DELETE /api/kapellen/{id}`, `POST /api/kapellen/beitreten`
- `MitgliederController` mit 4 Endpoints: `GET mitglieder`, `POST einladungen`, `PUT mitglieder/{userId}/rolle`, `DELETE mitglieder/{userId}`
- `Einladung` Entity (Code, KapelleID, VorgeseheRolle, ExpiresAt, IsUsed, ErstelltVon, EingeloestVon)
- `Kapelle` Entity erweitert: `Ort`, `LogoUrl`, `Einladungen` Navigation
- DTOs in `Sheetstorm.Domain.Kapellenverwaltung` (wegen Namenskonflikt mit Klasse `Kapelle`)
- EF Konfigurationen: `KapelleConfiguration`, `MitgliedschaftConfiguration` (Unique-Index MusikerID+KapelleID), `EinladungConfiguration` (Unique-Index Code)
- `KapelleService` + `IKapelleService` in `Sheetstorm.Infrastructure.KapelleManagement`
- Rollenbasierte Autorisierung in der Service-Schicht (kein Policy-Framework nötig)
- Einladungscode: 8-Zeichen, kryptografisch zufällig, Einmalverwendung, konfigurierbares Ablaufdatum (1–30 Tage)
- Schutz: Letzter Admin kann Kapelle nicht verlassen; Re-Aktivierung bei Wiederbeitritt

**Architektur-Entscheidungen:**
- DTOs-Namespace `Sheetstorm.Domain.Kapellenverwaltung` statt `Sheetstorm.Domain.Kapelle`, weil letzteres mit der gleichnamigen Entity-Klasse kollidiert (C# löst Namespace `Kapelle` vor importiertem Typ auf)
- Service-Namespace `Sheetstorm.Infrastructure.KapelleManagement` statt `Sheetstorm.Infrastructure.Kapelle` — gleicher Grund: Namespace-Konflikt mit `Kapelle`-Klasse in Infrastructure-internen Dateien
- Rollenprüfungen in Service-Schicht, nicht via ASP.NET Core Policies — Rollen sind in der DB, kein JWT-Claim, flexibler für Multi-Kapellen-Szenario
- `AuthException` wird auch für Kapelle-Fehler genutzt (Middleware fängt sie bereits ab)
- `POST /api/kapellen/beitreten` im `KapelleController` statt im `MitgliederController`, da kein `{kapelleId}` vorhanden und Antwort ein `KapelleDto` ist

---

### 2026-03-28 — MS2 Backend Implementation (5 Features)

**Features implementiert:**
1. **Setlists** — Konzert-/Proben-/Template-Setlists mit Entries (Piece-Referenzen oder Platzhalter)
2. **Media Links** — YouTube/Spotify/SoundCloud-Links zu Pieces
3. **Communication** — Posts mit Comments und Reactions (Board-Feature)
4. **Polls** — Abstimmungen mit Single-/Multi-Choice und Anonymität
5. **Attendance** — Anwesenheitsverwaltung mit Statistics

**Domain Layer (13 Entities + 3 Enums + 5 DTOs):**
- Entities: `Setlist`, `SetlistEntry`, `MediaLink`, `Post`, `PostComment`, `PostReaction`, `Poll`, `PollOption`, `PollVote`, `AttendanceRecord`
- Enums: `SetlistType`, `MediaLinkType`, `AttendanceStatus`
- DTOs: `Sheetstorm.Domain.Setlists`, `Sheetstorm.Domain.MediaLinks`, `Sheetstorm.Domain.Communication`, `Sheetstorm.Domain.Polls`, `Sheetstorm.Domain.Attendance`

**Infrastructure Layer (10 EF Configurations + 10 Services):**
- EF Configurations für alle 13 Entities mit Relationships, Indizes, Constraints
- Services: `SetlistService`, `MediaLinkService`, `PostService`, `PollService`, `AttendanceService` (je mit Interface)
- Alle Services implementieren Membership-Check, Role-Based Access Control über `MemberRole` Enum
- Pattern: `RequireMembershipAsync()` Helper für Band-Zugriffskontrolle in jedem Service

**API Layer (5 Controllers):**
- `SetlistController` — CRUD + Entries hinzufügen/reordern/löschen + Duplicate
- `MediaLinkController` — CRUD für Links zu Pieces
- `PostController` — CRUD + Pin/Unpin + Comments + Reactions
- `PollController` — CRUD + Vote + Close
- `AttendanceController` — CRUD + Stats (Band-weit + per Musician)

**Access Control Matrix:**
- **Admin/Conductor:** Volle Rechte für Setlists, Posts, Polls, Attendance
- **SectionLeader:** Posts/Polls erstellen, Attendance eintragen
- **SheetMusicManager:** Media Links verwalten
- **Musician:** Lesen, Kommentieren, Reagieren, Voten, eigene Attendance sehen

**Key Patterns etabliert:**
- Enum → String Conversion in EF (`HasConversion<string>()` + `HasMaxLength(30)`)
- DTOs in `Domain/{Feature}/{Feature}Models.cs` mit Request/Response Records
- Service Helper Pattern: `RequireMembershipAsync()` wirft `DomainException("BAND_NOT_FOUND", ..., 404)` bei fehlender Membership
- Controller Pattern: `CurrentUserId` Property via JWT Sub-Claim, alle Methoden async mit `CancellationToken ct`
- ErrorResponse via `Sheetstorm.Domain.Auth.ErrorResponse` für konsistente Fehlerstruktur

**Wichtige Details:**
- Setlist Entries: Position-basiert, Reorder via `ReorderEntriesRequest` mit ID-Liste
- MediaLink Type Detection: Auto-Erkennung von YouTube/Spotify/SoundCloud via URL-Pattern
- Post Reactions: 1 Reaction pro User, Toggle-Mechanismus (Add überschreibt, Remove löscht)
- Poll Votes: Single-/Multi-Choice je nach `IsMultipleChoice`, alte Votes werden beim Vote überschrieben
- Attendance Stats: Aggregation über DateOnly-Range, `AttendanceRate = Present / Total * 100`

**Nicht modifiziert (wie gefordert):**
- `AppDbContext.cs` — DbSets werden von Follow-up Agent hinzugefügt
- `DependencyInjection.cs` — Service-Registrierungen erfolgen später
- `Program.cs` — Keine Änderungen, bleibt intakt

**Key Files:**
- Domain: `src/Sheetstorm.Domain/Entities/{Entity}.cs`, `src/Sheetstorm.Domain/Enums/{Enum}.cs`, `src/Sheetstorm.Domain/{Feature}/{Feature}Models.cs`
- Infrastructure: `src/Sheetstorm.Infrastructure/Persistence/Configurations/{Entity}Configuration.cs`, `src/Sheetstorm.Infrastructure/{Feature}/{Feature}Service.cs`
- API: `src/Sheetstorm.Api/Controllers/{Feature}Controller.cs`
## Session Log

### 2026-03-28 — PR #93 Auth Flutter Fix (Lockout: Romanoff → Banner)

**Requested by:** Thomas (via Ralph)
**Branch:** `squad/93-auth-flutter-fix` (worktree off `squad/12-auth-flutter`)
**PR under review:** #93 — [Dev] #12 Auth Flutter UI & Token Management

**Stark's Review — All 4 Action Items Resolved:**

1. ✅ **Token storage on flutter_secure_storage** — was already done by Romanoff in original PR (no change needed)
2. ✅ **`/email-verify/:token` route + handler** — Added `EmailVerificationScreen`, `/email-verify` and `/email-verify/:token` routes, `AuthService.verifyEmail()`, `AuthNotifier.verifyEmail()` + `resendVerificationEmail()`
3. ✅ **Token expiry on app start** — `TokenStorage.isAccessTokenExpired()` with 60s margin; `_initializeAuth` now attempts silent refresh → logout on failure
4. ✅ **`debugLogDiagnostics: kDebugMode`** — was hardcoded `true`

**Architecture Decisions Implemented:**
- **E-Mail-Bestätigung (Pflicht):** New `AuthEmailPendingVerification` state; `login`/`register` gate `AuthAuthenticated` on `user.emailVerified`; redirect logic updated
- **Dev-Mode Auto-Verify:** `AppConfig.devAutoVerifyEmail = kDebugMode` — skips email verification in debug builds
- **User model:** `emailVerified` field added; `TokenStorage` persists access token expiry timestamp

**Files changed (8):**
- `lib/core/config/app_config.dart` *(new)*
- `lib/core/routing/app_router.dart`
- `lib/features/auth/application/auth_notifier.dart`
- `lib/features/auth/data/models/auth_models.dart`
- `lib/features/auth/data/services/auth_service.dart`
- `lib/features/auth/data/services/token_storage.dart`
- `lib/features/auth/presentation/screens/email_verification_screen.dart` *(new)*
- `lib/features/auth/presentation/screens/register_screen.dart`

**Note:** PR comment could not be posted automatically (no GitHub write token available in environment). Comment should be posted manually on PR #93 referencing branch `squad/93-auth-flutter-fix`.


---

## Team Update: Kapellenverwaltung & Auth-Onboarding Spec-Update (2026-03-28T22:10Z)

**From:** Hill (Product Manager)  
**Action:** Backend scope expanded for approval workflow.

**New Endpoints Required:**
- POST /api/kapellen/beitreten — Create join request (user submits via invitation)
- GET /api/kapellen/{id}/anfragen — List pending join requests (admin/conductor only)
- PUT /api/kapellen/{id}/anfragen/{requestId} — Approve/reject request

**Service Changes:**
- Extend KapelleService with RequestJoinAsync(), GetJoinRequestsAsync(), ApproveRequestAsync(), RejectRequestAsync()
- Add BeitrittsanfrageRepository interface + EF implementation
- Permission checks: Admin/Conductor/SectionLeader can approve (service layer)
- Rejection sends email notification

**Affected User Stories:**
- US-00: "Meine Musik" auto-created (add ist_persoenlich flag to Kapelle creation)
- US-02: Entry point selection (POST /kapellen/select endpoint exists?)
- US-06: New approval workflow (3 new endpoints)

**Testing:**
- 13 edge cases including: double-requests, rejection+reapply, "Meine Musik" immutability, last-admin protection

**Status:** Estimate expansion needed for new endpoints + service methods

---

## Team Update: MS2 Nacharbeit Batch 1 (2026-03-30T21:10Z)

**From:** Scribe  
**Action:** Romanoff, Banner, Parker executed parallel P0/P1 batch.

### Banner's Completed Tasks

**Tickets Resolved:**
- #111 — ShiftService validation: Added null checks + 3 new tests
- #112 — ParentCommentId check: Added parent post existence validation + 2 new tests
- #109 — MaxLength attributes: Reflection-based fluent API on 17 string properties + 17 new tests

**Test Results:** 854 tests passing (22 new validation tests added)

**Key Pattern:** `RequirePostExistsAsync()` helper in PostService for parent validation. This pattern established for Parker's upcoming provider override tests.

**Files:** ShiftService.cs, PostService.cs, 17 Configuration.cs files, new validation test files

### Cross-Team Impact

**Parker (QA) - IMPORTANT:**
- Banner's ParentCommentId fix in `PostService.AddCommentAsync()` affects Parker's provider override migration for communication notifiers
- When Parker tests `post_notifier_test.dart`, parent comment validation is now enforced at service layer — mock setup must include valid post references
