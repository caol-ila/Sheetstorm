# Project Context

- **Owner:** Thomas
- **Project:** Sheetstorm — Notenmanagement-App für Blaskapellen
- **Stack:** Flutter 3.41.5 + ASP.NET Core 10 LTS + PostgreSQL + SQLite
- **Role:** Principal Backend Engineer — übernimmt die komplexesten Backend-Aufgaben
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. -->

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

### 2026-03-31: MS3 — Annotation Sync Backend (TDD)

**What was built:**
- REST controller for annotation CRUD + delta sync (AnnotationController.cs)
- DI wiring for IAnnotationSyncService in DependencyInjection.cs
- 33 passing tests (18 service + 8 hub + 7 controller)

**Architecture (from Stark's spec):**
- Op-Log + LWW per element — no CRDT, no OT
- Annotation container = one per (PiecePageId, Level, VoiceId?) tuple
- AnnotationElement = individual graphic element with version + soft-delete
- Optimistic concurrency: 409 Conflict when client version != server version
- SignalR groups: `annotation-voice-{bandId}-{voiceId}-{piecePageId}` and `annotation-orchestra-{bandId}-{piecePageId}`
- REST is source of truth; SignalR is real-time notification shortcut

**Key files (created/modified):**
- `src/Sheetstorm.Api/Controllers/AnnotationController.cs` — REST endpoints
- `src/Sheetstorm.Infrastructure/DependencyInjection.cs` — DI registration
- `tests/Sheetstorm.Tests/Annotations/AnnotationControllerTests.cs` — controller tests

**Pre-existing files (already committed by prior team member):**
- Domain entities: `Annotation.cs`, `AnnotationElement.cs`, enums
- Service: `AnnotationSyncService.cs`, `IAnnotationSyncService.cs`
- Hub: `AnnotationSyncHub.cs`
- Tests: `AnnotationSyncServiceTests.cs`, `AnnotationSyncHubTests.cs`
- EF configs: `AnnotationConfiguration.cs`, `AnnotationElementConfiguration.cs`

**Patterns used:**
- Controller uses `IAnnotationSyncService` interface (mock in tests, scoped DI in production)
- `RequireMembershipAsync` per service call (not shared, per Sheetstorm convention)
- Orchestra annotations restricted to Conductor/Admin role
- Soft-delete for sync consistency (deleted elements still sync to clients)
- Delta sync: `SyncElements(sinceVersion)` returns only elements with version > sinceVersion

