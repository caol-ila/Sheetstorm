# 10 — Metronom & Sync-Click

> **Status:** Spec, noch nicht implementiert.
> **Verwandt:** 05 (Conductor-Sync-Protocol), 08 (BLE), 11 (Tuning).

## 10.1 Ziel

Jeder Musiker hat einen **Metronom** im Pult. Der Dirigent kann einen
**Sync-Click** starten, der auf allen verbundenen Geräten **gleichzeitig**
hörbar ist — Drift-Toleranz **≤ 50 ms** zwischen je zwei Geräten.

Use Cases:
- **Probe:** Dirigent gibt Tempo vor, alle Musiker hören denselben Click im
  In-Ear / kleinen Lautsprecher → keine Verwirrung wenn jemand "schiebt".
- **Sektionsprobe:** Sektion startet Click ohne Dirigent.
- **Solo-Üben:** Musiker nutzt das Metronom mit Tempo aus dem aktuellen Stück.

## 10.2 Tempo & Taktart

### Quelle des Tempos

1. **Aus dem Stück** (Default, sobald ein Werk geöffnet ist):
   - `Piece.Tempo` (BPM, optional)
   - `Piece.TimeSignature` (z. B. `4/4`, `3/4`, `6/8`)
   - Bei MusicXML-Import: `<sound tempo="…">` und `<time>` werden gelesen.
2. **Manuell**: BPM-Slider (40–240) und Taktart-Dropdown (`2/4`, `3/4`, `4/4`,
   `3/8`, `6/8`, `9/8`, `12/8`, custom).
3. **Tap-Tempo**: Button "Tap" — letzte 4 Taps werden gemittelt.

### Tempo-Schnellwahl

Drei Buttons immer sichtbar:

| Button | Wirkung |
|---|---|
| **100 %** | Stück-Tempo (oder eingestelltes Tempo) |
| **−10 %** | 0,9 × Stück-Tempo |
| **−20 %** | 0,8 × Stück-Tempo |

Buttons sind toggle-artig — aktive Auswahl ist primär hervorgehoben. Manuelle
BPM-Änderung deaktiviert die Schnellwahl (zeigt "Custom").

### Akzentuierung

- **Erster Schlag** im Takt höher / lauter (z. B. 1000 Hz).
- **Andere Schläge**: 800 Hz.
- **Subdivision** (optional): Achtel/Sechzehntel mit reduzierter Lautstärke.

## 10.3 Sync-Architektur

### Anforderung

- Drift zwischen je zwei verbundenen Geräten ≤ **50 ms**.
- Jitter unter Last (Bluetooth-LE-Background-Scans, WLAN-Roaming) toleriert
  über **Lookahead-Scheduling**: alle Geräte berechnen Click-Zeitpunkte aus
  einer **gemeinsamen Zeitbasis** und planen Audio-Buffer 200 ms im Voraus.

### Empfohlener Stack: **WLAN-Multicast + NTP-Light**

Begründung: BLE-Advertising hat bei mehr als ~10 Subscribern Aussetzer,
Verbindungs-Aufbau dauert pro Gerät 100–300 ms. WLAN-Multicast/UDP ist auf
allen Plattformen (auch PWA über Companion-App) verlässlicher.

#### Komponenten

```
┌──────────────┐       NTP-Sync (UDP/WS)        ┌──────────────┐
│  Dirigent    │ ←──────────────────────────→  │  Musiker N   │
│  (Conductor) │                                │  (Follower)  │
└──────┬───────┘                                └──────────────┘
       │
       │  Multicast 239.42.13.1:51213 (Click-Tick)
       ↓
   ┌───────────────────────┐
   │  Lokales WLAN         │  alle Follower hören mit
   └───────────────────────┘
```

1. **Time-Base-Sync** beim Verbinden:
   - Companion-NTP-light: 5 Round-Trips zwischen Conductor und Server,
     Server-Zeit = anchored common base. Offset wird je Follower berechnet.
   - Genauigkeit auf lokalem WLAN: **5–15 ms**.
2. **Click-Schedule-Broadcast** (UDP-Multicast, alternativ unicast):
   - Conductor sendet 1× pro Sekunde ein **Schedule-Paket**:
     ```
     {
       "patternId": "uuid",       // Identität der aktuellen Click-Session
       "anchorMs": 1714300000123, // gemeinsame Zeitbasis
       "bpm": 120,
       "timeSig": "4/4",
       "subdivision": "quarter",
       "startMs": 1714300000500   // erster Schlag in Anchor-Zeit
     }
     ```
   - Follower berechnet aus `startMs + n*60000/bpm` jeden weiteren Schlag und
     plant `WebAudio.AudioContext.scheduleAt(...)`.
3. **Drift-Korrektur**: Follower vergleicht alle 5 s seinen lokalen Tick mit
   dem Schedule-Paket; bei > 20 ms Abweichung → Resync der Time-Base.

### Fallback-Stack: BLE-Advertising

Wenn kein WLAN verfügbar (Open-Air, kein Hotspot):
- Conductor sendet als Beacon (Manufacturer-Specific-Data).
- Payload: `bpm | startMs (4 Byte, mod 2^32) | subdivision`.
- Follower-Apps (native Wrapper) hören passiv mit.
- Drift-Risiko: 30–80 ms je nach OS-Scan-Window — akzeptabel für Probe ohne
  WLAN, **nicht** für Konzert-Click.

### Sicherheit

- **Authenticated-Broadcast**: Pakete werden mit dem Event-Schlüssel signiert
  (HMAC-SHA256 über Payload + anchorMs).
- **Replay-Protection**: Follower akzeptiert nur Pakete mit `anchorMs` ≥
  letzter empfangenes − 2 s.
- **Pairing**: Follower joinen ein Event vorab (Code-Scan oder QR), holen
  sich dabei den Event-Public-Key aus der API. Ohne gültige Signatur → Ignore.

## 10.4 Audio-Latenz-Profil

Der Lookahead muss die schlechteste erwartete Audio-Latenz übersteigen:

| Plattform | Audio-Latenz | Lookahead |
|---|---|---|
| iOS Safari | 30–60 ms | 200 ms |
| Android Chrome | 40–80 ms | 200 ms |
| Desktop Browser | 10–25 ms | 200 ms |
| Native Wrapper (Capacitor) | 8–20 ms | 200 ms |

Pro Gerät wird die Latenz beim Verbinden gemessen (Loopback-Estimate über
`AudioContext.outputLatency` + `baseLatency`) und vom geplanten `startMs`
abgezogen.

## 10.5 UI

### Metronom-Panel (überall sichtbar via Bottom-Sheet)

```
┌──────────────────────────────────────────────────┐
│  ●  120 BPM    4/4   ⏯              ✕            │
│                                                   │
│  [ 100% ] [ −10% ] [ −20% ]   Tap                 │
│                                                   │
│  Subdivision: [Off | 8tel | 16tel]                │
│  Lautstärke:  [────●──────]                       │
│  Akzent 1: ●                                      │
└──────────────────────────────────────────────────┘
```

### Conductor-Sync-Modus

Zusätzlich:
- **"Click an Musiker senden"** (Toggle, sichtbar nur für Dirigenten-Rolle).
- Status-Liste der verbundenen Follower mit gemessener Drift in ms.

### Anzeige bei Followern

Mini-Badge oben rechts: `🥁 120 BPM` (kein Toggle — wenn der Dirigent den
Click schickt, hört der Follower mit, kann aber lokal stummschalten).

## 10.6 Datenmodell

```csharp
public class MetronomeSession
{
    public Guid Id { get; set; }
    public Guid EventId { get; set; }       // optional, für Sync im Event
    public Guid OwnerUserId { get; set; }   // wer hat den Click gestartet
    public int Bpm { get; set; }
    public string TimeSignature { get; set; } // "4/4"
    public string Subdivision { get; set; }   // "off"|"8th"|"16th"
    public DateTimeOffset StartedAt { get; set; }
    public DateTimeOffset? StoppedAt { get; set; }
}
```

`MetronomeSession` ist nur für Audit / "wer hat heute auf 92 BPM geprobt?".
Die Echtzeit-Übertragung läuft **nicht** über die DB sondern über
WebSocket/UDP-Multicast.

## 10.7 Akzeptanzkriterien

- [ ] Zwei Follower auf demselben WLAN haben eine Drift ≤ 50 ms (Messung mit
      gleichzeitiger Audio-Aufnahme zweier Geräte).
- [ ] BPM-Slider, Taktart-Dropdown und Tap-Tempo funktionieren ohne ausgewähltes Stück.
- [ ] Bei geöffnetem Stück werden Tempo + Taktart vorgeschlagen (Auto-Übernahme abschaltbar).
- [ ] 100/−10/−20 %-Buttons schalten korrekt um.
- [ ] Subdivision ein/aus ändert die Audio-Pattern in < 100 ms.
- [ ] Pakete ohne gültige HMAC-Signatur werden vom Follower ignoriert.
- [ ] Beim Stoppen des Click verstummen alle Follower binnen 500 ms.
