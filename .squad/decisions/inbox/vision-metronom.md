# Vision — Metronom Frontend Entscheidungen

**Datum:** 2026-07-01  
**Agent:** Vision (Principal Frontend Engineer)

## 1. Beat-Berechnung ist reine Mathematik (kein State)

`BeatCalculator` ist eine reine Dart-Klasse ohne Riverpod-State. Input: `startTimeUs`, `bpm`, `clockOffsetUs`, `nowUs`. Output: `beatNumber`, `measure`, `beatInMeasure`, `isDownbeat`, `microsecondsToNextBeat`.

**Begründung:** Maximale Testbarkeit, kein Framework-Dependency für die Kern-Logik. 21 Unit-Tests decken alle Edge Cases ab (extreme BPM, negative offsets, etc.).

## 2. ClockSyncService gehört zum MetronomeNotifier (kein eigener Provider)

`ClockSyncService` wird als Instanzvariable im `MetronomeNotifier` gehalten, nicht als globaler Riverpod-Provider.

**Begründung:** Clock-Sync macht nur Sinn im Kontext einer aktiven Metronom-Session. Kein Grund für globalen Zustand. Vereinfacht Lifecycle-Management.

## 3. SignalR-Service folgt BroadcastSignalRService-Pattern

Gleiche manuelle JSON-Protokoll-Implementierung: Handshake, Record Separator `\u001e`, Ping/Pong Typ 6, Invocation Typ 1. Gleiche Reconnect-Strategie (exponential backoff 2-32s, max 5 Versuche).

**Hub:** `/hubs/metronome`
**Events:** `OnSessionStarted`, `OnSessionStopped`, `OnSessionUpdated`, `OnClockSyncResponse`, `OnParticipantCountChanged`

## 4. Sentinel-Pattern für nullable copyWith-Felder

`MetronomeState.copyWith` verwendet `static const _sentinel = Object()` für nullable Felder (`session`, `currentBeat`, `error`). Verhindert den `field ?? this.field`-Bug, der in MS2 identifiziert wurde.

## 5. Route: `/app/metronome` mit Query-Parameter für Rolle

Statt separater Routen für Dirigent/Musiker: eine Route `/app/metronome?conductor=true`. Rollenprüfung erfolgt lokal (kein Server-Roundtrip), wie in UX-Spec §2 festgelegt.

## 6. API Convention: `/api/` ohne Version

Per Task-Anweisung verwendet der Frontend-Client `/api/bands/{bandId}/metronome/` ohne Versionssegment. camelCase JSON Keys. **Hinweis:** Banner's Backend verwendet `/api/v1/bands/{bandId}/metronome/` — muss abgestimmt werden.

## Open Items für Banner (Backend)

- SignalR Hub muss `OnSessionStarted`, `OnSessionStopped`, `OnSessionUpdated`, `OnClockSyncResponse`, `OnParticipantCountChanged` senden
- Client-Methoden: `StartSession`, `StopSession`, `UpdateSession`, `RequestClockSync`, `JoinSession`, `LeaveSession`
- UDP Multicast (239.255.77.77:5100) ist für spätere Transport-Erkennung vorbereitet, aber nicht implementiert — Frontend nutzt derzeit nur WebSocket
