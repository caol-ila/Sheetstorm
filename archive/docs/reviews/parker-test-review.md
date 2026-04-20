# Test Quality Review — Parker (QA Engineer)
**Datum:** 2025-01-24T23:45:00Z  
**Reviewer:** Parker  
**Model:** claude-sonnet-4.5  
**Scope:** Tests (Backend + Frontend, Coverage-Analyse)

## Zusammenfassung

Die MS2-Testbasis zeigt **solide Grundlagen mit kritischen Lücken**. Backend-Tests (493 Tests) folgen konsistenten Patterns mit starker RBAC-Abdeckung. Frontend-Tests (660 Tests) decken Notifier-Logik gut ab, aber echte Integration fehlt komplett. **Kritische Schwächen:** Keine Capacity/Rate-Limiting-Tests, keine OAuth-Calendar-Sync-Tests, fehlende GEMA-Export-Failure-Szenarien, keine Token-Enumeration-Tests für Aushilfen. Test-zu-Spec-Mapping zeigt 15-20% Feature-Lücken. Vor Merge müssen **7 kritische Issues** behoben werden.

---

## Coverage-Matrix

| Feature (aus Spec) | Backend Tests | Frontend Tests | Coverage | Lücken |
|-------------------|---------------|----------------|----------|--------|
| **Anwesenheit** | ✅ AttendanceService (23), Controller (12) | ✅ attendance_notifier (34) | **Hoch** | Export-Job-Failure-Handling fehlt; Concurrent-Export-Tests fehlen |
| **Kommunikation (Posts)** | ✅ PostService (29), Controller (20) | ✅ post_notifier (27) | **Hoch** | Pin-Limit-Race-Condition nicht getestet; Register-Deletion-Cascade fehlt |
| **Kommunikation (Polls)** | ✅ PollService (24), Controller (14) | ✅ poll_notifier (31) | **Hoch** | Expiry-während-Vote nicht getestet; Multi-Select-Race-Condition fehlt |
| **Konzertplanung (Events)** | ✅ EventService (35), Controller (25), Calendar (15) | ✅ event_notifier (17), calendar_notifier (17) | **Mittel** | ❌ **KRITISCH:** Keine OAuth-Calendar-Sync-Tests; Recurring-Event-Edge-Cases fehlen |
| **Setlist** | ✅ SetlistService (41), Controller (31) | ✅ setlist_notifier (26), setlist_player (20) | **Hoch** | Concurrent-Reorder-Rollback nicht getestet; 100+-Entry-Performance fehlt |
| **Schichtplanung** | ✅ ShiftService (25), Controller (19) | ✅ shift_notifier (47) | **Mittel** | ❌ **KRITISCH:** Capacity-Overflow-Tests fehlen (Spec-Widerspruch Admin-Override); Overlap-Warning nicht getestet |
| **GEMA Compliance** | ✅ GemaService (30), Controller (25) | ✅ gema_notifier (11) | **Mittel** | ❌ **KRITISCH:** XML-Export-Filesystem-Failure fehlt; AI-Rate-Limiting nicht getestet; Schema-Change-Resilience fehlt |
| **Media Links** | ✅ MediaLinkService (23), Controller (16) | ✅ media_link_notifier (14) | **Hoch** | oEmbed-Failure-Fallback nicht getestet; AI-Suggestion-Rate-Limit fehlt |
| **Song Broadcast** | ✅ SongBroadcastHub (26) | ✅ broadcast_notifier (24) | **Mittel** | Two-Conductor-Collision nicht getestet; Network-Latency-Simulation fehlt; Long-Polling-Fallback nicht getestet |
| **Aushilfen** | ✅ SubstituteService (19), Controller (10) | ✅ substitute_notifier (40) | **Niedrig** | ❌ **KRITISCH:** Token-Enumeration/Brute-Force nicht getestet; Rate-Limiting (20/min/IP) fehlt; Offline-Cache-Behavior fehlt |
| **Annotationen** | ❌ **Keine Backend-Tests** | ✅ Umfangreich (166 Tests) | **Niedrig** | ❌ **KRITISCH:** Backend-API komplett ungetestet (Permission, Persistence, Conductor-Lock) |
| **Import/Noten** | ✅ ImportService (32), EdgeCases (11), Controller (8), Pieces (16) | ❌ **Keine Frontend-Tests** | **Mittel** | Frontend-Upload-Flow, AI-Metadata-Retry-UI fehlt |
| **Stimmenauswahl** | ✅ VoiceService (23), Taxonomy (13), Normalize (15) | ❌ **Keine dedizierten Tests** | **Mittel** | Frontend-Voice-Selection-UI fehlt |
| **Performance Mode** | ❌ **Keine Backend-Tests** | ✅ Sehr umfangreich (178 Tests) | **Mittel** | Backend-Page-Service ungetestet; Zoom-Memory-Sync nicht getestet |
| **Band/Kapelle** | ✅ BandService (53) | ❌ **Keine dedizierten Tests** | **Mittel** | Frontend-Invitation-Flow fehlt; Voice-Mapping-UI fehlt |
| **Auth/Onboarding** | ✅ AuthService (15) | ❌ **Keine dedizierten Tests** | **Mittel** | Frontend-Email-Verification-Flow fehlt; Refresh-Token-Reuse-Detection-UI fehlt |

**Legende:**  
✅ = Vorhanden | ❌ = Fehlt | **Coverage:** Hoch (>80%), Mittel (50-80%), Niedrig (<50%)

---

## Kritische Issues (MUST FIX vor Merge)

### K1: Aushilfen — Token-Enumeration nicht getestet
- **Dateien:** `tests/Sheetstorm.Tests/Substitutes/SubstituteServiceTests.cs`, `SubstituteControllerTests.cs`
- **Problem:** Spec fordert "Rate limit 20 requests/min/IP" und "256-bit token" gegen Brute-Force. Keine Tests für Token-Enumeration-Schutz, Rate-Limiting oder Token-Sicherheit vorhanden.
- **Fix:** Füge Tests hinzu:
  - `ValidateAccessAsync_BruteForceAttempts_ReturnsRateLimitError`
  - `ValidateAccessAsync_SequentialInvalidTokens_BlocksAfter20`
  - `CreateAccessAsync_GeneratesSecureToken_256Bit`
- **Begründung:** Sicherheitslücke — unautorisierter Zugang zu Noten ist DSGVO-kritisch und ein reales Angriffsrisiko.

### K2: Schichtplanung — Capacity-Overflow-Verhalten unklar
- **Dateien:** `tests/Sheetstorm.Tests/Shifts/ShiftServiceTests.cs`
- **Problem:** Spec enthält Widerspruch: Story sagt "Admin kann Kapazität überschreiten", aber API/Edge-Cases sagen "409 bei Overflow". Tests decken nur 409-Fall ab (`ShiftFull`), aber nicht Admin-Override.
- **Fix:** 
  1. Klären: Darf Admin override oder nicht?
  2. Implementiere Tests für geklärtes Verhalten: `AssignMusicianAsync_AdminOverride_ExceedsCapacity` oder `AssignMusicianAsync_AdminAttemptOverflow_Returns409`
- **Begründung:** Verhalten ist undefiniert. In Prod könnte das zu Race-Conditions oder inkonsistenten Zuständen führen.

### K3: GEMA Export — Filesystem-Failure nicht getestet
- **Dateien:** `tests/Sheetstorm.Tests/Gema/GemaServiceTests.cs`
- **Problem:** Spec erwähnt "Export filesystem failure" als Edge Case. Tests prüfen nur Happy Path für CSV/XML/PDF-Export (`ExportReport_ValidFormat_ReturnsContent`), aber keine Failure-Szenarien.
- **Fix:** Füge Tests hinzu:
  - `ExportReportAsync_FilesystemError_ThrowsDomainException`
  - `ExportReportAsync_ReportStatusRemainsExported_OnSubsequentFailure` (idempotency)
- **Begründung:** GEMA-Reports sind rechtlich bindend. Ein stiller Export-Fehler führt zu Compliance-Verstößen und Strafen.

### K4: Konzertplanung — OAuth Calendar Sync komplett ungetestet
- **Dateien:** **Neu:** `tests/Sheetstorm.Tests/Events/CalendarSyncServiceTests.cs` (fehlt)
- **Problem:** Spec fordert bidirektionale Google/Apple/Outlook-Calendar-Sync mit OAuth-Token-Refresh. **Keinerlei Tests** für OAuth, Token-Expiry, Sync-Fenster, oder External-Calendar-Deletion vorhanden.
- **Fix:** Erstelle `CalendarSyncServiceTests.cs` mit:
  - `SyncToExternalCalendar_TokenExpired_RefreshesAndRetries`
  - `SyncFromExternalCalendar_CalendarDeleted_HandlesGracefully`
  - `SyncBidirectional_ConflictDetection_PrefersLocalChanges`
- **Begründung:** OAuth-Flows sind notorisch fehleranfällig. Ohne Tests ist Production-Rollout ein Blindflug mit hohem Nutzer-Frustrations-Risiko.

### K5: Annotationen Backend — 0 Tests für gesamte API
- **Dateien:** **Neu:** `tests/Sheetstorm.Tests/Annotations/AnnotationServiceTests.cs`, `AnnotationControllerTests.cs` (fehlen)
- **Problem:** Frontend hat 166 Annotation-Tests, aber **Backend-API ist komplett ungetestet**. Keine Tests für Permission-Checks (Conductor-Lock), Persistence, Layer-Visibility-Server-Enforcement, oder SVG-Path-Serialization.
- **Fix:** Erstelle Backend-Tests:
  - `SaveAnnotation_NonConductor_CannotModifyOrchestraLayer`
  - `GetAnnotations_PrivateLayer_OnlyOwnerCanRead`
  - `SaveAnnotation_InvalidSVGPath_ReturnsValidationError`
- **Begründung:** Frontend-Tests ohne Backend-Coverage = unvollständige Verifikation. Permissions auf Client-Seite sind nicht ausreichend (Security by Obscurity).

### K6: Song Broadcast — Concurrent-Conductor-Collision nicht getestet
- **Dateien:** `tests/Sheetstorm.Tests/SongBroadcast/SongBroadcastHubTests.cs`
- **Problem:** Spec erwähnt "Two conductors start at same time (session collision)" als Edge Case. Test prüft nur sequentiellen Collision-Fall (`StartBroadcast_AlreadyActiveBroadcast_ThrowsHubException`), aber nicht gleichzeitige Race-Condition.
- **Fix:** Füge Test hinzu:
  - `StartBroadcast_TwoConductorsConcurrent_OnlyOneSucceeds`
- **Begründung:** Race-Conditions in Live-Performance-Szenarien können zu doppelten Sessions, geteiltem State oder Connection-Chaos führen.

### K7: Kommunikation — Pin-Limit-Race-Condition nicht getestet
- **Dateien:** `tests/Sheetstorm.Tests/Communication/PostServiceTests.cs`
- **Problem:** Spec fordert max. 3 pinned posts. Test prüft sequentielles 4. Pin (`PinPost_AlreadyThreePinned_ThrowsConflict`), aber nicht concurrent Pin-Requests.
- **Fix:** Füge Test hinzu:
  - `PinPost_ConcurrentRequests_OnlyThreeSucceed` (verwende `Task.WhenAll` für parallel Pins)
- **Begründung:** In-Memory-DB-Tests verschleiern Race-Conditions. In Prod mit echtem DB-Concurrency kann das zu >3 pinned posts führen.

---

## Empfehlungen (SHOULD — nice-to-have)

### E1: Test-Naming-Konsistenz verbessern
- **Beobachtung:** Backend nutzt `Method_Scenario_Outcome` (z.B. `GetAllAsync_RegularMember_ReturnsOwnRecordsOnly`). Frontend hat inkonsistente Namen (z.B. `'Pläne werden initial geladen'` vs `'createPlan erstellt neuen Schichtplan'`).
- **Empfehlung:** Frontend auf konsistentes Schema umstellen: `featureName — Scenario — Expected Outcome`.
- **Nutzen:** Bessere Lesbarkeit bei Test-Failures; einfacheres Mapping zu Requirements.

### E2: Frontend-Integration-Tests hinzufügen
- **Beobachtung:** Alle 660 Frontend-Tests sind Unit/Widget-Tests. Keine echten Integration-Tests (z.B. End-to-End-Flows über mehrere Screens).
- **Empfehlung:** Füge Integration-Tests hinzu für kritische User-Journeys:
  - Anwesenheit erfassen → Statistik anzeigen → Export
  - Event erstellen → Zusage → Ersatzmusiker anfordern
  - Setlist erstellen → Play Mode → Annotationen
- **Nutzen:** Deckt Integrations-Bugs ab, die Unit-Tests nicht finden (z.B. Navigation-State-Loss, Inkonsistente-Provider-Scopes).

### E3: Performance-Tests automatisieren
- **Beobachtung:** Nur `performance_mode_performance_test.dart` (15 Tests) prüft Timing-Thresholds. Keine Performance-Tests für Backend (z.B. 100+ Setlist-Entries, 1000+ Attendance-Records).
- **Empfehlung:** Füge Backend-Performance-Tests hinzu:
  - `GetAllAsync_1000AttendanceRecords_CompletesWithin500ms`
  - `ReorderEntries_100Entries_CompletesWithin1Second`
- **Nutzen:** Früherkennung von Performance-Regressionen vor Production.

### E4: Test-Data-Builder statt Helper-Methoden
- **Beobachtung:** Tests nutzen private Helper wie `SeedMemberAsync()`, `SeedPollAsync()`. Diese sind nicht wiederverwendbar über Test-Dateien hinweg.
- **Empfehlung:** Erstelle zentrale Builder-Klassen: `MusicianBuilder`, `BandBuilder`, `EventBuilder` mit Fluent-API.
- **Nutzen:** Reduziert Duplikation; erleichtert Setup komplexer Test-Szenarien.

### E5: Golden-Tests für kritische UI-Komponenten
- **Beobachtung:** Keine Golden-Tests (Screenshot-Regression-Tests) vorhanden.
- **Empfehlung:** Füge Golden-Tests hinzu für:
  - Performance-Mode-Overlays (Night-Mode, Sepia-Mode)
  - Annotation-Toolbar (verschiedene Tool-Selections)
  - Setlist-Player (Play/Pause-States)
- **Nutzen:** Verhindert ungewollte visuelle Regressionen.

### E6: Test-Coverage-Metriken tracken
- **Beobachtung:** Keine automatische Coverage-Messung sichtbar (z.B. via Coverlet für Backend, coverage package für Frontend).
- **Empfehlung:** Integriere Coverage-Reporting in CI:
  - Backend: `dotnet test --collect:"XPlat Code Coverage"`
  - Frontend: `flutter test --coverage`
  - Setze Threshold: mindestens 80% Line-Coverage.
- **Nutzen:** Objektive Metrik für Test-Qualität; verhindert Coverage-Erosion.

### E7: Mocking-Strategie überdenken
- **Beobachtung:** Backend nutzt In-Memory-DB (EF Core) für Services (gut), aber Controller-Tests mocken Services komplett (weniger wertvoll).
- **Empfehlung:** Erwäge Controller-Integration-Tests mit echten Services + In-Memory-DB statt reinem Mocking. Mocke nur externe Dependencies (Email, Storage, OAuth).
- **Nutzen:** Controller-Tests werden aussagekräftiger (testen mehr als nur Service-Delegation).

### E8: Error-Message-Assertions schärfen
- **Beobachtung:** Tests prüfen nur `ErrorCode` und `StatusCode`, aber nicht `Message`-Inhalte (z.B. `Assert.Equal("FORBIDDEN", ex.ErrorCode)`).
- **Empfehlung:** Füge Message-Assertions hinzu wo sinnvoll:
  - `Assert.Contains("already active", ex.Message)` (bereits in SongBroadcastHub)
  - Nutze diese Praxis konsistent.
- **Nutzen:** Verifiziert User-Facing-Error-Messages; bessere Debugging-Info bei Test-Failures.

---

## Fehlende Tests (Gap-Analyse)

### Backend Gaps
1. **Attendance:** Export-Job-Failure-Handling (PDF-Generation fehlschlägt, Export-Link-Expiry)
2. **Events:** OAuth-Calendar-Sync (Token-Refresh, Sync-Conflicts, External-Calendar-Deletion)
3. **Events:** Recurring-Event-Edge-Cases (Einzelne Occurrence ändern/ablehnen)
4. **Setlists:** Concurrent-Reorder-Rollback (Zwei User reordern gleichzeitig)
5. **Setlists:** Performance-Test für 100+ Entries
6. **Shifts:** Capacity-Overflow-Verhalten (Admin-Override vs. 409-Conflict)
7. **Shifts:** Overlap-Warning (Warnung aber kein Hard-Block)
8. **GEMA:** XML-Export-Filesystem-Failure
9. **GEMA:** AI-Rate-Limiting (Search-API)
10. **GEMA:** Schema-Change-Resilience (GEMA-XML v2.1 statt v2.0)
11. **GEMA:** Same-Work-Multiple-Bands-Cache
12. **MediaLinks:** oEmbed-Fetch-Failure-Fallback
13. **MediaLinks:** AI-Suggestion-Rate-Limiting
14. **SongBroadcast:** Two-Conductor-Concurrent-Collision
15. **SongBroadcast:** Network-Latency-Simulation (>1000ms)
16. **SongBroadcast:** Long-Polling-Fallback (WebSocket-Failure)
17. **Substitutes:** Token-Enumeration/Brute-Force-Protection
18. **Substitutes:** Rate-Limiting (20 req/min/IP)
19. **Substitutes:** Offline-Cache-Behavior (Web-Viewer)
20. **Polls:** Expiry-während-Vote (User votet, Poll expired während Request)
21. **Polls:** Multi-Select-Race-Condition (Duplicate-Vote)
22. **Posts:** Pin-Limit-Race-Condition (Concurrent 4. Pin)
23. **Posts:** Register-Deletion-Cascade (Register gelöscht, Posts bleiben)
24. **Annotations:** **Gesamte Backend-API** (Service + Controller)
25. **Config:** Multi-Device-Sync-Conflict (Zwei Devices ändern Config gleichzeitig)

### Frontend Gaps
26. **Import:** Frontend-Upload-Flow (File-Picker, Progress, AI-Metadata-Retry)
27. **Voices:** Frontend-Voice-Selection-UI
28. **Band:** Frontend-Invitation-Flow (QR-Code, Join-Link)
29. **Band:** Frontend-Voice-Mapping-UI (Drag-Drop-Reorder)
30. **Auth:** Frontend-Email-Verification-Flow
31. **Auth:** Frontend-Refresh-Token-Reuse-Detection-UI
32. **Performance-Mode:** Backend-Page-Service (PDF-Rendering, Caching)
33. **Performance-Mode:** Zoom-Memory-Sync (Multi-Device)
34. **Integration-Tests:** End-to-End-Flows über mehrere Screens
35. **Golden-Tests:** Visual-Regression-Tests für kritische UI-Komponenten

---

## Positives

### Backend
1. **Konsistente Patterns:** Alle Service-Tests nutzen In-Memory-DB; Controller-Tests mocken sauber mit NSubstitute.
2. **RBAC-Coverage exzellent:** Jedes Feature testet Permissions für alle Rollen (Conductor, Admin, Section Leader, Musician).
3. **Edge-Case-Awareness:** Import-Tests haben dedizierte `ImportEdgeCaseTests.cs` (11 Tests für Empty-Streams, Corrupt-Files, Non-Seekable-Streams).
4. **Domain-Exception-Propagation:** Controller-Tests verifizieren konsistent, dass Service-Exceptions korrekt propagiert werden.
5. **Isolated-DB per Test:** Jeder Test bekommt eigene GUID-DB → keine Test-Interdependenzen.
6. **Helper-Methoden reduzieren Boilerplate:** `SeedMemberAsync()`, `SeedPollAsync()` etc. machen Tests lesbarer.
7. **Band-Scoped-Access-Tests:** Jedes Feature verifiziert, dass Bands isoliert sind (kein Cross-Band-Data-Leak).

### Frontend
8. **Sehr hohe Notifier-Coverage:** 660 Tests decken State-Management umfassend ab.
9. **Performance-Mode herausragend:** 178 Tests inkl. Performance-Benchmarks (Timing-Thresholds).
10. **Annotations umfassend:** 166 Tests decken alle Edge-Cases (Empty-Paths, Long-Text, Pressure-Sensitivity, Undo/Redo-Stack).
11. **Test-Helpers durchdacht:** Helper-Funktionen wie `_makeNotifier()`, `_setupList()` reduzieren Boilerplate.
12. **Null-Safety-Tests:** Tests verifizieren explizit `null`-Handling (z.B. `offen: null` in Attendance).
13. **Enum-Coverage:** Tests prüfen alle Enum-Werte (z.B. `SetlistTyp`, `EventType`, `ShiftStatus`).

---

## Bewertung

### **Coverage:** ⭐⭐⭐☆☆ (3/5)
- **Kommentar:** 80% der Features haben Tests, aber kritische Gaps (OAuth-Sync, Token-Security, Annotations-Backend, Integration-Tests) senken die Bewertung. Backend-zu-Frontend-Coverage ist ungleichmäßig (Import: Backend ja, Frontend nein; Annotations: Backend nein, Frontend ja).

### **Test-Qualität:** ⭐⭐⭐⭐☆ (4/5)
- **Kommentar:** Backend-Tests folgen Best-Practices (AAA-Pattern, In-Memory-DB, Isolation). Frontend-Tests sind solide, aber ohne Integration-Tests. Test-Names könnten konsistenter sein. Error-Assertions könnten schärfer sein (Message-Inhalte prüfen).

### **Edge Cases:** ⭐⭐⭐☆☆ (3/5)
- **Kommentar:** Gute Edge-Case-Awareness (Empty-States, Null-Values, Boundaries), aber **kritische Lücken bei Concurrency, Rate-Limiting und Security-Edge-Cases**. Import-Edge-Cases vorbildlich; Substitutes/Shifts/GEMA haben Lücken.

### **Testbarkeit:** ⭐⭐⭐⭐☆ (4/5)
- **Kommentar:** Code ist gut testbar designed (DI, Services/Controllers getrennt, In-Memory-DB-Support). Aber: OAuth-Sync, Storage, Email sind mocked → schwer zu testen. SignalR-Hub-Tests zeigen gute Mock-Nutzung. Frontend-Provider-Scoping gut testbar.

---

## Abschluss-Statement

Die Testbasis zeigt **professionelle Arbeit mit Schwerpunkt auf Happy-Path und RBAC**. Die 7 kritischen Issues (Token-Security, OAuth-Sync, Capacity-Overflow, GEMA-Export-Failure, Annotations-Backend, Concurrent-Broadcast, Pin-Race) müssen vor Merge behoben werden. Ohne diese Fixes ist das Produktions-Risiko zu hoch (Security, Compliance, Race-Conditions). Nach Behebung der kritischen Issues und Hinzufügen von Integration-Tests erreicht die Testbasis **Production-Ready-Status**.

**Nächste Schritte:**
1. Kritische Issues K1-K7 beheben (geschätzt: 3-4 Tage)
2. Frontend-Integration-Tests hinzufügen (geschätzt: 2 Tage)
3. Coverage-Reporting in CI integrieren (geschätzt: 0.5 Tage)
4. Test-Lücken aus Gap-Analyse priorisieren und schrittweise schließen

**Parker's Verdict:** ⚠️ **NOT READY FOR MERGE** — 7 critical issues MUST be fixed. After fixes: **READY WITH CONFIDENCE**.
