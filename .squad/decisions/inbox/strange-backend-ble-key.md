# Decision: BLE Session Key Generation & Distribution

**Author:** Strange (Principal Backend Engineer)
**Date:** 2025-07-25
**Status:** Implemented

## Context

The BLE broadcast spec requires HMAC-SHA256 signed messages between conductor and musicians.
Musicians need a pre-shared session key before connecting via BLE to verify the conductor's identity.

## Decisions

### 1. Key stored in static ConcurrentDictionary (same pattern as ActiveBroadcasts)
- BLE session keys live in-memory alongside broadcast state
- No database persistence needed — keys are ephemeral and session-scoped
- Cleanup happens automatically on StopBroadcast and conductor disconnect

### 2. LeaderDeviceId is server-generated UUID (placeholder)
- The spec calls for the conductor's actual BLE device ID
- For now, the server generates a UUID at session start
- The Flutter client will later send its real device ID via StartBroadcast parameters
- This is forward-compatible: the field exists, clients can already consume it

### 3. REST endpoint for pre-BLE key retrieval
- `GET /api/broadcast/sessions/{bandId}/ble-key` — separate from the SignalR Hub
- Musicians need the key BEFORE establishing BLE connection (to verify conductor in challenge-response)
- Auth: JWT + band membership check (same as Hub methods)
- Controller accesses Hub's static state via `internal static` accessor method

### 4. JoinBroadcast returns BroadcastStateWithBle (breaking Hub contract)
- Changed return type from `BroadcastState?` to `BroadcastStateWithBle?`
- BroadcastStateWithBle has all BroadcastState fields + `BleSession`
- Existing clients that ignore unknown fields are unaffected
- New clients get BLE info automatically on join

### 5. StartBroadcast now returns BleSessionInfo
- Changed from `Task` (void) to `Task<BleSessionInfo>`
- Conductor gets the session key immediately upon starting the broadcast
- No extra round-trip needed
