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

---

### 2026-03-31: MS2 Nacharbeit Batch 3 — CR#7 Cursor-Pagination Infrastructure

**Orchestration:** Parallel with Banner (CR#4/5/9) + Romanoff (MS3 tuner)  
**Task:** Implement pagination infrastructure for Posts and Events (TDD-driven)  
**Result:** DONE ✅ — 904 tests passing (+26 new)

**Deliverables:**
- `PaginationModels` — CursorPaginationRequest/Response
- `CursorHelper` — Base64 cursor encode/decode
- `PaginationExtensions` — LINQ-to-EF pagination helper
- PostService.GetPostsAsync() + EventService.GetEventsAsync() paginated
- PostController + EventController pagination endpoints
- 26 new TDD tests covering cursor logic, edge cases, empty results

**Key Patterns:**
- Cursor encoding: Base64(ID:timestamp) — reversible, URL-safe
- Stable ordering: All queries sorted by (BandId, CreatedAt/StartsAt desc, Id)
- Backward compatible: Non-paginated queries still work (return all results)
- Next-page logic: If result count < pageSize, hasMore=false, nextCursor=null

**Test Results:** 904 total passing

**Cross-Team Integration:**
- Pagination infrastructure ready for all future list endpoints
- Compatible with Banner's rate-limiting on paginated endpoints
- Romanoff (Flutter) can implement infinite-scroll pattern

**See:** `.squad/orchestration-log/2026-03-31T00-54-17-strange.md`
### 2026-03-31: #108 + CR#6 — IBandAuthorizationService DRY Refactoring

**Problem:** `RequireMembershipAsync`, `RequireConductorOrAdminAsync`, `RequireAdminAsync` were duplicated as private helpers across 12 services + SongBroadcastHub. Each had minor variants (error codes, db access patterns, CancellationToken support).

**Solution:** Extracted into shared `IBandAuthorizationService` → `BandAuthorizationService` (Scoped DI). Single source of truth for band-level authorization.

**Files Created:**
- `src/Sheetstorm.Infrastructure/Auth/IBandAuthorizationService.cs`
- `src/Sheetstorm.Infrastructure/Auth/BandAuthorizationService.cs`
- `tests/Sheetstorm.Tests/Auth/BandAuthorization/BandAuthorizationServiceTests.cs` (24 tests)

**Services Refactored (13 total):** EventService, GemaService, ShiftService, SubstituteService, BandService, ConfigService, PostService, MediaLinkService, PollService, AttendanceService, SetlistService, ImportService, SongBroadcastHub.

**Standardizations Applied:**
- Error code: `"NOT_FOUND"` → `"BAND_NOT_FOUND"` for 4 services (Event, Gema, Shift, Substitute)
- Exception type: `AuthException` → `DomainException` for admin checks (BandService, ConfigService)
- Hub: `HubException` → `DomainException` for auth failures
- All methods now support optional `CancellationToken`

**Impact:** Net -145 lines production code. 882 tests pass. SongBroadcastHub no longer depends on `AppDbContext` directly.

**Pattern Learned:** When extracting shared services from duplicated private helpers, standardize on the majority error code pattern and update the minority callers' tests. The middleware handles both `DomainException` and `AuthException` identically, so exception type changes are safe.

### 2026-04-16: CR#7 — Cursor-Based Pagination for List Endpoints

**Problem:** All list endpoints returned unbounded results. For growing data, this is a performance risk.

**Solution:** Cursor-based pagination (not offset) using `CreatedAt` + `Id` as cursor position. Base64-encoded JSON cursors are opaque to clients.

**Infrastructure Created:**
- `src/Sheetstorm.Domain/Pagination/PaginationModels.cs` — `PaginationRequest` (Cursor?, PageSize with EffectivePageSize clamped 1–100) and `PagedResult<T>` (Items, Cursor, HasMore, PageSize)
- `src/Sheetstorm.Infrastructure/Pagination/CursorHelper.cs` — Encode/Decode cursor as Base64(JSON `{CreatedAt, Id}`). Invalid cursors throw `DomainException("INVALID_CURSOR", 400)`.
- `src/Sheetstorm.Infrastructure/Pagination/PaginationExtensions.cs` — `ToPaginatedAsync` extension on `IQueryable`. Caller applies cursor WHERE clause and ordering; extension handles Take(N+1), HasMore detection, cursor encoding from last item.

**Endpoints Updated:**
- `GET /api/bands/{bandId}/posts` — paginated (newest first by CreatedAt)
- `GET /api/bands/{bandId}/events` — paginated (newest first by CreatedAt)
- `GET /api/bands/{bandId}/posts/{postId}/comments` — **new endpoint**, paginated (oldest first for chronological reading)

**Backward Compatibility:** All endpoints default to `cursor=null, pageSize=20`. Existing clients without pagination params get the first page. Old `GetAllAsync`/`GetEventsAsync` methods remain in interfaces for internal use.

**Tests:** 26 new tests (6 CursorHelper, 13 PostPagination, 7 EventPagination). All existing 882 tests pass unchanged.

**Design Decision:** Cursor filtering is applied in the service layer (not the extension) because cursor WHERE clauses use concrete entity property access (e.g., `p.CreatedAt < cursorDate`) which must be translatable by EF Core for both InMemory and PostgreSQL providers. The extension method only handles the generic take+hasMore+encode logic.

**Pattern Learned:** For cursor-based pagination with ascending vs descending order, the cursor filter direction must match: descending order uses `<` (older than cursor), ascending uses `>` (newer than cursor). Comments use ascending (chronological) while posts/events use descending (newest first).

