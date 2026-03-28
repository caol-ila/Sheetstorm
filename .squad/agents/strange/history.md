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
