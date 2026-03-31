# Feature: Metronom-Sync Protokoll

**Datum:** 2026-03-30
**Autor:** Stark (Lead / Architect)
**Status:** Draft
**Referenz:** `docs/specs/2026-03-30-ms3-architecture.md` §3

## Kontext

Das Echtzeit-Metronom synchronisiert Taktschläge zwischen dem Dirigenten und allen verbundenen Musikern. Zwei Transportwege: UDP Multicast (LAN, <5ms) und SignalR WebSocket (Fallback, <50ms).

Kernprinzip: **Beats als Timestamps, nicht als Live-Kommandos.** Der Server verteilt Session-Informationen (BPM, Startzeit), die Clients berechnen Beats lokal.

## Anforderungen

### Must-Have
- [ ] Clock-Synchronisation mit <1ms Genauigkeit im LAN
- [ ] UDP Multicast Server als `IHostedService` in ASP.NET Core 10
- [ ] SignalR Hub als Fallback bei nicht-erreichbarem UDP
- [ ] Automatische Transport-Erkennung (UDP-Probe → Fallback)
- [ ] Session Start/Stop/Update durch Conductor/Admin
- [ ] BPM-Änderung zur Laufzeit ohne Neusync
- [ ] Latenz-Kompensation pro Gerät (Config)

### Nice-to-Have
- [ ] BLE Broadcast als dritter Transport
- [ ] Akzentuierung (erster Beat betont)
- [ ] Subdivisions (Achtel, Triolen)

## Technisches Design

### Clock-Synchronisation

**Algorithmus (NTP-ähnlich):**

```
Schritt 1: Client sendet ClockSyncRequest
  Paket: { type: 0x01, clientSendTimeUs: T1 }

Schritt 2: Server empfängt bei T2, antwortet bei T3
  Paket: { type: 0x01, clientSendTimeUs: T1, serverRecvTimeUs: T2, serverSendTimeUs: T3 }

Schritt 3: Client empfängt bei T4
  roundTrip = (T4 - T1) - (T3 - T2)
  offset = ((T2 - T1) + (T3 - T4)) / 2

Schritt 4: Wiederhole 5x, verwerfe Ausreißer (> 2σ), nehme Median
```

**Zeitbasis:** Mikrosekunden seit Unix-Epoch (UTC). Auf allen Plattformen: `Stopwatch.GetTimestamp()` (.NET), `DateTime.now().microsecondsSinceEpoch` (Dart).

**Re-Sync:** Alle 30 Sekunden eine einzelne Messung. Gleitender Median über letzte 10 Messungen.

### UDP Multicast — Byte-Layout

Alle Werte Little-Endian. Minimaler Overhead für Latenz.

#### Message Header (alle Nachrichten)
```
Offset  Größe  Feld
0       1      MessageType
1       16     SessionId (GUID, Little-Endian)
17      ...    Payload (typ-abhängig)
```

#### ClockSync Request (Client → Server, Unicast an Port 5101)
```
Offset  Größe  Feld
0       1      0x01 (MessageType)
1       8      ClientSendTimeUs (int64)
Total: 9 Bytes
```

#### ClockSync Response (Server → Client, Unicast)
```
Offset  Größe  Feld
0       1      0x01 (MessageType)
1       8      ClientSendTimeUs (int64)
9       8      ServerRecvTimeUs (int64)
17      8      ServerSendTimeUs (int64)
Total: 25 Bytes
```

#### SessionStart (Server → Multicast)
```
Offset  Größe  Feld
0       1      0x02 (MessageType)
1       16     SessionId (GUID)
17      16     BandId (GUID)
33      2      BPM (uint16)
35      1      BeatsPerMeasure (uint8)
36      1      BeatUnit (uint8)
37      8      StartTimeUs (int64)
45      16     ConductorId (GUID)
Total: 61 Bytes
```

#### SessionStop (Server → Multicast)
```
Offset  Größe  Feld
0       1      0x03 (MessageType)
1       16     SessionId (GUID)
Total: 17 Bytes
```

#### SessionUpdate (Server → Multicast, BPM/Taktart-Änderung)
```
Offset  Größe  Feld
0       1      0x04 (MessageType)
1       16     SessionId (GUID)
17      2      NewBPM (uint16)
19      1      NewBeatsPerMeasure (uint8)
20      1      NewBeatUnit (uint8)
21      8      ChangeAtBeatNumber (int64)
29      8      NewStartTimeUs (int64, recalculierter Startpunkt)
Total: 37 Bytes
```

### SignalR Hub — Methoden

#### Client → Server

| Methode | Parameter | Berechtigung |
|---------|-----------|-------------|
| `StartSession` | `bandId`, `bpm`, `beatsPerMeasure`, `beatUnit` | Conductor, Administrator |
| `StopSession` | `bandId` | Conductor, Administrator |
| `UpdateSession` | `bandId`, `bpm`, `beatsPerMeasure`, `beatUnit` | Conductor, Administrator |
| `RequestClockSync` | `clientSendTimeUs` | Alle Mitglieder |
| `JoinSession` | `bandId` | Alle Mitglieder |
| `LeaveSession` | `bandId` | Alle Mitglieder |

#### Server → Client

| Event | Payload |
|-------|---------|
| `OnSessionStarted` | `{ sessionId, bandId, bpm, beatsPerMeasure, beatUnit, startTimeUs, conductorId, conductorName }` |
| `OnSessionStopped` | `{ sessionId, bandId }` |
| `OnSessionUpdated` | `{ sessionId, bandId, bpm, beatsPerMeasure, beatUnit, changeAtBeatNumber, newStartTimeUs }` |
| `OnClockSyncResponse` | `{ clientSendTimeUs, serverRecvTimeUs, serverSendTimeUs }` |
| `OnParticipantCountChanged` | `{ bandId, count }` |

### Beat-Berechnung (Client-seitig)

```dart
class BeatCalculator {
  final int bpm;
  final int beatsPerMeasure;
  final int startTimeUs;
  final Duration clockOffset;

  int get beatIntervalUs => (60000000 / bpm).round();

  /// Gibt zurück: (beatNumber, microsecondsToNextBeat, isDownbeat)
  (int, int, bool) getCurrentBeat() {
    final serverNowUs = DateTime.now().microsecondsSinceEpoch + clockOffset.inMicroseconds;
    final elapsedUs = serverNowUs - startTimeUs;
    if (elapsedUs < 0) return (0, -elapsedUs, true);

    final beatNumber = elapsedUs ~/ beatIntervalUs;
    final nextBeatUs = startTimeUs + (beatNumber + 1) * beatIntervalUs;
    final toNextUs = nextBeatUs - serverNowUs;
    final isDownbeat = (beatNumber % beatsPerMeasure) == 0;

    return (beatNumber, toNextUs, isDownbeat);
  }
}
```

### Transport-Erkennung

```dart
Future<MetronomeTransport> detectTransport(String serverHost) async {
  // 1. Client lauscht 2s auf UDP Multicast (239.255.77.77:5100)
  //    Server sendet alle 500ms ein Heartbeat-Paket (0x00, 8 bytes timestamp)
  // 2. Empfängt Paket → UDP verfügbar
  // 3. Timeout → WebSocket Fallback
  //
  // Heuristik: WiFi-verbunden UND gleiches Subnetz wie Server → UDP probieren
  //            Mobilfunk oder anderes Netz → direkt WebSocket
}
```

### ASP.NET Core Integration

```csharp
// Program.cs — Ergänzungen
builder.Services.Configure<MetronomeUdpOptions>(
    builder.Configuration.GetSection("Metronome:Udp"));
builder.Services.AddSingleton<IMetronomeService, MetronomeService>();
builder.Services.AddHostedService<UdpMulticastServer>();

app.MapHub<MetronomeHub>("/hubs/metronome");

// appsettings.json
{
  "Metronome": {
    "Udp": {
      "MulticastGroup": "239.255.77.77",
      "Port": 5100,
      "ClockSyncPort": 5101,
      "HeartbeatIntervalMs": 500
    }
  }
}
```

## File-Structure-Map

**CREATE:**
- `src/Sheetstorm.Domain/Metronome/IMetronomeService.cs`
- `src/Sheetstorm.Domain/Metronome/MetronomeModels.cs`
- `src/Sheetstorm.Infrastructure/Metronome/MetronomeService.cs`
- `src/Sheetstorm.Infrastructure/Metronome/UdpMulticastServer.cs`
- `src/Sheetstorm.Api/Hubs/MetronomeHub.cs`
- `sheetstorm_app/lib/features/metronome/` (gesamtes Modul)

**MODIFY:**
- `src/Sheetstorm.Api/Program.cs` — Hub-Mapping + DI + Hosted Service
- `src/Sheetstorm.Api/appsettings.json` — Metronom-Config
- `sheetstorm_app/lib/` — GoRouter-Routes für Metronom

## Offene Fragen

- [ ] BLE Broadcast: Soll als dritter Transport in MS3 oder als spätere Iteration implementiert werden?
- [ ] Multicast-Gruppe: `239.255.77.77` oder anderer Bereich? (RFC 5771 empfiehlt 239.0.0.0/8 für lokale Nutzung)
- [ ] Heartbeat auf UDP: Notwendig für Transport-Erkennung oder reicht ein Probe-Paket?
