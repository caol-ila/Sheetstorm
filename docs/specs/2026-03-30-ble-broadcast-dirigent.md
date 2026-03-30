# Feature: BLE-Broadcast — Dirigent-zu-Musiker

**Datum:** 2026-03-30
**Autor:** Strange (Principal Backend Engineer)
**Status:** Draft

---

## Kontext

Sheetstorm ermöglicht dem Dirigenten, während Proben und Auftritten Stückwechsel, Metronom-Beats und Annotations-Updates an alle Musiker zu senden. Die bestehende Implementierung nutzt SignalR (WebSocket) über einen zentralen Server — das erfordert Internet-Zugang und einen laufenden Backend-Server.

Für **lokale Proben ohne Internet** wird BLE (Bluetooth Low Energy) als **primärer Transport** eingeführt:

- **Dirigent = BLE Peripheral** (advertiset einen GATT-Service)
- **Musiker = BLE Central** (scannen und verbinden sich)
- **Kein Server nötig** — vollständig offline-fähig
- **SignalR bleibt als Remote-Fallback** für entfernte Teilnehmer

### Warum BLE statt UDP/WiFi?

| Kriterium | BLE GATT | WiFi UDP | WebSocket/SignalR |
|-----------|----------|----------|-------------------|
| Offline-fähig | ✅ Ja | ⚠️ Lokales Netzwerk nötig | ❌ Server nötig |
| Latenz | < 20ms | < 5ms | 50–200ms |
| Pairing | Nicht nötig | Nicht nötig | Auth nötig |
| Max Teilnehmer | ~20 (BLE 5.x) | Unbegrenzt | Unbegrenzt |
| Stromverbrauch | Sehr niedrig | Mittel | Hoch |
| Reichweite | ~30m (Indoor) | ~50m (Indoor) | Unbegrenzt |

**Entscheidung (Stark MS3-Alignment):** BLE GATT als primärer P2P-Transport. UDP wurde verworfen wegen der Abhängigkeit von einem gemeinsamen WiFi-Netzwerk.

---

## Anforderungen

### Must-Have

- [ ] GATT-Service mit Characteristics für Song-Broadcast, Metronom, Annotations-Invalidierung und Session-Kontrolle
- [ ] Sicherheitskonzept: HMAC-SHA256 signierte Nachrichten mit Pre-Shared Session Key
- [ ] Leader-Identifikation: Nur der identifizierte Dirigent kann steuernde Broadcasts senden
- [ ] Replay-Protection: Sequenznummern + Timestamps in signierten Payloads
- [ ] Hybrid-Modus: BLE primär, SignalR als Fallback, transparenter Wechsel
- [ ] Offline-fähige Proben ohne Server-Abhängigkeit
- [ ] Reconnect bei BLE-Verbindungsverlust in < 2 Sekunden
- [ ] Beat-Genauigkeit des Metronoms < 5ms Jitter
- [ ] Annotations-Invalidierung: Nur Signal (Stück-GUID + Stimme), keine Daten über BLE
- [ ] Android- und iOS-BLE-Berechtigungen konfiguriert

### Nice-to-Have

- [ ] BLE Extended Advertising für größere Payloads (BLE 5.x)
- [ ] Automatische Latenz-Kompensation pro Musiker
- [ ] BLE-Mesh für > 20 Teilnehmer (Relay-Modus über verbundene Geräte)
- [ ] Verbindungsqualitäts-Indikator im UI (RSSI-basiert)
- [ ] Batterie-Level-Characteristic des Dirigenten-Geräts

---

## Technisches Design

### 1. GATT-Architektur

#### 1.1 Service-Definition

```
GATT Service: Sheetstorm Broadcast Service
  UUID: 0x5353-0001-0000-1000-8000-00805F9B34FB
  (Custom 128-bit UUID, Prefix "SS" = 0x5353)

Characteristics:
  ┌─────────────────────────────────────────────────────────────────┐
  │ Song Selection (Notify + Read)                                  │
  │ UUID: 0x5353-0002-...                                           │
  │ Beschreibung: Aktuelles Stück (ID + Titel)                     │
  │ Zugriff: Dirigent schreibt, Musiker lesen/subscriben            │
  ├─────────────────────────────────────────────────────────────────┤
  │ Metronome Beat (Notify)                                         │
  │ UUID: 0x5353-0003-...                                           │
  │ Beschreibung: BPM, Taktart, Beat-Timestamps                    │
  │ Zugriff: Dirigent schreibt, Musiker subscriben                  │
  ├─────────────────────────────────────────────────────────────────┤
  │ Annotation Invalidation (Notify)                                │
  │ UUID: 0x5353-0004-...                                           │
  │ Beschreibung: Stück-GUID + Stimme + "has update"                │
  │ Zugriff: Alle authentifizierten Mitglieder können schreiben     │
  ├─────────────────────────────────────────────────────────────────┤
  │ Session Control (Write + Notify + Read)                         │
  │ UUID: 0x5353-0005-...                                           │
  │ Beschreibung: Start/Stop/Status der Session                     │
  │ Zugriff: Nur Dirigent schreibt, Musiker lesen/subscriben        │
  ├─────────────────────────────────────────────────────────────────┤
  │ Security Handshake (Write + Read)                               │
  │ UUID: 0x5353-0006-...                                           │
  │ Beschreibung: Challenge-Response Authentifizierung               │
  │ Zugriff: Musiker schreiben Challenge, Dirigent antwortet        │
  └─────────────────────────────────────────────────────────────────┘
```

#### 1.2 Rollen-Mapping

| Rolle | BLE-Rolle | Verhalten |
|-------|-----------|-----------|
| **Dirigent** | Peripheral (GATT Server) | Advertiset den Service, akzeptiert Verbindungen, schreibt Characteristics |
| **Musiker** | Central (GATT Client) | Scannt nach dem Service, verbindet sich, subscribt auf Notifications |

**Bibliotheken:**
- **Central (Musiker):** `flutter_blue_plus` (v1.34.5) — plattformübergreifender BLE-Scanner und GATT-Client
- **Peripheral (Dirigent):** `flutter_ble_peripheral` — GATT-Server-Fähigkeit auf Android/iOS

**Kein Pairing nötig:** BLE-Verbindung erfolgt ohne Betriebssystem-Pairing. Authentifizierung läuft über das anwendungseigene Session-Key-Verfahren (siehe Abschnitt 2).

#### 1.3 Advertising-Daten

Der Dirigent advertiset mit folgenden Daten:

```
Advertising Payload (max 31 Bytes Legacy / 254 Bytes Extended):
┌──────────────────────────────────────────┐
│ Service UUID:    0x5353-0001-...          │  16 Bytes
│ Local Name:      "SS:<KapelleID-kurz>"   │  ~12 Bytes
│ TX Power Level:  (automatisch)           │
└──────────────────────────────────────────┘

Scan Response (zusätzlich):
┌──────────────────────────────────────────┐
│ Manufacturer Data:                        │
│   Session-ID (8 Bytes, truncated UUID)   │
│   Leader-Device-ID (4 Bytes, Hash)       │
│   Flags: [isActive, hasSetlist]          │
└──────────────────────────────────────────┘
```

Musiker-Geräte filtern beim Scan auf den Service-UUID `0x5353-0001` und matchen die Kapelle-ID.

---

### 2. Sicherheitskonzept

> **Thomas-Direktive:** „Die Geräte wissen durch die Teilnahme an einer Probe oder einem Auftritt, wer broadcasten kann. Der Leader sollte eindeutig erkennbar sein und die Endgeräte der Teilnehmer sollten nur diesem folgen."

#### 2.1 Pre-Shared Session Key

Beim Start einer Probe oder eines Auftritts generiert der **Backend-Server** einen kryptographischen Session Key:

```
┌─────────────┐       POST /api/v1/broadcast/sessions          ┌──────────┐
│  Dirigent    │ ─────────────────────────────────────────────→ │  Server  │
│  (App)       │                                                │          │
│              │ ←──── Response:                                │          │
│              │       {                                        │          │
│              │         sessionId: "uuid",                     │          │
│              │         sessionKey: "base64(32 bytes)",        │          │
│              │         leaderDeviceId: "device-uuid",         │          │
│              │         expiresAt: "ISO-8601"                  │          │
│              │       }                                        │          │
└─────────────┘                                                 └──────────┘

┌─────────────┐       GET /api/v1/broadcast/sessions/active     ┌──────────┐
│  Musiker     │ ─────────────────────────────────────────────→ │  Server  │
│  (App)       │                                                │          │
│              │ ←──── Response:                                │          │
│              │       {                                        │          │
│              │         sessionId: "uuid",                     │          │
│              │         sessionKey: "base64(32 bytes)",        │          │
│              │         leaderDeviceId: "device-uuid",         │          │
│              │         ...                                    │          │
│              │       }                                        │          │
└─────────────┘                                                 └──────────┘
```

**Schlüsselgenerierung:**
- `RandomNumberGenerator.GetBytes(32)` → 256-Bit HMAC-SHA256-Key
- Schlüssel wird über die **authentifizierte REST-API** (JWT Bearer Token) verteilt
- Nur Mitglieder der Kapelle mit gültigem Session-Token erhalten den Session Key
- Key ist **an die Session-ID gebunden** — neue Session = neuer Key

**Offline-Szenario (ohne Server):**
Wenn kein Server erreichbar ist, generiert der Dirigent den Session Key **lokal** auf seinem Gerät:

```
Dirigent-Gerät:
  1. Generiert sessionKey = SecureRandom(32 Bytes)
  2. Zeigt QR-Code oder 6-stelligen PIN im UI
  3. Musiker scannen QR / geben PIN ein → erhalten sessionKey + leaderDeviceId

Alternativ (automatisch):
  1. Dirigent öffnet BLE-Session
  2. Musiker verbinden sich über BLE
  3. Schlüsselaustausch über Security-Handshake-Characteristic (Abschnitt 2.3)
```

#### 2.2 Nachrichtensignaturen (HMAC-SHA256)

**Jede BLE-Nachricht** wird mit HMAC-SHA256 signiert:

```
┌─────────────────────────────────────────────────────────┐
│ BLE Message Format                                       │
├─────────────────────────────────────────────────────────┤
│ Header (4 Bytes):                                        │
│   [0]     Message Type   (uint8)                         │
│   [1..2]  Sequence Number (uint16, Big Endian)           │
│   [3]     Flags          (uint8)                         │
│                                                          │
│ Timestamp (4 Bytes):                                     │
│   [4..7]  Unix Epoch Seconds, truncated (uint32)         │
│                                                          │
│ Payload (Variable, max 182 Bytes):                       │
│   [8..N]  Nachrichteninhalt (je nach Type)               │
│                                                          │
│ HMAC Signature (32 Bytes):                               │
│   [N+1..N+32]  HMAC-SHA256(sessionKey, Header+Timestamp+Payload)  │
└─────────────────────────────────────────────────────────┘

Maximale Nachrichtengröße: 4 + 4 + 182 + 32 = 222 Bytes
(Passt in BLE ATT MTU von 247 Bytes mit 3 Bytes ATT-Header)
```

**Message Types:**

| Type-ID | Name | Sender | Beschreibung |
|---------|------|--------|--------------|
| `0x01` | `SONG_CHANGED` | Dirigent | Stückwechsel (ID + Titel) |
| `0x02` | `METRONOME_BEAT` | Dirigent | Beat-Timing (BPM, Taktart, Beat-Nr.) |
| `0x03` | `ANNOTATION_INVALIDATED` | Alle Auth. | Stück-GUID + Stimme hat Update |
| `0x10` | `SESSION_START` | Dirigent | Session gestartet |
| `0x11` | `SESSION_STOP` | Dirigent | Session beendet |
| `0x12` | `SESSION_STATUS` | Dirigent | Heartbeat / Status-Update |
| `0xF0` | `AUTH_CHALLENGE` | Musiker | Challenge für Handshake |
| `0xF1` | `AUTH_RESPONSE` | Dirigent | Response auf Challenge |

**Verifikation auf Empfänger-Seite:**

```dart
bool verifyMessage(Uint8List message, Uint8List sessionKey) {
  final payloadEnd = message.length - 32;
  final payload = message.sublist(0, payloadEnd);
  final receivedHmac = message.sublist(payloadEnd);

  final hmac = Hmac(sha256, sessionKey);
  final expectedHmac = hmac.convert(payload).bytes;

  // Constant-time comparison (timing-attack-sicher)
  return constantTimeEquals(receivedHmac, expectedHmac);
}
```

#### 2.3 Challenge-Response Authentifizierung

Beim Verbindungsaufbau authentifiziert sich jeder Musiker:

```
Musiker (Central)                          Dirigent (Peripheral)
     │                                           │
     │──── BLE Connect ───────────────────────→  │
     │                                           │
     │──── Write AUTH_CHALLENGE ──────────────→  │
     │     { nonce: random(16), deviceId }       │
     │                                           │
     │                    Dirigent prüft:         │
     │                    1. deviceId bekannt?    │
     │                    2. HMAC(sessionKey,     │
     │                       nonce + deviceId)    │
     │                                           │
     │  ←── Notify AUTH_RESPONSE ──────────────  │
     │     { hmac: HMAC(sessionKey, nonce),      │
     │       leaderDeviceId, sessionInfo }       │
     │                                           │
     │     Musiker prüft:                        │
     │     1. HMAC korrekt? (beweist Key-Besitz) │
     │     2. leaderDeviceId == erwartet?         │
     │                                           │
     │  ✅ Authentifiziert — Subscribe Notify     │
     │──── Subscribe Song/Metronome/etc ──────→  │
     │                                           │
```

**Wichtig:** Der Challenge-Response beweist **beidseitig**, dass beide Seiten den Session Key besitzen, ohne ihn zu übertragen. Der Dirigent beweist seine Identität durch korrektes Signieren des Nonce.

#### 2.4 Trust-Modell je Event-Typ

| Event-Typ | Erlaubter Sender | Trust Level | Begründung |
|-----------|-----------------|-------------|------------|
| `SONG_CHANGED` | **Nur Dirigent** | Höchste | Stückwechsel ist Dirigenten-Hoheit |
| `METRONOME_BEAT` | **Nur Dirigent** | Höchste | Tempo gibt der Dirigent vor |
| `SESSION_START/STOP/STATUS` | **Nur Dirigent** | Höchste | Session-Kontrolle ist Dirigenten-Sache |
| `ANNOTATION_INVALIDATED` | **Alle Auth. Mitglieder** | Standard | Jeder kann eigene Annotationen ändern |

**Durchsetzung:**

```dart
bool isAuthorizedSender(int messageType, String senderDeviceId, SessionInfo session) {
  // Dirigenten-exklusive Message Types
  const conductorOnlyTypes = {0x01, 0x02, 0x10, 0x11, 0x12};

  if (conductorOnlyTypes.contains(messageType)) {
    return senderDeviceId == session.leaderDeviceId;
  }

  // Annotation Invalidation: Jedes authentifizierte Mitglied
  if (messageType == 0x03) {
    return session.authenticatedDevices.contains(senderDeviceId);
  }

  return false;
}
```

#### 2.5 Replay-Protection

Jede Nachricht enthält:
1. **Sequence Number** (uint16): Monoton steigend pro Sender. Empfänger verwerfen Nachrichten mit `seq <= lastSeenSeq[sender]`.
2. **Timestamp** (uint32): Unix-Epoch in Sekunden. Empfänger verwerfen Nachrichten, die **> 5 Sekunden** in der Vergangenheit liegen (Toleranz für BLE-Latenz + Clock-Drift).

```dart
class ReplayProtection {
  final Map<String, int> _lastSeqBySender = {};
  static const _maxTimeDriftSeconds = 5;

  bool isValid(String senderId, int sequenceNumber, int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Timestamp-Check
    if ((now - timestamp).abs() > _maxTimeDriftSeconds) return false;

    // Sequence-Check
    final lastSeq = _lastSeqBySender[senderId] ?? -1;
    if (sequenceNumber <= lastSeq) return false;

    _lastSeqBySender[senderId] = sequenceNumber;
    return true;
  }
}
```

**Sequence-Number-Overflow:** Bei uint16 (0–65535) reicht der Zähler für ~18 Stunden bei 1 Nachricht/Sekunde. Bei Overflow wird auf 0 zurückgesetzt, was eine einmalige Akzeptanz eines niedrigeren Werts erfordert. Alternativ: Session-Neustart bei langen Events.

#### 2.6 Session-Lebenszyklus

```
┌──────────────────────────────────────────────────────────────────┐
│                    Session Lifecycle                               │
│                                                                   │
│  ┌─────────┐     ┌──────────┐     ┌──────────┐     ┌─────────┐  │
│  │  IDLE    │────→│ STARTING │────→│  ACTIVE  │────→│ ENDING  │  │
│  └─────────┘     └──────────┘     └──────────┘     └─────────┘  │
│       │                                │                  │       │
│       │                                │  Timeout/Error   │       │
│       │                                ▼                  │       │
│       │                          ┌──────────┐             │       │
│       │                          │ SUSPENDED│─────────────│       │
│       │                          └──────────┘             │       │
│       │                                                   │       │
│       │←──────────────────────────────────────────────────┘       │
│                                                                   │
│  Session Key gültig: nur während ACTIVE/SUSPENDED                 │
│  Bei ENDING/IDLE: Key wird verworfen, Sequence Counter reset      │
└──────────────────────────────────────────────────────────────────┘
```

**Regeln:**
- **Neuer Key pro Session:** Jede Session erhält einen frischen 256-Bit-Key
- **Key-Ablauf:** Keys sind maximal **4 Stunden** gültig (längste Probe/Auftritt)
- **Explizite Beendigung:** Dirigent sendet `SESSION_STOP` → alle Clients verwerfen Key
- **Timeout:** Kein Heartbeat > 60 Sekunden → Clients wechseln zu `SUSPENDED`, nach 5 Minuten → Key verwerfen

---

### 3. Payload-Definitionen

#### 3.1 Song Changed (0x01)

```
Payload (max 182 Bytes):
┌────────────────────────────────────────────┐
│ [0..15]   Stück-UUID (16 Bytes, Binary)    │
│ [16..17]  Titel-Länge (uint16)             │
│ [18..N]   Titel (UTF-8, max 164 Bytes)     │
└────────────────────────────────────────────┘
```

#### 3.2 Metronome Beat (0x02)

```
Payload (14 Bytes, feste Größe):
┌────────────────────────────────────────────┐
│ [0..1]    BPM (uint16, z.B. 120)           │
│ [2]       Zähler der Taktart (uint8, z.B. 4)│
│ [3]       Nenner der Taktart (uint8, z.B. 4)│
│ [4..7]    Beat-Timestamp (uint32, ms seit   │
│           Session-Start)                    │
│ [8..9]    Beat-Nummer im Takt (uint16)      │
│ [10..13]  Nächster Beat in ms (uint32,      │
│           vorausberechneter Timestamp)      │
└────────────────────────────────────────────┘
```

**Wichtig für Latenz-Kompensation:** Der `Nächster-Beat`-Timestamp erlaubt dem Musiker-Gerät, den Beat **vorauszuberechnen** statt auf die BLE-Übertragung zu warten. So wird BLE-Jitter kompensiert.

#### 3.3 Annotation Invalidation (0x03)

```
Payload (max 50 Bytes):
┌────────────────────────────────────────────┐
│ [0..15]   Stück-GUID (16 Bytes, Binary)    │
│ [16..17]  Stimme-ID-Länge (uint16)         │
│ [18..N]   Stimme-ID (UTF-8, max ~30 Bytes) │
│ [N+1]     Update-Typ (uint8):              │
│            0x01 = Neue Annotation           │
│            0x02 = Geänderte Annotation      │
│            0x03 = Gelöschte Annotation      │
└────────────────────────────────────────────┘
```

> **Thomas-Direktive:** „BLE transportiert NICHT die Annotationen selbst, nur die Benachrichtigung. Die eigentlichen Annotationsdaten werden über die REST-API nachgeladen."

Empfänger-Logik bei Annotation-Invalidierung:
1. BLE-Signal empfangen: „Stück X, Stimme Y hat Update"
2. Wenn Stück X gerade geöffnet ist → REST-API-Aufruf: `GET /api/v1/pieces/{pieceId}/voices/{voiceId}/annotations?since={lastSync}`
3. Wenn Stück X nicht geöffnet → Marker setzen, beim nächsten Öffnen synchronisieren

#### 3.4 Session Control (0x10, 0x11, 0x12)

```
SESSION_START (0x10) Payload:
┌────────────────────────────────────────────┐
│ [0..15]   Session-UUID (16 Bytes)          │
│ [16..31]  Kapelle-UUID (16 Bytes)          │
│ [32]      Flags (uint8):                   │
│            Bit 0: hasSetlist               │
│            Bit 1: isRehearsalMode          │
│            Bit 2: isConcertMode            │
└────────────────────────────────────────────┘

SESSION_STOP (0x11) Payload:
┌────────────────────────────────────────────┐
│ [0..15]   Session-UUID (16 Bytes)          │
│ [16]      Reason (uint8):                  │
│            0x00 = Normal                   │
│            0x01 = Timeout                  │
│            0x02 = Error                    │
└────────────────────────────────────────────┘

SESSION_STATUS (0x12) Payload:
┌────────────────────────────────────────────┐
│ [0..15]   Session-UUID (16 Bytes)          │
│ [16]      Verbundene Musiker (uint8)       │
│ [17..20]  Uptime Sekunden (uint32)         │
└────────────────────────────────────────────┘
```

---

### 4. Performance-Ziele

| Metrik | Ziel | Kritisch | Maßnahme |
|--------|------|----------|----------|
| BLE-Latenz (Dirigent → Musiker) | < 20ms | < 50ms | Connection Interval = 7.5ms (BLE Minimum), Notify statt Indicate |
| Max verbundene Musiker | 20 (BLE 5.x) | 7 (BLE 4.2 garantiert) | Android: max 7–15 je nach Gerät, iOS: bis 20 |
| Reconnect-Zeit | < 2 Sekunden | < 5 Sekunden | Background-Scan mit Service-UUID-Filter, Cached GATT-Handles |
| Beat-Genauigkeit (Metronom) | < 5ms Jitter | < 10ms Jitter | Vorausberechnete Beat-Timestamps, lokaler Timer auf Empfänger |
| Connection Interval | 7.5ms | 15ms | `requestConnectionPriority(HIGH)` auf Android |
| MTU-Größe | 247 Bytes | 185 Bytes | MTU-Negotiation beim Verbindungsaufbau |
| Advertising Interval | 100ms | 200ms | Schnelles Discovery, höherer Stromverbrauch akzeptabel während Session |

#### 4.1 Latenz-Optimierungen

1. **Connection Interval minimieren:** Android erlaubt `CONNECTION_PRIORITY_HIGH` (7.5ms Interval). iOS verwaltet dies automatisch.
2. **Notify statt Indicate:** Notifications benötigen keine Bestätigung → halbe Latenz gegenüber Indications.
3. **Vorausberechnete Timestamps:** Metronom-Beats senden den **nächsten** Beat-Timestamp voraus. Der Empfänger nutzt seinen lokalen Timer und korrigiert nur bei Drift.
4. **MTU maximieren:** Beim Verbindungsaufbau wird die maximale MTU verhandelt (bis 512 Bytes). Dadurch passen alle Payloads in eine einzige BLE-Transaktion.

---

### 5. Hybrid-Modus: BLE + SignalR

#### 5.1 Transport-Hierarchie

```
┌───────────────────────────────────────────────────────────┐
│                  BroadcastNotifier                         │
│  (Verwaltet den aktiven Transport transparent)             │
│                                                           │
│  ┌──────────────┐    ┌──────────────┐                     │
│  │  BLE Transport│    │ SignalR       │                     │
│  │  (Primär)     │    │ Transport    │                     │
│  │              │    │ (Fallback)   │                     │
│  └──────┬───────┘    └──────┬───────┘                     │
│         │                    │                             │
│         ▼                    ▼                             │
│  ┌──────────────────────────────────────┐                 │
│  │  IBroadcastTransport (Interface)      │                 │
│  │  - connect()                          │                 │
│  │  - disconnect()                       │                 │
│  │  - sendSongChanged(...)               │                 │
│  │  - sendMetronomeBeat(...)             │                 │
│  │  - sendAnnotationInvalidation(...)    │                 │
│  │  - onSongChanged: Stream             │                 │
│  │  - onMetronomeBeat: Stream           │                 │
│  │  - onAnnotationInvalidated: Stream   │                 │
│  │  - onSessionControl: Stream          │                 │
│  │  - connectionState: Stream           │                 │
│  └──────────────────────────────────────┘                 │
└───────────────────────────────────────────────────────────┘
```

#### 5.2 Auto-Detection-Logik

```dart
enum TransportType { ble, signalR, none }

Future<TransportType> detectBestTransport() async {
  // 1. BLE verfügbar und Dirigent in Reichweite?
  if (await _isBleAvailable()) {
    final bleSession = await _scanForBleSession(timeout: Duration(seconds: 3));
    if (bleSession != null) return TransportType.ble;
  }

  // 2. Server erreichbar?
  if (await _isServerReachable()) {
    return TransportType.signalR;
  }

  // 3. Kein Transport verfügbar
  return TransportType.none;
}
```

#### 5.3 Szenarien

| Szenario | Transport | Verhalten |
|----------|-----------|-----------|
| **Lokale Probe, alle anwesend** | BLE only | Dirigent = Peripheral, kein Server nötig |
| **Probe mit Remote-Teilnehmer** | BLE + SignalR | Lokale Musiker über BLE, Remote über SignalR. Dirigent bridget Events |
| **Rein Remote (Distanz-Probe)** | SignalR only | Wie bisher, kein BLE |
| **BLE-Ausfall während Probe** | Fallback zu SignalR | Automatischer Wechsel, Musiker merkt kurzes „Reconnecting" |
| **Server-Ausfall + BLE vorhanden** | BLE only | Fortsetzen ohne Server, Annotations-Sync pausiert |

#### 5.4 Bridge-Modus (Dirigent)

Im Hybrid-Szenario (BLE + Remote-Teilnehmer) agiert der Dirigent als **Bridge**:

```
┌──────────────┐   BLE    ┌──────────────┐   SignalR   ┌──────────┐
│ Lokale        │ ←──────→ │  Dirigent    │ ←─────────→ │  Server  │
│ Musiker       │          │  (Bridge)    │             │          │
└──────────────┘           └──────────────┘             └──────────┘
                                                              │
                                                              │ SignalR
                                                              ▼
                                                        ┌──────────┐
                                                        │  Remote  │
                                                        │  Musiker │
                                                        └──────────┘
```

Der Dirigent:
1. Sendet Events gleichzeitig über BLE (Notify) und SignalR (Hub Invoke)
2. Empfängt Annotation-Invalidierungen von lokalen Musikern (BLE) und leitet sie an den Server weiter (für Remote-Musiker)
3. Empfängt Annotation-Invalidierungen von Remote-Musikern (SignalR) und leitet sie über BLE weiter

---

### 6. Integration mit bestehender Architektur

#### 6.1 Erweiterung des BroadcastNotifier

Der bestehende `BroadcastNotifier` wird um Transport-Abstraktion erweitert:

```dart
// Bestehend (wird erweitert, nicht ersetzt):
enum BroadcastMode { idle, connecting, broadcasting, receiving, error }

// NEU: Transport-Typ im State
class BroadcastState {
  final BroadcastMode mode;
  final BroadcastSession? session;
  final List<ConnectedMusician> connectedMusicians;
  final SongChangedPayload? currentSong;
  final TransportType activeTransport;  // NEU
  final BleConnectionState? bleState;   // NEU
  final SignalRConnectionState connectionState;
  // ...
}
```

#### 6.2 Erweiterung der Models

```dart
// NEU in broadcast_models.dart:

class MetronomeBeatPayload {
  final int bpm;
  final int beatsPerMeasure;   // Zähler der Taktart
  final int beatUnit;          // Nenner der Taktart
  final int beatTimestampMs;   // ms seit Session-Start
  final int beatNumberInMeasure;
  final int nextBeatMs;        // vorausberechneter nächster Beat
}

class AnnotationInvalidationPayload {
  final String stueckGuid;
  final String stimmeId;
  final AnnotationUpdateType updateType;
}

enum AnnotationUpdateType { created, modified, deleted }

// NEU: BLE-spezifische Session-Info
class BleSessionInfo {
  final String sessionKey;       // HMAC-Key (Base64)
  final String leaderDeviceId;   // Geräte-ID des Dirigenten
  final DateTime expiresAt;
}
```

---

### 7. BLE-Berechtigungen (Plattform-spezifisch)

#### 7.1 Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />

<!-- Für Android < 12 (API < 31) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

<uses-feature android:name="android.hardware.bluetooth_le"
    android:required="false" />
```

#### 7.2 iOS

```xml
<!-- Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Sheetstorm verwendet Bluetooth, um Stückwechsel und Metronom-Signale vom Dirigenten zu empfangen.</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>Als Dirigent sendet Sheetstorm Broadcast-Signale über Bluetooth an alle Musiker.</string>

<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
</array>
```

**Wichtig:** iOS Background-Mode für `bluetooth-central` und `bluetooth-peripheral` ist essenziell — ohne diese Einträge wird die BLE-Verbindung getrennt, wenn die App in den Hintergrund geht (z.B. beim Notenlesen in einer anderen App).

---

## File-Structure-Map

### CREATE (Neue Dateien)

```
sheetstorm_app/lib/features/song_broadcast/
├── data/
│   ├── services/
│   │   ├── ble_broadcast_service.dart         # BLE-Transport (Central + Peripheral)
│   │   ├── ble_security_service.dart          # HMAC, Challenge-Response, Key-Management
│   │   └── broadcast_transport.dart           # IBroadcastTransport Interface
│   └── models/
│       ├── ble_models.dart                    # BLE-spezifische Payloads + Serialisierung
│       └── ble_message_codec.dart             # Binäres Encoding/Decoding der BLE-Nachrichten
├── application/
│   └── transport_detector.dart                # Auto-Detection BLE vs SignalR
└── presentation/
    └── widgets/
        └── transport_indicator.dart           # UI-Widget: aktiver Transport + BLE-Signal
```

### MODIFY (Bestehende Dateien erweitern)

```
sheetstorm_app/lib/features/song_broadcast/
├── data/
│   ├── models/
│   │   └── broadcast_models.dart              # + MetronomeBeatPayload
│   │                                          # + AnnotationInvalidationPayload
│   │                                          # + BleSessionInfo
│   │                                          # + TransportType Enum
│   └── services/
│       └── broadcast_service.dart             # BroadcastSignalRService implementiert
│                                              # IBroadcastTransport Interface
└── application/
    └── broadcast_notifier.dart                # + TransportType im State
                                               # + Auto-Detection Logik
                                               # + BLE Connect/Disconnect
                                               # + Bridge-Modus für Hybrid

sheetstorm_app/android/app/src/main/AndroidManifest.xml
    # + BLE-Berechtigungen (BLUETOOTH_SCAN, CONNECT, ADVERTISE)

sheetstorm_app/ios/Runner/Info.plist
    # + NSBluetoothAlwaysUsageDescription
    # + NSBluetoothPeripheralUsageDescription
    # + UIBackgroundModes (bluetooth-central, bluetooth-peripheral)
```

### BACKEND (Server-seitige Erweiterungen)

```
src/Sheetstorm.Domain/
└── SongBroadcast/
    └── SongBroadcastModels.cs                 # + SessionKey, LeaderDeviceId Felder

src/Sheetstorm.Infrastructure/
└── SongBroadcast/
    └── (kein neuer Service nötig — Key-Generierung in bestehenden Broadcast-Endpoints)

src/Sheetstorm.Api/
└── Hubs/
    └── SongBroadcastHub.cs                    # + SessionKey-Distribution bei Join
```

### DEPENDENCIES (pubspec.yaml)

```yaml
dependencies:
  flutter_blue_plus: ^1.34.5       # BLE Central (Scanner + GATT Client)
  flutter_ble_peripheral: ^latest   # BLE Peripheral (GATT Server)
  crypto: ^3.0.6                    # HMAC-SHA256, SHA-256
  pointycastle: ^3.9.1              # Für erweiterte Kryptografie (optional)
```

---

## Offene Fragen

- [ ] **BLE 4.2 vs 5.x Minimum:** Sollen wir BLE 5.x voraussetzen (Extended Advertising, höhere MTU)? Oder BLE 4.2 als Minimum mit reduzierter Funktionalität (max 7 Verbindungen)?
- [ ] **Offline Key-Distribution:** Ist der QR-Code/PIN-Ansatz für Offline-Szenarien ausreichend, oder brauchen wir einen anderen Mechanismus (NFC, lokaler Hotspot)?
- [ ] **Background-Verhalten iOS:** Apple beschränkt BLE-Operationen im Hintergrund stark. Wie gehen wir damit um, wenn der Musiker die Noten in einer anderen App betrachtet?
- [ ] **Metronom als eigenständiges Feature:** Soll das Metronom auch ohne BLE-Session nutzbar sein (lokaler Modus)? Aktuell ist es an die Broadcast-Session gekoppelt.
- [ ] **flutter_ble_peripheral Reife:** Diese Bibliothek ist weniger ausgereift als flutter_blue_plus. Brauchen wir einen Fallback-Plan oder eigene Platform Channels?
- [ ] **Sequence-Number-Overflow:** Reicht uint16 (65535) für sehr lange Sessions, oder sollen wir uint32 verwenden (4 Bytes mehr pro Nachricht)?
- [ ] **Concurrent Annotation-Writes:** Wenn mehrere Musiker gleichzeitig Annotations-Invalidierungen senden — wie vermeidet der Dirigent (Peripheral) Schreibkonflikte auf der Characteristic?
