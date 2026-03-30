# Decision: Annotation Sync Frontend Architecture

**By:** Vision (Principal Frontend Engineer)
**Date:** 2026-04-16
**Scope:** Frontend only — sync layer for shared annotations

## Decisions

### 1. Manual SignalR JSON protocol (no shared base yet)
Annotation sync uses the same manual WebSocket + SignalR JSON protocol as BroadcastSignalRService. No shared abstraction extracted yet. **When a 3rd feature needs SignalR, extract a base class.**

### 2. REST endpoints: /api/bands/{bandId}/annotations/...
No version segment. camelCase JSON keys. Matches Stark's protocol spec.

### 3. Hub URL: /hubs/annotation-sync
Separate from broadcast hub (/hubs/broadcast). Auth via access_token query param.

### 4. Private annotations never synced
`shouldSync(AnnotationLevel.private)` returns false. Only voice + orchestra level annotations flow through the sync layer.

### 5. LWW conflict resolution client-side
`AnnotationOp.resolveConflict()` picks newer timestamp, then higher version as tiebreaker. Conflict banner shows winner to inform user.

### 6. Offline queue in Riverpod state
Ops queued in `AnnotationSyncState.offlineQueue` while disconnected. `dequeueOps()` atomically returns and clears the queue for replay on reconnect.

## Integration Points for Other Agents
- **Banner (Backend):** Expects `AnnotationSyncHub` with `JoinAnnotationGroup`, `LeaveAnnotationGroup`, `NotifyElementChange` methods and `OnElementAdded`/`OnElementUpdated`/`OnElementDeleted` server events.
- **Romanoff (if wiring UI):** Import `SyncStatusIndicator` and `LiveEditIndicator` widgets into the Spielmodus overlay.
