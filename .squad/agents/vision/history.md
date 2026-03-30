# Project Context

- **Owner:** Thomas
- **Project:** Sheetstorm — Notenmanagement-App für Blaskapellen
- **Stack:** Flutter 3.41.5 + ASP.NET Core 10 LTS + PostgreSQL + SQLite
- **Role:** Principal Frontend Engineer — übernimmt die komplexesten Flutter-Aufgaben
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. -->

### 2026-07-01: Echtzeit-Metronom Frontend (MS3)

**Context:** Implemented full metronome client with TDD: 106 tests, 21 files, 4012 LOC.

**Architecture:**
- `BeatCalculator` (pure math): given startTime + BPM + clockOffset → beat number, measure, downbeat. Called at ~60fps for animation.
- `ClockSyncService` (NTP-like): sliding window of 10 measurements, median filter, 2σ outlier rejection. Quality: good (<5ms RTT), acceptable (5-20ms), poor (>20ms).
- `MetronomeNotifier` (Riverpod keepAlive): orchestrates conductor/musician modes. Beat timer at 16ms. Only updates state when beat number changes.
- `MetronomeSignalRService`: manual SignalR JSON protocol (same pattern as `BroadcastSignalRService`). Hub at `/hubs/metronome`.
- `BeatIndicator` (CustomPainter): pulse animation via `AnimationController`, downbeat accent color.
- Route: `/app/metronome?conductor=true` for role-based view.

**Key Files:**
- `lib/features/metronome/application/beat_calculator.dart` — Pure math, 100% testable
- `lib/features/metronome/application/clock_sync_service.dart` — NTP offset calculation
- `lib/features/metronome/application/metronome_notifier.dart` — Main state management
- `lib/features/metronome/data/metronome_connection_service.dart` — SignalR service
- `lib/features/metronome/data/models/metronome_models.dart` — All models
- `lib/features/metronome/presentation/widgets/beat_indicator.dart` — Canvas beat display
- `lib/features/metronome/presentation/widgets/conductor_controls.dart` — Full conductor UI
- `lib/features/metronome/presentation/widgets/musician_view.dart` — Passive receiver UI
- `lib/features/metronome/presentation/widgets/bpm_picker.dart` — BPM slider/stepper/tap-tempo

**Decisions:**
1. Sentinel pattern for `MetronomeState.copyWith` on nullable fields (session, currentBeat, error) — learned from MS2 copyWith bug
2. `ClockSyncService` is plain Dart class (not a Riverpod notifier) — owned by `MetronomeNotifier`, no global state needed
3. Widget tests for `MusicianView` use `overrideWithValue` — notifier access only in callbacks, not in build method
4. `BeatCirclePainter.shouldRepaint` compares `isActive`, `isDownbeat`, `pulseScale`, `accentColor` — minimal repaints
5. Tap-Tempo: removes taps older than 2s, needs ≥3 taps, averages intervals

**TDD Stats:** 106 tests total (27 models, 21 beat calculator, 13 clock sync, 17 notifier, 7 beat indicator, 10 BPM picker, 8 conductor controls, 5 musician view). All green.

### 2026-04-15: MS2 Frontend Orchestration Summary — Setlist + Song Broadcast + 7 Romanoff Modules

**Overall Context:**
Parallel orchestration completed. Vision implemented 2 modules (Setlist + Song Broadcast). Romanoff completed 5 separate feature modules (Events, GEMA, Media Links, Communication, Attendance+Substitute+Shifts). Total: 9 modules, 112 files, ~50 minutes wall-clock time.

**Cross-Agent Decisions:** All architecture patterns, dependencies, and design decisions consolidated in `.squad/decisions.md` under "MS2 Frontend Implementation Decisions" section.

**Related Orchestration Logs:**
- `.squad/orchestration-log/2026-04-15T0000Z-vision-setlist-broadcast.md` — This agent's output
- `.squad/orchestration-log/2026-04-15T0017Z-romanoff-events-calendar.md`
- `.squad/orchestration-log/2026-04-15T0024Z-romanoff-gema-media.md`
- `.squad/orchestration-log/2026-04-15T0031Z-romanoff-communication.md`
- `.squad/orchestration-log/2026-04-15T0040Z-romanoff-attendance-subs-shifts.md`

**Session Log:** `.squad/log/2026-04-15T0040Z-ms2-frontend-implementation.md` — Full summary of all 9 modules, dependencies, next steps.

**Key Shared Learnings:**
1. **SignalR Manual Implementation (Vision):** Enables flexibility and clear upgrade path. If Dart SignalR package becomes available, only `BroadcastSignalRService` changes.
2. **Family Notifiers Essential:** Fine-grained state management crucial for multi-list applications. CalendarEntry + Event separation optimizes network traffic.
3. **Routes.dart Pattern:** Modular, conflict-free. Requires manual integration in app_router.dart (separate PR task).
4. **Stub .g.dart Files:** Successful compilation without build_runner. Real generation documented for post-Flutter-install.
5. **Optimistic UI Patterns:** Reactions/comments with rollback significantly improve perceived performance (no spinners).
6. **Color + Icon Accessibility:** Status indicators (green/yellow/red) with icons maintain accessibility while providing visual feedback.

---

### 2026-03-28: Setlist + Song Broadcast Feature Modules (MS2)

**Architecture Decisions:**
- Both features follow the established `features/{name}/` structure: `application/`, `data/models/`, `data/services/`, `presentation/screens/`, `presentation/widgets/`
- Riverpod 3.x codegen pattern: `@Riverpod(keepAlive: true)` for services/global state, `@riverpod` for transient/family providers
- Each feature exports a `routes.dart` with GoRoute definitions — NOT modifying `app_router.dart`
- German field names with 'ü' mapped to 'ue' in Dart identifiers (e.g., `stueckId`, `aktiveStueckId`) while JSON keys match the API contract

**Setlist Feature (`features/setlist/`):**
- Models: `Setlist`, `SetlistEntry`, `SetlistEntryType` (stueck/platzhalter/pause), `PieceInfo`, `PlatzhalterInfo`, `PauseInfo`, `SpielmodusData`
- Service: Full CRUD, entry management, reorder via PATCH, duplicate, spielmodus endpoint
- Notifiers: `SetlistListNotifier` (keepAlive, global list), `SetlistDetailNotifier` (family by setlistId), `SetlistPlayerNotifier` (family, player state machine)
- Player: Immersive fullscreen, overlay-based controls, auto-advance timer, navigation sheet
- Base API path: `/api/v1/kapellen/{bandId}/setlists`

**Song Broadcast Feature (`features/song_broadcast/`):**
- SignalR WebSocket implementation: Manual JSON protocol over `web_socket_channel` (no dedicated SignalR Dart package)
- Protocol: JSON messages separated by record separator (0x1E), message types 1 (invocation), 6 (ping/pong), 7 (close)
- Reconnect: Exponential backoff (2s, 4s, 8s, 16s, 32s), max 5 attempts
- BroadcastNotifier: keepAlive, manages conductor (broadcasting) and musician (receiving) modes
- REST endpoints at `/api/v1/broadcast/sessions` for session lifecycle
- SignalR hub at `/hubs/broadcast` for real-time events

**Key File Paths:**
- `features/setlist/data/models/setlist_models.dart` — All setlist domain models
- `features/setlist/data/services/setlist_service.dart` — REST API wrapper
- `features/setlist/application/setlist_notifier.dart` — List + Detail notifiers
- `features/setlist/application/setlist_player_notifier.dart` — Player state machine
- `features/song_broadcast/data/services/broadcast_service.dart` — REST + SignalR services
- `features/song_broadcast/application/broadcast_notifier.dart` — Broadcast state management
- `pubspec.yaml` — Added `web_socket_channel: ^3.0.2` dependency

### 2026-04-16: Routing + copyWith Fixes (Lockout Fix for Romanoff's Code)

**Context:** Stark's meta-review flagged 3 bugs in Romanoff's MS2 modules. Vision fixed as lockout reviewer.

**Fixes Applied:**
1. **Communication route path mismatch:** `/board` → `/app/board` — route must be absolute and match `AppRoutes.board` since `communicationRoutes` is spread at top level in app_router profile shell branch
2. **Poll route ordering:** Moved `:bandId/polls/create` before `:bandId/polls/:pollId` — GoRouter matches in declaration order, so literal paths must precede parameter routes
3. **AttendanceDashboardState.copyWith sentinel pattern:** Replaced `field ?? this.field` with `Object? field = _sentinel` pattern for all nullable fields (`stats`, `trend`, `startDate`, `endDate`, `eventType`, `error`). `isLoading` kept as `bool?` since it's non-nullable with default.

**Key Insight:** `copyWith(error: null)` with `error ?? this.error` silently keeps the old value — a pervasive pattern bug across many MS2 models. Sentinel pattern is the correct Dart idiom for nullable field resets.

### 2026-04-16: Auto-Scroll / Reflow Feature (MS3)

**Context:** Implemented auto-scroll controls, settings persistence, and screen integration following strict TDD.

**Architecture:**
- `AutoScrollState` + `AutoScrollNotifier` (@riverpod): stateless scroll state machine — idle/playing/paused transitions, speed factor (0.5×–3×), BPM mode, bars-per-line, lead-in bars
- `AutoScrollSettingsNotifier` (@riverpod): persistent defaults via SharedPreferences, same pattern as `PerformanceModeSettingsNotifier`
- `AutoScrollControlBar` (ConsumerWidget): compact 48px bar with Stop/Play-Pause/Reset + speed stepper [−] label [+]
- `AutoScrollWrapper` (existing, tested): Timer.periodic ~60fps scrolling with speed parameter
- Screen integration: control bar appears at bottom when auto-scroll active, gesture layer wires `onUserInteraction()` to pause-on-touch

**Key Files:**
- `lib/features/performance_mode/application/auto_scroll_notifier.dart` — State + notifier
- `lib/features/performance_mode/application/auto_scroll_settings_notifier.dart` — Persistent settings
- `lib/features/performance_mode/presentation/widgets/auto_scroll_control_bar.dart` — Control bar widget
- `lib/features/performance_mode/presentation/screens/performance_mode_screen.dart` — Integration

**Speed Calculation:**
- Manual: `speedFactor × (screenHeight / 10)` px/s
- BPM: `lineHeight / lineDuration` where `lineDuration = (60/BPM) × barsPerLine`
- All calculation tested with real-world values (120 BPM, 4 bars/line, A4 page)

**TDD Stats:** 70+ new tests (48 notifier, 8 settings, 14 widget, 4 wrapper). 252 total performance_mode tests green.

**Decisions:**
1. Separate `AutoScrollNotifier` (runtime state) from `AutoScrollSettingsNotifier` (persistence) — clean separation, settings survive app restart
2. Control bar uses `ConsumerWidget` not `StatefulWidget` — all state lives in Riverpod, no local state needed
3. `overrideWithValue` doesn't work with Riverpod 3.x codegen notifier providers for widget tests — use `UncontrolledProviderScope` + real notifier instead

### 2026-04-16: Annotation Sync Frontend Layer (MS3)

**Context:** Implemented the full real-time annotation sync frontend layer following strict TDD.

**Architecture:**
- `sync/annotation_op_model.dart` — Wire DTOs (AnnotationElementDto, BBoxDto, StrokePointDto), AnnotationOp with LWW conflict resolution, SyncVersion, ElementChangeNotification
- `sync/annotation_sync_notifier.dart` — Riverpod Notifier managing 5 sync states (disconnected/connecting/connected/syncing/error), offline op queue, remote element tracking, active editors presence, conflict info
- `sync/annotation_sync_service.dart` — Manual SignalR JSON protocol client (same pattern as BroadcastSignalRService), REST URL builders, server event parsing, reconnect with exponential backoff (1s/3s/10s/30s)
- `sync/annotation_sync_converters.dart` — Bidirectional Annotation ↔ AnnotationElementDto conversion, level/tool string mapping, shouldSync() gate
- `presentation/widgets/sync_status_indicator.dart` — ConsumerWidget showing connected/syncing/offline state with icon + pending-ops badge
- `presentation/widgets/live_edit_indicator.dart` — Active editors banner ("Max zeichnet…") + LWW conflict banner ("Änderung von X wurde übernommen")

**Key Decisions:**
1. **No shared SignalR base class yet** — mirrors BroadcastSignalRService pattern directly. If a third feature needs SignalR, extract shared base.
2. **Sentinel pattern for nullable copyWith fields** — `clearError: true` / `clearConflict: true` flags instead of `Object? = _sentinel` pattern (simpler for this state shape).
3. **REST endpoints follow `/api/bands/{bandId}/annotations/...`** — no version segment, camelCase JSON keys per API convention.
4. **Hub at `/hubs/annotation-sync`** — separate from broadcast hub.
5. **Private annotations never synced** — `shouldSync()` returns false for `AnnotationLevel.private`.
6. **Widget tests use `overrideWith(() => FakeNotifier)` pattern** — works cleanly with non-codegen NotifierProvider.

**TDD Stats:** 108 new tests (31 model, 32 notifier, 19 service, 14 integration, 12 widget). 274 total annotation tests green. Zero analyzer issues.

**Key Files:**
- `lib/features/annotations/sync/annotation_op_model.dart`
- `lib/features/annotations/sync/annotation_sync_notifier.dart`
- `lib/features/annotations/sync/annotation_sync_service.dart`
- `lib/features/annotations/sync/annotation_sync_converters.dart`
- `lib/features/annotations/presentation/widgets/sync_status_indicator.dart`
- `lib/features/annotations/presentation/widgets/live_edit_indicator.dart`

