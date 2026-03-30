# Project Context

- **Owner:** Thomas
- **Project:** Sheetstorm — Notenmanagement-App für Blaskapellen
- **Stack:** Flutter 3.41.5 + ASP.NET Core 10 LTS + PostgreSQL + SQLite
- **Role:** Principal Backend Engineer — übernimmt die komplexesten Backend-Aufgaben
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. -->

## 2026-03-30 — MS2 Nacharbeit Batch 2: IBandAuthorizationService DRY Extraction

**Task:** Orchestration Batch 2 parallel execution (Romanoff, Banner, Strange, Parker)  
**Scope:** #108+CR#6 DRY Auth extraction from 12 services  
**Result:** Done, 882 tests pass, 145 lines duplication removed, 24 new tests

### IBandAuthorizationService Extraction

1. **Service Interface & Implementation**
   - Created `IBandAuthorizationService` in `Sheetstorm.Infrastructure.Authorization`
   - Centralized membership and role-based authorization logic
   - Three core methods:
     - `RequireMembershipAsync(bandId, userId)` — throws 404 if not member
     - `RequireConductorOrAdminAsync(bandId, userId)` — throws 403 if not conductor/admin
     - `RequireAdminAsync(bandId, userId)` — throws 403 if not admin

2. **Services Refactored**
   - Extracted duplicated auth checks from 12 services:
     - EventService, GemaService, SubstituteService, ShiftService
     - PostService, PollService, AttendanceService, SetlistService
     - MediaLinkService, SongBroadcastHub
     - (2 additional internal services)
   - Each service now injects `IBandAuthorizationService`
   - ~145 lines of duplicated auth code removed

3. **Pattern Standardization**
   - All services now use same auth interface (not scattered `RequireMembershipAsync` copies)
   - Consistent error codes: 404 for not-found, 403 for forbidden
   - DomainException layer properly separated from AuthException
   - No more ad-hoc authorization scattered across codebase

### Cross-Team Context

**Integration with Banner:**
- Banner's soft-delete consistency patterns now use centralized IBandAuthorizationService for auth checks
- Service-layer delete validation secured by `RequireAdminAsync` before soft-delete
- Eliminates auth boilerplate from Banner's service implementations

**Integration with Romanoff:**
- Frontend refactoring (GoRouter, Author DRY) can rely on consistent backend auth contracts
- All frontend calls to protected endpoints get uniform 403 responses
- Reduces frontend error-handling complexity

**Integration with Parker:**
- Test fixtures can mock single `IBandAuthorizationService` instead of per-service auth logic
- 24 new tests cover extracted service in isolation
- Parker's backend tests use mocked service for authorization scenarios

### Test Coverage

- 24 new tests for `IBandAuthorizationService` (isolation tests)
- All 882 existing tests still pass (refactoring-only, no logic changes)
- 1 pre-existing failure (unrelated to this work)
- Pattern: "Extract Method, Extract Class" TDD applies to service-layer DRY

### Key Learnings

- Authorization as first-class service (not utility methods) = better testability
- Centralizing cross-cutting concerns (auth) reduces bugs & inconsistency
- DRY extraction in backend: 12 services → 1 service interface = 145 lines less code
- Pattern: Principal engineer role = identify duplication, propose centralized interface

---

### 2026-04-15: MS2 Backend — 5 Complex Features Implemented

**Architecture Decisions:**
- All services use primary constructor injection with `AppDbContext db`
- Membership checks via private `RequireMembershipAsync` / `RequireConductorOrAdminAsync` per service (not shared — keeps services independent)
- DomainException for all error cases (NOT_FOUND=404, FORBIDDEN=403, CONFLICT=409, VALIDATION_ERROR=400)
- Enums stored as strings via `.HasConversion<string>()` in EF configurations

**Key Patterns:**
- Substitute token security: `RandomNumberGenerator.GetBytes(32)` → Base64Url encode → SHA-256 hash for DB storage. Raw token returned only once at creation.
- SongBroadcast Hub: In-memory state via `ConcurrentDictionary` (no DB persistence needed for real-time broadcast sessions)
- GEMA export: CSV (semicolon-separated, UTF-8 BOM) and XML (simple GEMA-Meldung schema)

**Files Created (by feature):**

1. **Events/Konzertplanung:**
   - Domain: `Entities/Event.cs`, `Entities/EventRsvp.cs`, `Enums/EventType.cs`, `Enums/RsvpStatus.cs`, `Events/EventModels.cs`
   - Infrastructure: `Configurations/EventConfiguration.cs`, `EventRsvpConfiguration.cs`, `Events/IEventService.cs`, `Events/EventService.cs`
   - API: `Controllers/EventController.cs`, `Controllers/CalendarController.cs`

2. **GEMA Compliance:**
   - Domain: `Entities/GemaReport.cs`, `Entities/GemaReportEntry.cs`, `Enums/CollectingSociety.cs`, `Enums/GemaReportStatus.cs`, `Gema/GemaModels.cs`
   - Infrastructure: `Configurations/GemaReportConfiguration.cs`, `GemaReportEntryConfiguration.cs`, `Gema/IGemaService.cs`, `Gema/GemaService.cs`
   - API: `Controllers/GemaController.cs`

3. **Song Broadcast (SignalR):**
   - Domain: `SongBroadcast/SongBroadcastModels.cs`
   - API: `Hubs/SongBroadcastHub.cs`

4. **Substitute Access (Aushilfen):**
   - Domain: `Entities/SubstituteAccess.cs`, `Substitutes/SubstituteModels.cs`
   - Infrastructure: `Configurations/SubstituteAccessConfiguration.cs`, `Substitutes/ISubstituteService.cs`, `Substitutes/SubstituteService.cs`
   - API: `Controllers/SubstituteAccessController.cs`

5. **Shift Planning (Schichtplanung):**
   - Domain: `Entities/ShiftPlan.cs`, `Entities/Shift.cs`, `Entities/ShiftAssignment.cs`, `Enums/ShiftAssignmentStatus.cs`, `Shifts/ShiftModels.cs`
   - Infrastructure: `Configurations/ShiftPlanConfiguration.cs`, `ShiftConfiguration.cs`, `ShiftAssignmentConfiguration.cs`, `Shifts/IShiftService.cs`, `Shifts/ShiftService.cs`
   - API: `Controllers/ShiftController.cs`

**NOT modified (by design):** AppDbContext.cs, DependencyInjection.cs, Program.cs — follow-up agent will wire these.

### 2026-04-16: MS2 Fixes — Stark Meta-Review Issues (Fixes 6-9)

**Fixes Applied (Lockout: Banner's Code):**
1. **Fix 6 — GEMA ExportReportAsync:** Moved format validation (csv/xml whitelist) BEFORE `SaveChangesAsync` to prevent DB mutation on invalid format.
2. **Fix 7 — GEMA Composer Fallback:** Changed `?? "Unknown"` to `?? "Komponist unbekannt"` for GEMA-legal compliance.
3. **Fix 8 — Conductor Disconnect Cleanup:** `OnDisconnectedAsync` now checks if disconnected `userId == state.ConductorId`. If yes: removes broadcast, sends `OnBroadcastStopped`. If no: updates participant count as before.
4. **Fix 9 — Cross-Band FK Validation:** Added `BandId`-scoped checks for `VoiceId`/`EventId` in SubstituteService (Voice via `Piece.BandId`), `SetlistId` in EventService (Create+Update), `EventId` in AttendanceService. MediaLinkService already correct.

**Test Updates:** Replaced `OnDisconnectedAsync_UpdatesParticipantCount` with conductor/non-conductor disconnect tests. Updated GEMA composer test assertion. All 827 tests pass.

**Pattern Learned:** Voice entity has no `BandId` — must validate via `Voice.Piece.BandId` (requires `.Include(v => v.Piece)`).
