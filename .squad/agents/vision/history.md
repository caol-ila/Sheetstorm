# Project Context

- **Owner:** Thomas
- **Project:** Sheetstorm — Notenmanagement-App für Blaskapellen
- **Stack:** Flutter 3.41.5 + ASP.NET Core 10 LTS + PostgreSQL + SQLite
- **Role:** Principal Frontend Engineer — übernimmt die komplexesten Flutter-Aufgaben
- **Created:** 2026-03-28

## Learnings

<!-- Append new learnings below. -->

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
