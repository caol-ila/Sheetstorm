# MS3 — Technische Architektur

**Datum:** 2026-03-30
**Autor:** Stark (Lead / Architect)
**Status:** Draft
**Meilenstein:** MS3 — Tuner + Echtzeit-Klick + Cloud-Sync
**Abhängigkeiten:** MS1 (Spielmodus, Annotationen, Config-System)

---

## 1. Übersicht

MS3 erweitert Sheetstorm um musikalische Werkzeuge für den Probenbetrieb. Sechs Features mit unterschiedlichen Architektur-Anforderungen:

| Feature | Backend | Echtzeit | Neue DB-Tabellen | Neue Flutter-Module |
|---------|---------|----------|-------------------|---------------------|
| Stimmgerät (Tuner) | — | — | — | `tuner/` |
| Echtzeit-Metronom | ✅ UDP + SignalR | ✅ | `MetronomeSessions` | `metronome/` |
| Cloud-Sync | ✅ REST | — | `SyncVersions`, `SyncChangelogs` | `cloud_sync/` |
| Annotationen-Sync | ✅ REST + SignalR | ✅ | `Annotations`, `AnnotationElements` | `annotation_sync/` (erweitert `annotations/`) |
| Auto-Scroll / Reflow | — | — | — | (erweitert `performance_mode/`) |
| Aufgabenverwaltung | ✅ REST | — | `BandTasks`, `TaskAssignments` | `tasks/` |

### Architektur-Überblick (Datenfluss)

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Client                            │
│                                                                  │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌───────────────┐  │
│  │  Tuner   │  │ Metronome │  │  Tasks   │  │ Annotation    │  │
│  │(Platform │  │  (UDP +   │  │  (REST)  │  │ Sync (REST +  │  │
│  │ Channel) │  │ SignalR)  │  │          │  │ SignalR)      │  │
│  └────┬─────┘  └─────┬─────┘  └────┬─────┘  └──────┬────────┘  │
│       │              │              │               │            │
│       │         ┌────┴────┐         │          ┌────┴────┐      │
│       ▼         │ Clock   │         │          │ Cloud   │      │
│   Native        │ Sync    │         │          │ Sync    │      │
│   Audio API     │ Service │         │          │ Engine  │      │
│   (CoreAudio/   └────┬────┘         │          └────┬────┘      │
│    Oboe/WebAudio)     │              │               │           │
│                       │              │               │           │
│       ┌───────────────┴──────────────┴───────────────┘           │
│       │           Drift (SQLite) — Offline Cache                 │
│       └──────────────────────────────────────────────            │
└──────────────────────────────────┬───────────────────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
                    ▼              ▼              ▼
            ┌──────────┐  ┌──────────────┐  ┌─────────┐
            │ REST API │  │ SignalR Hubs  │  │ UDP     │
            │ /api/... │  │ /hubs/...     │  │ Server  │
            └────┬─────┘  └──────┬───────┘  └────┬────┘
                 │               │               │
                 └───────────────┼───────────────┘
                                 │
                          ┌──────┴──────┐
                          │ ASP.NET Core│
                          │ 10 Backend  │
                          └──────┬──────┘
                                 │
                          ┌──────┴──────┐
                          │ PostgreSQL  │
                          │ 18          │
                          └─────────────┘
```

---

## 2. Stimmgerät (Tuner)

### 2.1 Architektur-Entscheidung

**Rein clientseitig.** Kein Backend nötig. FFT-basierte Frequenzerkennung läuft komplett auf dem Gerät über Platform Channels zu nativen Audio-APIs.

### 2.2 FFT-Pipeline

```
┌─────────────┐    ┌──────────────┐    ┌─────────────┐    ┌──────────┐
│ Mikrofon    │───►│ Native Audio │───►│ FFT         │───►│ Pitch    │
│ (Hardware)  │    │ Capture      │    │ Processing  │    │ Detection│
└─────────────┘    └──────────────┘    └─────────────┘    └─────┬────┘
                                                                │
                   ┌──────────────┐    ┌─────────────┐    ┌─────▼────┐
                   │ Flutter UI   │◄───│ Platform    │◄───│ Note     │
                   │ (Dart)       │    │ Channel     │    │ Mapping  │
                   └──────────────┘    └─────────────┘    └──────────┘
```

**Stufen der Pipeline:**

| Stufe | Implementierung | Latenz-Budget |
|-------|----------------|---------------|
| Audio Capture | CoreAudio (iOS), Oboe (Android), Web Audio API | < 5ms |
| FFT | vDSP (iOS), KissFFT/PFFFT (Android), AnalyserNode (Web) | < 5ms |
| Pitch Detection | YIN oder MPM Algorithmus | < 3ms |
| Note Mapping + Transposition | Dart (Platform Channel Result) | < 2ms |
| UI Update | Flutter setState/Riverpod | < 5ms |
| **Gesamt** | | **< 20ms** |

### 2.3 Platform Channel Interface

```dart
// Dart-seitig
abstract class TunerPlatformInterface {
  /// Startet Audio-Capture + FFT-Pipeline
  Future<void> startListening({
    int sampleRate = 44100,
    int bufferSize = 2048,  // ~46ms bei 44.1kHz, 2x pro Zyklus
  });

  /// Stoppt Audio-Capture
  Future<void> stopListening();

  /// Event-Stream mit Pitch-Ergebnissen
  Stream<TunerResult> get pitchStream;
}

class TunerResult {
  final double frequency;     // Hz (z.B. 440.0)
  final double confidence;    // 0.0–1.0 (Erkennungssicherheit)
  final int midiNote;         // MIDI-Nummer (z.B. 69 = A4)
  final String noteName;      // "A4", "Bb3", etc.
  final double centDeviation; // -50 bis +50 Cent
  final DateTime timestamp;
}
```

**Native-Seite (pro Plattform):**

| Plattform | Audio-Framework | FFT-Bibliothek | Buffer-Strategie |
|-----------|----------------|----------------|------------------|
| iOS | AVAudioEngine (CoreAudio) | vDSP (Accelerate.framework) | installTap, 2048 Samples |
| Android | Oboe (AAudio/OpenSL) | KissFFT oder PFFFT | Callback-basiert, Low-Latency |
| Web | AudioContext + MediaStreamSource | AnalyserNode (built-in FFT) | ScriptProcessorNode / AudioWorklet |
| Windows | WASAPI via Oboe-Port oder NAudio | KissFFT | Shared-Mode, Low-Latency |

### 2.4 Transpositions-Support

Transposition basiert auf dem Instrumentenprofil des Nutzers (aus `UserInstruments` / Nutzer-Config):

```
Klingende Frequenz → Transponierte Note
  B♭-Instrument: +2 Halbtöne (klingendes C = notiertes D)
  E♭-Instrument: +3 Halbtöne (klingendes C = notiertes A)
  F-Instrument:  +7 Halbtöne (klingendes C = notiertes G)
```

**Kammerton-Kalibrierung:** A4-Frequenz aus Device-Config (`tuner.referenceFrequency`, Default: 442 Hz). Wird im Config-System gespeichert (Geräte-Ebene, orange).

### 2.5 Flutter-Modul-Struktur

```
sheetstorm_app/lib/features/tuner/
├── application/
│   ├── tuner_notifier.dart          # Riverpod-State: aktuelle Note, Cent, Frequenz
│   └── tuner_notifier.g.dart
├── data/
│   ├── models/
│   │   └── tuner_models.dart        # TunerResult, TunerState, TranspositionMode
│   ├── services/
│   │   ├── tuner_platform_interface.dart   # Abstraktion über Platform Channels
│   │   └── pitch_calculator.dart    # Note-Mapping, Cent-Berechnung, Transposition
│   └── native/
│       ├── tuner_ios.dart           # MethodChannel → Swift/CoreAudio
│       ├── tuner_android.dart       # MethodChannel → Kotlin/Oboe
│       └── tuner_web.dart           # dart:js_interop → Web Audio API
├── presentation/
│   ├── screens/
│   │   └── tuner_screen.dart        # Hauptbildschirm mit Tuner-Anzeige
│   └── widgets/
│       ├── tuner_gauge.dart         # Rundes Gauge mit Cent-Anzeige
│       ├── tuner_note_display.dart  # Aktuelle Note (groß, zentral)
│       ├── tuner_frequency_bar.dart # Frequenz-Balken
│       └── tuner_settings.dart      # Kammerton + Transposition
└── routes.dart
```

### 2.6 Integration mit bestehendem System

- **Config-System:** `tuner.referenceFrequency` als Geräte-Config (Ebene 3, Orange). Default 442 Hz. Via `ConfigController` (bestehend) les-/schreibbar.
- **Instrumentenprofil:** Transpositionsmodus aus `UserInstruments.InstrumentType` ableiten. Instrument-Typ-Enum um `TranspositionKey` erweitern (Bb, Eb, F, C).
- **Permissions:** Mikrofon-Berechtigung beim ersten Tuner-Start anfordern (Platform-spezifisch).

---

## 3. Echtzeit-Metronom (Sync)

> **Architektur-Entscheidung:** WiFi UDP Multicast als primärer Transport für LAN-Szenarien (< 5ms). SignalR WebSocket als Fallback für Remote/Internet-Szenarien (< 50ms). Beats als Timestamps, nicht als Live-Kommandos.
>
> **Hinweis:** Thomas hat initial BLE Broadcast als primäre Technologie vorgeschlagen (Decision 2026-03-28T12:44Z). Die Meilenstein-Spezifikation (v2) definiert jedoch WiFi UDP Multicast + SignalR WebSocket. Diese Architektur folgt der detaillierteren Spezifikation. BLE bleibt als potenzielle dritte Transport-Option für zukünftige Iterationen.

### 3.1 Protokoll-Architektur

```
┌────────────────────────────────────────────────────────────────────┐
│                      Dirigent (Client)                             │
│                                                                    │
│  Start/Stop ──► MetronomeService ──► Transport-Auswahl             │
│                     │                    │                         │
│                     │              ┌─────┼─────┐                   │
│                     │              ▼           ▼                   │
│                     │          UDP Client   SignalR Client         │
└─────────────────────┼──────────────┼───────────┼───────────────────┘
                      │              │           │
                      │         UDP Multicast  WebSocket
                      │              │           │
┌─────────────────────┼──────────────┼───────────┼───────────────────┐
│                     ▼              ▼           ▼                   │
│              ┌─────────────┐  ┌────────┐  ┌──────────┐            │
│              │ Metronome   │  │ UDP    │  │ Metronome│            │
│              │ Service     │◄─┤ Server │  │ Hub      │            │
│              │ (Singleton) │  │        │  │ (SignalR)│            │
│              └──────┬──────┘  └────────┘  └──────────┘            │
│                     │                                              │
│              ┌──────┴──────┐                                       │
│              │ Clock Sync  │                                       │
│              │ Service     │                                       │
│              └─────────────┘                                       │
│                                                                    │
│                    ASP.NET Core 10 Backend                          │
└────────────────────────────────────────────────────────────────────┘
                      │
         ┌────────────┼────────────┐
         ▼            ▼            ▼
   ┌──────────┐ ┌──────────┐ ┌──────────┐
   │ Musiker  │ │ Musiker  │ │ Musiker  │
   │ Client A │ │ Client B │ │ Client C │
   └──────────┘ └──────────┘ └──────────┘
```

### 3.2 Clock-Synchronisation (NTP-ähnlich)

Bevor Beats empfangen werden können, muss jeder Client seinen Clock-Offset zum Server ermitteln.

**Protokoll (UDP oder WebSocket):**

```
Client                              Server
  │                                    │
  │── ClockSyncRequest ──────────────►│
  │   { clientSendTime: T1 }          │
  │                                    │
  │◄── ClockSyncResponse ────────────│
  │   { clientSendTime: T1,           │
  │     serverRecvTime: T2,           │
  │     serverSendTime: T3 }          │
  │                                    │
  │   T4 = localReceiveTime           │
  │                                    │
  │   roundTrip = (T4 - T1) - (T3 - T2)
  │   offset = ((T2 - T1) + (T3 - T4)) / 2
  │                                    │
  │   → Wiederhole 5x, Median nehmen  │
```

**Datenstrukturen:**

```csharp
// Server-seitig
public record ClockSyncRequest(long ClientSendTimeUs);

public record ClockSyncResponse(
    long ClientSendTimeUs,
    long ServerRecvTimeUs,
    long ServerSendTimeUs
);

// Client-seitig (Dart)
class ClockSyncResult {
  final Duration offset;        // Differenz Client→Server
  final Duration roundTripTime; // Netzwerk-Latenz (bidirektional)
  final DateTime syncedAt;
}
```

**Sync-Intervall:** Initial 5 Messungen beim Verbinden, danach alle 30 Sekunden eine Re-Sync-Messung.

### 3.3 Beat-Protokoll

Beats werden als Timestamps verschickt, nicht als "jetzt spielen"-Kommandos. Der Client berechnet lokal, wann der nächste Beat fällig ist.

**MetronomeSession (Server-seitig, in-memory):**

```csharp
public record MetronomeSession(
    Guid Id,
    Guid BandId,
    Guid ConductorId,
    string ConductorName,
    bool IsActive,
    int Bpm,                    // 20–300
    int BeatsPerMeasure,        // Zähler der Taktart (z.B. 4)
    int BeatUnit,               // Nenner der Taktart (z.B. 4)
    long StartTimeUs,           // Server-Mikrosekunden-Timestamp des ersten Beats
    int ParticipantCount,
    DateTime StartedAt
);
```

**Beat-Berechnung (Client-seitig):**

```dart
// Nächster Beat berechnen (kein Server-Ping nötig!)
Duration beatInterval = Duration(microseconds: (60000000 / bpm).round());
int currentBeat = ((serverTimeNow - startTimeUs) / beatInterval).floor();
Duration timeToNextBeat = startTimeUs + (currentBeat + 1) * beatInterval - serverTimeNow;

// serverTimeNow = localTime + clockOffset
```

**Vorteile dieses Ansatzes:**
- Keine Netzwerk-Latenz pro Beat (Beat-Timing ist lokal)
- Server sendet nur Session-Start/Stop/Change-Events
- Bei Netzwerk-Ausfällen tickt das Metronom weiter
- Clients sind durch Clock-Sync synchron (< 1ms Abweichung bei < 5ms Roundtrip)

### 3.4 UDP Multicast Server

**ASP.NET Core Integration:**

```csharp
// Registrierung in Program.cs
builder.Services.AddSingleton<IMetronomeService, MetronomeService>();
builder.Services.AddHostedService<UdpMulticastServer>();

// Konfiguration
public class MetronomeUdpOptions
{
    public string MulticastGroup { get; set; } = "239.255.77.77";
    public int Port { get; set; } = 5100;
    public int ClockSyncPort { get; set; } = 5101;
}
```

**UDP-Nachrichtenformat (binär, Little-Endian, minimaler Overhead):**

```
Byte-Layout:
[0]      MessageType (1 byte): 0x01=ClockSync, 0x02=SessionStart,
                                0x03=SessionStop, 0x04=SessionUpdate
[1-16]   SessionId (16 bytes, GUID)
[17-24]  Payload (variabel nach Typ)

SessionStart Payload:
[17-18]  BPM (uint16)
[19]     BeatsPerMeasure (uint8)
[20]     BeatUnit (uint8)
[21-28]  StartTimeUs (int64, Server-Mikrosekunden)

ClockSync Request/Response:
[17-24]  ClientSendTimeUs (int64)
[25-32]  ServerRecvTimeUs (int64)
[33-40]  ServerSendTimeUs (int64)
```

**Automatische Transport-Erkennung (Client):**

```dart
enum MetronomeTransport { udp, webSocket }

class TransportDetector {
  Future<MetronomeTransport> detectBestTransport(String serverHost) async {
    // 1. Versuche UDP Multicast empfangen (Probe-Paket)
    //    → Timeout 2 Sekunden
    // 2. Wenn erfolgreich → UDP
    // 3. Sonst → WebSocket Fallback
  }
}
```

### 3.5 SignalR Hub (WebSocket Fallback)

```csharp
// Pfad: /hubs/metronome (bereits als Kommentar in Program.cs vorbereitet)
[Authorize]
public class MetronomeHub(IMetronomeService metronomeService) : Hub
{
    // Server → Client Events
    // OnSessionStarted(MetronomeSessionDto)
    // OnSessionStopped(Guid sessionId)
    // OnSessionUpdated(MetronomeSessionDto)  // BPM/Taktart-Änderung
    // OnClockSyncResponse(ClockSyncResponse)
    // OnParticipantCountChanged(int count)

    // Client → Server Methods
    // StartSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit)
    // StopSession(Guid bandId)
    // UpdateSession(Guid bandId, int bpm, int beatsPerMeasure, int beatUnit)
    // RequestClockSync(ClockSyncRequest)
    // JoinSession(Guid bandId)
    // LeaveSession(Guid bandId)
}
```

**Architektur-Hinweis:** `IMetronomeService` ist ein Singleton, das den Zustand aller aktiven Sessions hält (analog zu `SongBroadcastHub` mit `ConcurrentDictionary`). Sowohl UDP-Server als auch SignalR-Hub nutzen denselben Service.

### 3.6 Latenz-Kompensation

Geräte-Config (Ebene 3, Orange): `metronome.latencyCompensationMs` (Default: 0, Range: -50 bis +50ms).

Der Client addiert diesen Wert auf die berechnete Beat-Zeit, um individuelle Audio-/Display-Latenz auszugleichen.

### 3.7 Flutter-Modul-Struktur

```
sheetstorm_app/lib/features/metronome/
├── application/
│   ├── metronome_notifier.dart      # Session-State, aktiver Beat, BPM
│   ├── clock_sync_notifier.dart     # Clock-Offset-Management
│   └── *.g.dart
├── data/
│   ├── models/
│   │   └── metronome_models.dart    # MetronomeSession, ClockSyncResult, Beat
│   ├── services/
│   │   ├── metronome_service.dart   # Orchestriert Transport + Beat-Berechnung
│   │   ├── udp_transport.dart       # UDP Multicast Client
│   │   ├── websocket_transport.dart # SignalR Client
│   │   ├── transport_detector.dart  # Auto-Erkennung UDP vs WebSocket
│   │   └── clock_sync_service.dart  # NTP-ähnliche Clock-Sync-Logik
│   └── audio/
│       └── click_player.dart        # Audio-Click-Ausgabe (Platform Channel)
├── presentation/
│   ├── screens/
│   │   └── metronome_screen.dart    # Metronom-Hauptansicht
│   └── widgets/
│       ├── beat_indicator.dart      # Visueller Taktschlag (animiert)
│       ├── bpm_dial.dart            # BPM-Einstellung (Dirigent)
│       ├── time_signature_picker.dart
│       └── sync_status_badge.dart   # Verbindungsstatus + Latenz
└── routes.dart
```

### 3.8 Neue Datenbank-Entitäten

**Keine persistierte DB-Tabelle nötig.** Metronom-Sessions sind transient (in-memory via `ConcurrentDictionary`, analog zu `SongBroadcastHub`). Begründung: Ein Metronom läuft nur während der Probe — es gibt keinen Mehrwert in der Persistierung.

**Config-Einträge (bestehende Tabellen):**
- `ConfigUser`: `metronome.defaultBpm` (int, Default: 120)
- `ConfigUser`: `metronome.defaultTimeSignature` (string, Default: "4/4")
- Device-Config (lokal): `metronome.latencyCompensationMs` (int, Default: 0)
- Device-Config (lokal): `metronome.audioClickEnabled` (bool, Default: true)
- Device-Config (lokal): `metronome.audioClickVolume` (double, Default: 0.8)

---

## 4. Cloud-Sync (Persönliche Sammlung)

### 4.1 Architektur-Entscheidung

**Delta-Sync mit Versionierung und Last-Write-Wins per Feld.** Der Client hält einen lokalen Sync-Cursor und sendet nur geänderte Felder. Der Server ist autoritativ für die Merge-Logik.

### 4.2 Sync-Protokoll

```
Client                                    Server
  │                                          │
  │── GET /api/sync/state ─────────────────►│
  │   Authorization: Bearer {jwt}            │
  │                                          │
  │◄── { lastSyncVersion: 42,              │
  │      pendingChanges: 3 } ──────────────│
  │                                          │
  │── POST /api/sync/pull ─────────────────►│
  │   { sinceVersion: 38 }                   │
  │                                          │
  │◄── { changes: [...],                    │
  │      currentVersion: 42 } ─────────────│
  │                                          │
  │   → Client wendet Änderungen lokal an    │
  │                                          │
  │── POST /api/sync/push ─────────────────►│
  │   { baseVersion: 42,                     │
  │     changes: [                           │
  │       { entityType: "Piece",             │
  │         entityId: "...",                 │
  │         field: "title",                  │
  │         value: "Neue Polka",             │
  │         changedAt: "2026-03-30T10:00Z"   │
  │       }                                  │
  │     ]                                    │
  │   }                                      │
  │                                          │
  │◄── { accepted: [...],                   │
  │      conflicts: [...],                  │
  │      newVersion: 43 } ─────────────────│
```

### 4.3 Konflikt-Auflösung (Last-Write-Wins per Feld)

```
Szenario: Gleiche Piece.title auf zwei Geräten geändert

Gerät A: title = "Polka neu" um 10:00:05
Gerät B: title = "Neue Polka" um 10:00:03

Server empfängt A zuerst (Push):
  → title = "Polka neu", version 43

Server empfängt B danach (Push):
  → Conflict detected: B's changedAt (10:00:03) < Server's (10:00:05)
  → B's Änderung wird verworfen, A gewinnt
  → Response an B: { conflicts: [{ field: "title", serverValue: "Polka neu" }] }
```

**Regel:** Der spätere `changedAt`-Timestamp gewinnt. Bei Gleichheit gewinnt der erste Push (Server-Version).

### 4.4 Neue Datenbank-Tabellen

```sql
-- Sync-Versionierung pro Nutzer
CREATE TABLE "SyncVersions" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "MusicianId"      UUID NOT NULL REFERENCES "Musicians"("Id"),
    "CurrentVersion"  BIGINT NOT NULL DEFAULT 0,
    "LastSyncAt"      TIMESTAMP WITH TIME ZONE,
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX "IX_SyncVersions_MusicianId" ON "SyncVersions"("MusicianId");

-- Änderungs-Log (Delta-Sync)
CREATE TABLE "SyncChangelogs" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "MusicianId"      UUID NOT NULL REFERENCES "Musicians"("Id"),
    "Version"         BIGINT NOT NULL,
    "EntityType"      VARCHAR(100) NOT NULL,  -- "Piece", "SheetMusic", "PiecePage"
    "EntityId"        UUID NOT NULL,
    "Operation"       VARCHAR(10) NOT NULL,   -- "Create", "Update", "Delete"
    "FieldName"       VARCHAR(100),           -- NULL für Create/Delete
    "OldValue"        TEXT,
    "NewValue"        TEXT,
    "ChangedAt"       TIMESTAMP WITH TIME ZONE NOT NULL,
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX "IX_SyncChangelogs_Musician_Version"
    ON "SyncChangelogs"("MusicianId", "Version");
```

### 4.5 Neue Domain-Entitäten

```csharp
// src/Sheetstorm.Domain/Entities/SyncVersion.cs
public class SyncVersion : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;
    public long CurrentVersion { get; set; }
    public DateTime? LastSyncAt { get; set; }
}

// src/Sheetstorm.Domain/Entities/SyncChangelog.cs
public class SyncChangelog : BaseEntity
{
    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;
    public long Version { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public Guid EntityId { get; set; }
    public SyncOperation Operation { get; set; }
    public string? FieldName { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public DateTime ChangedAt { get; set; }
}

// src/Sheetstorm.Domain/Enums/SyncOperation.cs
public enum SyncOperation { Create, Update, Delete }
```

### 4.6 API-Endpunkte

```
GET    /api/sync/state              → SyncStateDto
POST   /api/sync/pull               → SyncPullResponseDto
POST   /api/sync/push               → SyncPushResponseDto
```

**Kein Band-Scope** — Cloud-Sync betrifft die persönliche Sammlung ("Meine Musik"), die keiner Band zugeordnet ist.

### 4.7 Sync-fähige Entitäten

| Entität | Sync-Felder | Binärdaten |
|---------|------------|------------|
| `Piece` (persönlich) | title, composer, arranger, genre, key, notes | — |
| `SheetMusic` | voiceName, instrumentType, sortOrder | — |
| `PiecePage` | pageNumber, sortOrder | Blob-URL (S3-Sync separat) |

**Binärdaten-Sync:** Notenbilder (JPEG/PNG) werden separat über S3-kompatiblen Storage synchronisiert. Der Sync-Changelog enthält nur die S3-URL/Key-Änderung, nicht die Binärdaten.

### 4.8 Flutter-Modul-Struktur

```
sheetstorm_app/lib/features/cloud_sync/
├── application/
│   ├── sync_notifier.dart           # Sync-Status, Auto-Sync-Timer
│   └── sync_notifier.g.dart
├── data/
│   ├── models/
│   │   └── sync_models.dart         # SyncState, SyncChange, SyncConflict
│   ├── services/
│   │   ├── sync_service.dart        # REST-Client für Sync-Endpoints
│   │   ├── sync_engine.dart         # Orchestrierung: Pull → Merge → Push
│   │   └── conflict_resolver.dart   # LWW-Logik, Conflict-UI-Trigger
│   └── local/
│       └── sync_drift_dao.dart      # Drift-DAO für lokalen Sync-State
├── presentation/
│   ├── screens/
│   │   └── sync_status_screen.dart  # Sync-Übersicht und manuelle Sync-Trigger
│   └── widgets/
│       ├── sync_indicator.dart      # Status-Badge (synced/syncing/conflict)
│       └── conflict_dialog.dart     # Konflikt-Auflösungs-Dialog
└── routes.dart
```

### 4.9 Offline-Strategie

```
App-Start:
  1. Drift-DB hat vollständige lokale Kopie (bestehend)
  2. SyncEngine prüft Konnektivität
  3. Wenn online: Pull → lokale Änderungen mergen → Push
  4. Wenn offline: Änderungen in lokaler Queue speichern

Änderung im Offline-Modus:
  1. Änderung in Drift-DB schreiben (sofort verfügbar)
  2. Änderung in lokaler Sync-Queue (pending_changes Tabelle in Drift)
  3. Bei Reconnect: Queue abarbeiten via Push

Auto-Sync:
  - Alle 5 Minuten im Hintergrund (konfigurierbar)
  - Bei App-Foreground
  - Bei expliziter Benutzer-Aktion
```

---

## 5. Annotationen-Sync

### 5.1 Architektur-Entscheidung

**Operations-basierter Sync via SignalR mit Last-Write-Wins per Element.**

CRDT und OT wurden evaluiert und für diesen Anwendungsfall verworfen:

| Ansatz | Pro | Contra | Entscheidung |
|--------|-----|--------|-------------|
| **CRDT** | Automatische Konflikt-Auflösung, mathematisch beweisbar | Hohe Komplexität, große Payload (State-CRDT), SVG-Paths nicht natürlich CRDT-fähig | ❌ Overkill |
| **OT** | Bewährt für Text-Collaboration | Hohe Server-Komplexität, transformiert Positionen — Annotationen sind keine lineare Sequenz | ❌ Falsches Modell |
| **Op-Log + LWW** | Einfach, passt zum Element-Modell, Server-Last gering | Seltene Konflikte → letzter Schreiber gewinnt | ✅ **Gewählt** |

**Begründung:** Annotationen sind unabhängige grafische Elemente (Striche, Texte, Stempel). Zwei Musiker annotieren fast nie dasselbe Element gleichzeitig. Wenn doch: LWW per Element-ID ist akzeptabel, da der "Verlust" ein einzelner Strich ist, nicht ein Dokument.

### 5.2 Datenmodell

Annotationen waren bisher rein client-seitig (Dart-Objekte in der Flutter-App). Für Sync müssen sie server-seitig persistiert werden.

```sql
-- Annotation-Container pro Seite + Sichtbarkeitsebene
CREATE TABLE "Annotations" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "PiecePageId"     UUID NOT NULL REFERENCES "PiecePages"("Id") ON DELETE CASCADE,
    "Level"           VARCHAR(20) NOT NULL,  -- 'Private', 'Voice', 'Orchestra'
    "VoiceId"         UUID REFERENCES "Voices"("Id"),  -- Nur bei Level='Voice'
    "BandId"          UUID REFERENCES "Bands"("Id"),   -- Nur bei Level='Voice'|'Orchestra'
    "CreatedByMusicianId" UUID NOT NULL REFERENCES "Musicians"("Id"),
    "Version"         BIGINT NOT NULL DEFAULT 1,
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Einzelne Annotation-Elemente (Striche, Texte, Stempel)
CREATE TABLE "AnnotationElements" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "AnnotationId"    UUID NOT NULL REFERENCES "Annotations"("Id") ON DELETE CASCADE,
    "Tool"            VARCHAR(20) NOT NULL,  -- 'Pencil', 'Highlighter', 'Text', 'Stamp'
    "Points"          JSONB,                 -- [{x, y, pressure}, ...] für Striche
    "BboxX"           DOUBLE PRECISION NOT NULL,
    "BboxY"           DOUBLE PRECISION NOT NULL,
    "BboxWidth"       DOUBLE PRECISION NOT NULL,
    "BboxHeight"      DOUBLE PRECISION NOT NULL,
    "Text"            VARCHAR(200),          -- Nur für Tool='Text'
    "StampCategory"   VARCHAR(50),           -- Nur für Tool='Stamp'
    "StampValue"      VARCHAR(50),           -- Nur für Tool='Stamp'
    "Opacity"         DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "StrokeWidth"     DOUBLE PRECISION NOT NULL DEFAULT 3.0,
    "Version"         BIGINT NOT NULL DEFAULT 1,
    "CreatedByMusicianId" UUID NOT NULL REFERENCES "Musicians"("Id"),
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "IsDeleted"       BOOLEAN NOT NULL DEFAULT FALSE  -- Soft-Delete für Sync
);
CREATE INDEX "IX_AnnotationElements_AnnotationId"
    ON "AnnotationElements"("AnnotationId");
```

### 5.3 Echtzeit-Sync via SignalR

```csharp
// Pfad: /hubs/annotations (bereits als Kommentar in Program.cs vorbereitet)
[Authorize]
public class AnnotationSyncHub(IAnnotationSyncService syncService) : Hub
{
    // ── SignalR Groups ──
    // Voice-Annotationen:     "annotation-voice-{bandId}-{voiceId}-{piecePageId}"
    // Orchester-Annotationen: "annotation-orchestra-{bandId}-{piecePageId}"
    // Private: kein Sync (nur REST für Cloud-Backup)

    // Client → Server
    // JoinAnnotationGroup(Guid bandId, Guid piecePageId, Guid? voiceId)
    // LeaveAnnotationGroup(Guid bandId, Guid piecePageId, Guid? voiceId)
    // PushElementChange(AnnotationElementChangeDto)

    // Server → Client
    // OnElementAdded(AnnotationElementDto)
    // OnElementUpdated(AnnotationElementDto)
    // OnElementDeleted(Guid elementId)
}
```

**Sync-Flow:**

```
Musiker A zeichnet Strich    Musiker B sieht Strich in Echtzeit
     │                              ▲
     ▼                              │
1. Lokal in Dart-State     4. OnElementAdded empfangen
2. REST POST → Server      5. In lokalen State einfügen
3. SignalR Broadcast        6. UI aktualisiert
     an Gruppe
```

### 5.4 API-Endpunkte

```
# Annotation-Container
GET    /api/bands/{bandId}/annotations/{piecePageId}
         ?level=Voice&voiceId={voiceId}              → AnnotationDto[]

# Element-Operationen (Batch-fähig)
POST   /api/bands/{bandId}/annotations/{annotationId}/elements
                                                      → AnnotationElementDto
PUT    /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
                                                      → AnnotationElementDto
DELETE /api/bands/{bandId}/annotations/{annotationId}/elements/{elementId}
                                                      → 204 No Content

# Persönliche Annotationen (Private Level, kein Band-Scope)
GET    /api/annotations/personal/{piecePageId}        → AnnotationDto[]
POST   /api/annotations/personal/{piecePageId}/elements
                                                      → AnnotationElementDto
PUT    /api/annotations/personal/elements/{elementId} → AnnotationElementDto
DELETE /api/annotations/personal/elements/{elementId} → 204 No Content

# Bulk-Sync (Initial Load / Offline-Sync)
POST   /api/bands/{bandId}/annotations/{piecePageId}/sync
         Body: { sinceVersion: 42 }                   → AnnotationSyncResponseDto
```

### 5.5 Erweiterung des bestehenden Flutter-Annotationsmoduls

```
sheetstorm_app/lib/features/annotations/
├── application/
│   ├── annotation_notifier.dart          # BESTEHEND — erweitern um Sync-Hooks
│   ├── annotation_toolbar_notifier.dart  # BESTEHEND — unverändert
│   └── annotation_sync_notifier.dart     # NEU — Sync-State + Conflict-Handling
├── data/
│   ├── models/
│   │   ├── annotation_models.dart        # BESTEHEND — ID-Feld wird server-synced
│   │   └── annotation_sync_models.dart   # NEU — SyncState, ElementChange, Conflict
│   ├── services/
│   │   ├── annotation_sync_service.dart  # NEU — REST-Client für Annotation-Sync
│   │   └── annotation_realtime.dart      # NEU — SignalR-Client für Echtzeit
│   └── stamp_catalog.dart               # BESTEHEND — unverändert
├── presentation/
│   └── ...                              # BESTEHEND — unverändert
└── routes.dart
```

**Änderung am bestehenden `AnnotationNotifier`:**

```dart
// Bestehend: commitStroke() speichert nur lokal
// Neu: commitStroke() → lokal speichern → REST POST → SignalR Broadcast
//      Wenn Level != private: Sync-Flow auslösen
```

---

## 6. Auto-Scroll / Reflow

### 6.1 Architektur-Entscheidung

**Rein clientseitig.** Erweiterung des bestehenden `performance_mode/` Feature-Moduls. Kein Backend nötig.

### 6.2 Scroll-Modi

| Modus | Geschwindigkeits-Quelle | Steuerung |
|-------|------------------------|-----------|
| **Manuell** | Nutzer-Slider (px/s) | Play/Pause/Speed-Buttons |
| **BPM-basiert** | BPM-Wert → Seitengeschwindigkeit | Automatisch aus Metronom-Session oder manueller BPM-Eingabe |

**BPM → Scroll-Geschwindigkeit Berechnung:**

```dart
// Annahme: 1 Seite ≈ 4 Takte (konfigurierbar pro Stück)
double measuresPerPage = piece.measuresPerPage ?? 4.0;
double secondsPerMeasure = (60.0 / bpm) * beatsPerMeasure;
double secondsPerPage = measuresPerPage * secondsPerMeasure;
double pixelsPerSecond = pageHeightPx / secondsPerPage;
```

### 6.3 Integration mit Metronom

Wenn ein Metronom-Session aktiv ist, kann Auto-Scroll automatisch die BPM übernehmen:

```dart
// In AutoScrollNotifier:
ref.listen(metronomeSessionProvider, (prev, next) {
  if (next != null && autoScrollState.syncWithMetronome) {
    updateSpeed(bpmToPixelsPerSecond(next.bpm));
  }
});
```

### 6.4 Flutter-Änderungen

```
sheetstorm_app/lib/features/performance_mode/
├── application/
│   ├── performance_mode_notifier.dart    # BESTEHEND
│   └── auto_scroll_notifier.dart         # NEU — Scroll-State + Speed-Kontrolle
├── presentation/
│   └── widgets/
│       ├── ...                           # BESTEHEND
│       ├── auto_scroll_controls.dart     # NEU — Play/Pause/Speed im Overlay
│       └── auto_scroll_speed_slider.dart # NEU — Geschwindigkeits-Slider
```

**Config-Einträge (Device-Config, lokal):**
- `playMode.autoScrollDefaultSpeed` (double, px/s, Default: 50.0)
- `playMode.autoScrollSyncWithMetronome` (bool, Default: true)

---

## 7. Aufgabenverwaltung (Tasks)

### 7.1 Architektur-Entscheidung

**Standard-CRUD mit Status-Machine.** Aufgaben sind Band-scoped (analog zu Events, Posts, Polls). Einfaches REST-API mit Status-Übergängen.

### 7.2 Datenmodell

```sql
CREATE TABLE "BandTasks" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "BandId"          UUID NOT NULL REFERENCES "Bands"("Id") ON DELETE CASCADE,
    "Title"           VARCHAR(300) NOT NULL,
    "Description"     TEXT,
    "Status"          VARCHAR(20) NOT NULL DEFAULT 'Open',
        -- 'Open', 'InProgress', 'Done'
    "Priority"        VARCHAR(10) NOT NULL DEFAULT 'Normal',
        -- 'Low', 'Normal', 'High'
    "DueDate"         TIMESTAMP WITH TIME ZONE,
    "EventId"         UUID REFERENCES "Events"("Id") ON DELETE SET NULL,
    "CreatedByMusicianId" UUID NOT NULL REFERENCES "Musicians"("Id"),
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE INDEX "IX_BandTasks_BandId" ON "BandTasks"("BandId");
CREATE INDEX "IX_BandTasks_Status" ON "BandTasks"("BandId", "Status");

CREATE TABLE "TaskAssignments" (
    "Id"              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "TaskId"          UUID NOT NULL REFERENCES "BandTasks"("Id") ON DELETE CASCADE,
    "MusicianId"      UUID NOT NULL REFERENCES "Musicians"("Id"),
    "AssignedAt"      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "CompletedAt"     TIMESTAMP WITH TIME ZONE,
    "CreatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"       TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX "IX_TaskAssignments_Task_Musician"
    ON "TaskAssignments"("TaskId", "MusicianId");
```

### 7.3 Domain-Entitäten

```csharp
// src/Sheetstorm.Domain/Entities/BandTask.cs
public class BandTask : BaseEntity
{
    public Guid BandId { get; set; }
    public Band Band { get; set; } = null!;

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public TaskStatus Status { get; set; } = TaskStatus.Open;
    public TaskPriority Priority { get; set; } = TaskPriority.Normal;
    public DateTime? DueDate { get; set; }

    public Guid? EventId { get; set; }
    public Event? Event { get; set; }

    public Guid CreatedByMusicianId { get; set; }
    public Musician CreatedByMusician { get; set; } = null!;

    public ICollection<TaskAssignment> Assignments { get; set; } = [];
}

// src/Sheetstorm.Domain/Entities/TaskAssignment.cs
public class TaskAssignment : BaseEntity
{
    public Guid TaskId { get; set; }
    public BandTask Task { get; set; } = null!;

    public Guid MusicianId { get; set; }
    public Musician Musician { get; set; } = null!;

    public DateTime? CompletedAt { get; set; }
}

// src/Sheetstorm.Domain/Enums/TaskStatus.cs
public enum TaskStatus { Open, InProgress, Done }

// src/Sheetstorm.Domain/Enums/TaskPriority.cs
public enum TaskPriority { Low, Normal, High }
```

### 7.4 Status-Machine

```
       ┌─────────┐
       │  Open   │
       └────┬────┘
            │ StartWork
            ▼
     ┌──────────────┐
     │ InProgress   │
     └──────┬───────┘
            │ Complete
            ▼
       ┌─────────┐
       │  Done   │
       └─────────┘

Erlaubte Übergänge:
  Open → InProgress (StartWork)
  Open → Done (Complete — Shortcut für schnelle Tasks)
  InProgress → Done (Complete)
  InProgress → Open (Reopen)
  Done → Open (Reopen)
```

### 7.5 API-Endpunkte

```
GET    /api/bands/{bandId}/tasks                     → BandTaskDto[]
       ?status=Open&assignedTo={musicianId}&eventId={eventId}
GET    /api/bands/{bandId}/tasks/{taskId}             → BandTaskDto
POST   /api/bands/{bandId}/tasks                      → BandTaskDto (201)
PUT    /api/bands/{bandId}/tasks/{taskId}              → BandTaskDto
DELETE /api/bands/{bandId}/tasks/{taskId}              → 204

# Status-Übergänge
POST   /api/bands/{bandId}/tasks/{taskId}/start       → BandTaskDto
POST   /api/bands/{bandId}/tasks/{taskId}/complete     → BandTaskDto
POST   /api/bands/{bandId}/tasks/{taskId}/reopen       → BandTaskDto

# Zuweisungen
POST   /api/bands/{bandId}/tasks/{taskId}/assign
       Body: { musicianIds: [...] }                    → TaskAssignmentDto[]
DELETE /api/bands/{bandId}/tasks/{taskId}/assign/{musicianId}
                                                       → 204
```

### 7.6 Berechtigungen

| Aktion | Rollen |
|--------|--------|
| Tasks erstellen | Administrator, Conductor, SectionLeader |
| Tasks zuweisen | Administrator, Conductor, SectionLeader |
| Status ändern (eigene) | Jedes zugewiesene Mitglied |
| Status ändern (fremde) | Administrator, Conductor |
| Tasks löschen | Administrator, Ersteller |

### 7.7 Erinnerungen

Erinnerungen bei Fälligkeiten werden über das bestehende Push-Notification-System realisiert (MS2-Infrastruktur):

- **24h vor Fälligkeit:** Push an zugewiesene Musiker
- **Bei Fälligkeit:** Push an zugewiesene Musiker + Ersteller
- **Überfällig:** Tägliche Push bis erledigt (max. 7 Tage)

### 7.8 Event-Kopplung

Aufgaben können optional an Events gekoppelt werden (`EventId` FK). Beispiel: "Notenpulte aufbauen" an Konzert-Event gekoppelt. In der Event-Detail-Ansicht erscheinen verknüpfte Tasks.

### 7.9 Flutter-Modul-Struktur

```
sheetstorm_app/lib/features/tasks/
├── application/
│   ├── task_list_notifier.dart      # Aufgaben-Liste mit Filter
│   ├── task_detail_notifier.dart    # Einzel-Aufgabe + Assignments
│   └── *.g.dart
├── data/
│   ├── models/
│   │   └── task_models.dart         # BandTask, TaskAssignment, TaskStatus
│   └── services/
│       ├── task_service.dart        # REST-Client
│       └── task_service.g.dart
├── presentation/
│   ├── screens/
│   │   ├── task_list_screen.dart    # Aufgaben-Übersicht mit Filterleiste
│   │   ├── task_detail_screen.dart  # Detail mit Zuweisungen + Status
│   │   └── task_create_screen.dart  # Erstellen/Bearbeiten
│   └── widgets/
│       ├── task_card.dart           # Aufgaben-Karte (Kanban-Style)
│       ├── task_status_chip.dart    # Status-Badge mit Farbe
│       ├── task_assignee_row.dart   # Zugewiesene Musiker
│       └── task_filter_bar.dart     # Filter: Status, Zugewiesen, Event
└── routes.dart
```

---

## 8. Vollständige Datenbank-Schema-Erweiterung (EF Core Migration)

### Neue Tabellen (Zusammenfassung)

| Tabelle | Feature | Beziehungen |
|---------|---------|-------------|
| `SyncVersions` | Cloud-Sync | Musician 1:1 |
| `SyncChangelogs` | Cloud-Sync | Musician N:1 |
| `Annotations` | Annotationen-Sync | PiecePage N:1, Voice N:1, Band N:1, Musician N:1 |
| `AnnotationElements` | Annotationen-Sync | Annotation N:1, Musician N:1 |
| `BandTasks` | Aufgabenverwaltung | Band N:1, Event N:1, Musician N:1 |
| `TaskAssignments` | Aufgabenverwaltung | BandTask N:1, Musician N:1 |

### Migration-Name

```
YYYYMMDDHHMMSS_MS3_TunerMetronomeCloudSyncTasksAnnotationSync.cs
```

### Erweiterungen an bestehenden Entitäten

```csharp
// Band.cs — neue Navigation Properties
public ICollection<BandTask> Tasks { get; set; } = [];
public ICollection<Annotation> Annotations { get; set; } = [];

// Event.cs — neue Navigation Property
public ICollection<BandTask> LinkedTasks { get; set; } = [];

// Musician.cs — neue Navigation Property
public SyncVersion? SyncVersion { get; set; }
```

---

## 9. Vollständige API-Endpunkt-Übersicht

### Neue Controller

| Controller | Route-Prefix | Feature |
|------------|-------------|---------|
| `SyncController` | `/api/sync` | Cloud-Sync |
| `TaskController` | `/api/bands/{bandId}/tasks` | Aufgabenverwaltung |
| `AnnotationController` | `/api/bands/{bandId}/annotations` + `/api/annotations/personal` | Annotationen-Sync |

### Neue SignalR Hubs

| Hub | Route | Feature |
|-----|-------|---------|
| `MetronomeHub` | `/hubs/metronome` | Echtzeit-Metronom |
| `AnnotationSyncHub` | `/hubs/annotations` | Annotationen-Sync |

### Neuer UDP-Server

| Service | Port | Feature |
|---------|------|---------|
| `UdpMulticastServer` | 5100 (Beats), 5101 (ClockSync) | Echtzeit-Metronom |

---

## 10. Neue Backend-Dateistruktur

```
src/Sheetstorm.Domain/
├── Entities/
│   ├── SyncVersion.cs            # NEU
│   ├── SyncChangelog.cs          # NEU
│   ├── Annotation.cs             # NEU
│   ├── AnnotationElement.cs      # NEU
│   ├── BandTask.cs               # NEU
│   └── TaskAssignment.cs         # NEU
├── Enums/
│   ├── SyncOperation.cs          # NEU
│   ├── TaskStatus.cs             # NEU (Achtung: Namespace-Kollision mit System.Threading.Tasks.TaskStatus → Sheetstorm.Domain.Enums.BandTaskStatus)
│   ├── TaskPriority.cs           # NEU
│   ├── AnnotationLevel.cs        # NEU
│   └── AnnotationTool.cs         # NEU
├── Sync/
│   ├── ISyncService.cs           # NEU
│   └── SyncModels.cs             # NEU (DTOs: SyncStateDto, SyncPullRequest, etc.)
├── Tasks/
│   ├── ITaskService.cs           # NEU
│   └── TaskModels.cs             # NEU (DTOs: BandTaskDto, TaskAssignmentDto, etc.)
├── Annotations/
│   ├── IAnnotationSyncService.cs # NEU
│   └── AnnotationModels.cs       # NEU (DTOs)
└── Metronome/
    ├── IMetronomeService.cs      # NEU
    └── MetronomeModels.cs        # NEU (Session, ClockSync, DTOs)

src/Sheetstorm.Infrastructure/
├── Sync/
│   ├── SyncService.cs            # NEU
│   └── ISyncService.cs           # NEU (Interface)
├── Tasks/
│   └── TaskService.cs            # NEU
├── Annotations/
│   └── AnnotationSyncService.cs  # NEU
├── Metronome/
│   ├── MetronomeService.cs       # NEU (Singleton, Session-Verwaltung)
│   └── UdpMulticastServer.cs     # NEU (IHostedService)
└── Persistence/
    └── Configurations/
        ├── AnnotationConfiguration.cs       # NEU
        ├── AnnotationElementConfiguration.cs # NEU
        ├── BandTaskConfiguration.cs          # NEU
        ├── TaskAssignmentConfiguration.cs    # NEU
        ├── SyncVersionConfiguration.cs       # NEU
        └── SyncChangelogConfiguration.cs     # NEU

src/Sheetstorm.Api/
├── Controllers/
│   ├── SyncController.cs         # NEU
│   ├── TaskController.cs         # NEU
│   └── AnnotationController.cs   # NEU
└── Hubs/
    ├── SongBroadcastHub.cs       # BESTEHEND
    ├── MetronomeHub.cs           # NEU
    └── AnnotationSyncHub.cs      # NEU
```

---

## 11. Neue Flutter-Modul-Struktur (Zusammenfassung)

```
sheetstorm_app/lib/features/
├── tuner/                        # NEU — Stimmgerät
│   ├── application/
│   ├── data/models/
│   ├── data/services/
│   ├── data/native/
│   ├── presentation/screens/
│   ├── presentation/widgets/
│   └── routes.dart
├── metronome/                    # NEU — Echtzeit-Metronom
│   ├── application/
│   ├── data/models/
│   ├── data/services/
│   ├── data/audio/
│   ├── presentation/screens/
│   ├── presentation/widgets/
│   └── routes.dart
├── cloud_sync/                   # NEU — Cloud-Sync Engine
│   ├── application/
│   ├── data/models/
│   ├── data/services/
│   ├── data/local/
│   ├── presentation/screens/
│   ├── presentation/widgets/
│   └── routes.dart
├── tasks/                        # NEU — Aufgabenverwaltung
│   ├── application/
│   ├── data/models/
│   ├── data/services/
│   ├── presentation/screens/
│   ├── presentation/widgets/
│   └── routes.dart
├── annotations/                  # BESTEHEND — erweitert um Sync
│   ├── application/
│   │   └── annotation_sync_notifier.dart    # NEU
│   ├── data/
│   │   ├── models/
│   │   │   └── annotation_sync_models.dart  # NEU
│   │   └── services/
│   │       ├── annotation_sync_service.dart # NEU
│   │       └── annotation_realtime.dart     # NEU
│   └── ...
└── performance_mode/             # BESTEHEND — erweitert um Auto-Scroll
    ├── application/
    │   └── auto_scroll_notifier.dart        # NEU
    └── presentation/widgets/
        ├── auto_scroll_controls.dart        # NEU
        └── auto_scroll_speed_slider.dart    # NEU
```

---

## 12. Integration Points mit bestehendem System

| Neues Feature | Integriert mit | Art der Integration |
|---------------|---------------|---------------------|
| Tuner → Config | `ConfigController`, Geräte-Config | Kammerton aus Config lesen |
| Tuner → Instruments | `UserInstruments` | Transpositionsmodus aus Instrumentenprofil |
| Metronom → SongBroadcast | `SongBroadcastHub` | Gemeinsame Band-Gruppierung, paralleler Betrieb möglich |
| Metronom → Config | `ConfigController` | Default-BPM, Latenz-Kompensation |
| Cloud-Sync → Pieces | `Pieces`, `SheetMusic`, `PiecePages` | Sync-Changelog referenziert bestehende Entitäten |
| Cloud-Sync → "Meine Musik" | Band (`IsPersonal = true`) | Sync nur für persönliche Sammlung |
| Annotationen-Sync → Annotations | `annotations/` Flutter-Feature | Erweitert bestehenden Notifier um Sync-Hooks |
| Annotationen-Sync → Voices | `Voices`, `Memberships` | Stimmen-Gruppierung für Voice-Level Sync |
| Auto-Scroll → Performance Mode | `performance_mode/` Feature | Neuer Notifier + Widgets im bestehenden Modul |
| Auto-Scroll → Metronom | `metronome/` Feature | Optionale BPM-Kopplung |
| Tasks → Events | `Events` | Optionale Event-Verknüpfung |
| Tasks → Members | `Memberships` | Zuweisung an Band-Mitglieder |
| Tasks → Push | Bestehende Notification-Infrastruktur (MS2) | Erinnerungen bei Fälligkeiten |

---

## 13. Performance-Ziele und Mess-Strategie

| Feature | Metrik | Ziel | Messung |
|---------|--------|------|---------|
| Tuner | Audio-zu-Display Latenz | < 20ms | Stopwatch: Mikrofon-Tap → UI-Update |
| Metronom (UDP) | Client-zu-Client Sync-Abweichung | < 5ms | Zwei Geräte gleichzeitig aufnehmen, Beats vergleichen |
| Metronom (WebSocket) | Client-zu-Client Sync-Abweichung | < 50ms | Wie oben |
| Cloud-Sync | Delta-Sync für 100 Änderungen | < 2s | Netzwerk-Round-Trip inkl. DB-Operationen |
| Annotation-Sync | Element-Broadcast Latenz | < 100ms | SignalR Roundtrip-Messung |
| Auto-Scroll | Frame-Rate während Scroll | 60 FPS | Flutter DevTools Performance Overlay |

---

## 14. Sicherheitsaspekte

| Aspekt | Maßnahme |
|--------|----------|
| UDP Multicast | Nur im LAN erreichbar (kein Internet-Routing). Session-ID als minimale Authentifizierung. |
| SignalR Hubs | JWT-Authentifizierung (bestehend, Query-String Token-Extraktion). Membership-Prüfung pro Band. |
| Cloud-Sync | JWT-Auth. Sync nur eigene persönliche Sammlung (MusicianId aus JWT). |
| Annotation-Sync | JWT-Auth. Membership-Prüfung. Voice-Annotations nur für Mitglieder derselben Stimme. |
| Mikrofon-Zugriff | Platform-Permission-Dialog. Audio wird nie an Server gesendet (rein lokal). |

---

## 15. Offene Entscheidungen

| # | Thema | Optionen | Empfehlung |
|---|-------|----------|------------|
| 1 | BLE als dritter Metronom-Transport | BLE Broadcast neben UDP + WebSocket | Spätere Iteration — UDP + WebSocket decken alle Szenarien ab |
| 2 | Annotation-Konflikte UI | Silent LWW vs. Toast-Benachrichtigung bei Überschreibung | Toast mit "Deine Änderung wurde überschrieben von [Name]" |
| 3 | Cloud-Sync Binärdaten | S3-Sync für Notenbilder parallel oder sequentiell | Parallel — Bilder unabhängig vom Metadaten-Sync |
| 4 | Metronom-Session Persistierung | In-Memory vs. DB | In-Memory (analog SongBroadcast) — Probe-Tools sind ephemeral |
| 5 | `TaskStatus` Namespace | `BandTaskStatus` vs. `Sheetstorm.Domain.Enums.TaskStatus` | `BandTaskStatus` zur Vermeidung der Kollision mit `System.Threading.Tasks.TaskStatus` |

---

## Referenzierte Spezifikationen

| Spec | Inhalt |
|------|--------|
| `docs/specs/2026-03-30-metronome-protocol.md` | UDP/WebSocket Protokoll-Details, Byte-Layouts, Clock-Sync |
| `docs/specs/2026-03-30-cloud-sync-protocol.md` | Delta-Sync Protokoll, Konflikt-Auflösung, Offline-Queue |
| `docs/specs/2026-03-30-annotation-sync.md` | Op-Log Sync, SignalR-Gruppen, LWW-Strategie |

---

*Erstellt von Stark (Lead / Architect). Zur Review durch Thomas via PR.*
