# 05 — Conductor-Sync-Protokoll (Sicherheit)

## Bedrohungsmodell

Wir sind im Festzelt. Hunderte Bluetooth-Geräte, dutzende Vereine
benachbart, 5G-Empfang löchrig. Angreifer-Modell:

| Akteur | Möglichkeit | Risiko |
|---|---|---|
| Bösewicht im Publikum | BLE-Broadcasts hört + sendet | Falsche Page-Turns/Pieces stören Konzert |
| Anderes Sheetstorm-Event nebenan | Eigener legitimer Broadcast | Verwechslung |
| Replay-Angreifer | zeichnet alte Broadcasts auf | Zeitversetzte Störung |
| Insider (Mitglied wurde rausgeworfen) | hat alten Public Key | Sollte nichts mehr empfangen |

## Schutzziele

1. Nur authentifizierte Dirigenten-Broadcasts werden akzeptiert.
2. Keine Verwechslung mit anderen Events / Vereinen.
3. Replay innerhalb derselben Session unwirksam.
4. Schlüssel sind pro Event neu — Kompromittierung eines
   alten Events kompromittiert kein neues.
5. Praktisch genug: Setup ≤ 30s, kein QR-Code-Scanning pro
   Mitglied.

## Krypto-Bausteine

* **Ed25519** für Signatur (kompakt, schnell, gut in Browser
  verfügbar via WebCrypto).
* **HKDF-SHA256** für Ableitung Session-Keys aus Master-Secret
  (falls nötig).
* **Random Nonces** über `crypto.getRandomValues`.

## Protokoll

### Phase A — Session-Setup (online, vor Event)

1. Dirigent klickt im Termin-Detail „Sync-Session starten".
2. Dirigent-Client erzeugt **Ed25519-Schlüsselpaar** lokal im
   Browser.
3. Public Key + Session-Metadaten werden zum Server gepostet:
   `POST /events/{eventId}/sync-session
       { publicKey, expiresAt, ... }`.
4. Privatekey bleibt im Dirigenten-Browser (IndexedDB,
   nicht-exportierbar via WebCrypto wenn möglich, sonst
   verschlüsselt mit user-passphrase). Optional zusätzlich
   server-seitig als **Backup** verschlüsselt mit Geheimnis das
   nur Dirigent kennt — opt-in.
5. Server speichert Public Key und macht ihn allen Mitgliedern
   des Vereins, die für den Event berechtigt sind, verfügbar.
6. Mitglieder-Clients pollen `GET /events/{eventId}/sync-session`
   beim Öffnen des Events oder bei Push-Notification → cachen
   Public Key lokal.

### Phase B — Live-Broadcast (offline möglich auf Dirigentseite)

Pro Aktion (Stück geöffnet, Page-Turn) sendet Dirigent
BLE-Advertisement im **Manufacturer Specific Data**-Feld:

```
struct BroadcastPayload {
  uint16  magic        = 0x5350;          // "SP" (Sheetstorm)
  uint8   version      = 0x01;
  uint8   kind;                           // 1=PieceOpened, 2=PageTurned
  uint64  sessionId;                      // first 8 bytes of EventSyncSession.Id
  uint32  monoCounter;                    // strictly increasing per session
  uint32  payload;                        // pieceId-hash or page index
  bytes64 sig;                            // Ed25519(magic..payload)
}
```

* **Frequenz**: alle 250–500ms wiederholend für ~3s je Aktion
  (BLE ist verlustbehaftet, Wiederholung garantiert Empfang).
* **Counter**: streng monoton, Replay-Schutz (Empfänger
  speichert höchsten gesehenen Counter pro Session).
* **Größe**: ≤ 31 Bytes für klassisches BLE-Advertisement ist
  knapp. Wir nutzen **Extended Advertising** (BLE 5.0) bis
  ~250 Bytes — funktioniert in Web Bluetooth via Scanning. Für
  ältere Geräte: Truncate-Strategie und nur Hash übertragen,
  konkretes `pieceId` über Backend nachladen (offline-Fallback
  cacht Mapping).

### Phase C — Empfang

1. Mitglieder-Client scannt BLE-Advertisements (Web Bluetooth
   `requestLEScan` mit Filter auf `magic=0x5350`).
2. Für jedes Ad:
   * Prüfe Magic + Version.
   * Lookup `sessionId` → Public Key in lokalem Cache. Falls
     unbekannt → ignoriere.
   * Prüfe Signatur. Falls ungültig → ignoriere.
   * Prüfe `monoCounter > lastSeenCounter[session]`. Wenn nein →
     Replay/Duplikat, ignoriere.
   * Update `lastSeenCounter`, dispatche UI-Event.

### Phase D — Fallback (iOS / kein BLE)

* Alle Broadcast-Kinds zusätzlich an Backend: `POST
  /events/{id}/sync-events`.
* SignalR-Hub `ConductorSyncHub` pusht an alle verbundenen
  Mitglieder im Event.
* Latenz 0,5–3s je nach Netz; akzeptabel.

## Schlüssel-Lebenszyklus

* Session endet automatisch (`ExpiresAt`) oder manuell.
* Public Key bleibt in Audit für Nachvollziehbarkeit, wird aber als
  „expired" markiert und Clients verwerfen Broadcasts.
* Bei Mitgliedschaftsende: Session-Keys werden invalidiert (Force
  Re-Generation für laufende Events).

## Privacy-Erwägungen

* Broadcast enthält **keine** persönlichen Daten — nur Hashes /
  IDs. Außenstehender sieht „irgendein Bluetooth-Beacon".
* `sessionId` rotiert pro Event ⇒ kein dauerhafter Tracker.
* Empfänger-Geräte senden nichts; rein passiv.

## Time-Sync & Position-Tracking

> **Verwandt:** [17 — Playback & Sync](17-playback-and-sync.md),
> [10 — Metronom](10-metronom-and-sync-click.md),
> [12 — Visualisierung & Datei-Strategie](12-visualization-and-file-strategy.md).

Aufbauend auf Phase A–D wird der Broadcast erweitert, sodass nicht nur
*welches Stück* sondern auch *welche Position im Stück* übertragen wird.
Ziel: Alle Mitglieder­geräte zeigen synchron Takt + Beat, sowohl im
Score-Modus (OSMD-SVG) als auch im Bild-Modus (PDF-Render).

### Designprinzip: Anker + lokale Extrapolation

Wir senden **nicht** jeden Beat einzeln (das wäre zu viel BLE-Traffic
und durch Verluste wackelig). Stattdessen:

* Conductor sendet alle **0,5–2 s** einen **Position-Anchor**
  (Takt-Nr, Beat-Index-im-Takt, BPM, Taktart, Wall-Clock-Timestamp).
* Follower extrapolieren lokal mit der bekannten BPM bis zum nächsten
  Anker (Lookahead-Scheduler analog `metronome.js`).
* Bei jedem empfangenen Anker wird die lokale Uhr weich nachgezogen
  (Drift-Korrektur ≤ 50 ms/s, kein Sprung).
* Tempo-Änderungen, Sprünge und Fermaten erzeugen einen **Out-of-Band-
  Anker mit Sonderflag** und werden zusätzlich mehrfach wiederholt
  (BLE-Verlust-Toleranz).

### Paket-Erweiterung: `kind = 3 (PositionAnchor)`

```
struct PositionAnchorPayload {
  uint16  magic        = 0x5350;
  uint8   version      = 0x02;          // bumped
  uint8   kind         = 0x03;          // PositionAnchor
  uint64  sessionId;
  uint32  monoCounter;
  uint32  pieceIdHash;                  // welches Stück (matcht kind=1)
  uint16  measureNumber;                // 1-basiert, MusicXML <measure number>
  uint8   beatIndex;                    // 0-basiert im Takt
  uint8   beatSubdivision;              // 0..push: Sechzehntel-Phase, 0..3
  uint16  bpmTimes100;                  // BPM × 100, Fixpoint
  uint8   timeSigNumerator;             // z.B. 4
  uint8   timeSigDenominator;           // 2/4/8/16
  uint8   flags;                        // siehe unten
  uint8   jumpKind;                     // siehe Sprungtabelle
  uint16  jumpTargetMeasure;            // 0 = kein Sprung
  uint64  conductorWallClockMs;         // Sender-Uhr in ms
  bytes64 sig;                          // Ed25519
}
```

**Flags (Bitmaske):**

| Bit | Bedeutung |
|---|---|
| 0  | `IsPlaying` (0 = pausiert / Probe-Stop) |
| 1  | `IsFermata` — Beat hängt auf Anker, kein Auto-Advance |
| 2  | `IsRitardando` — BPM gilt nur als Momentanwert, Follower glättet |
| 3  | `IsAccelerando` — analog |
| 4  | `IsRepeatStart` — ab hier markiert für Loop-Übungs-Modus |
| 5  | `IsRepeatEnd` |
| 6  | `IsCountIn` — Vorzähler vor Stückbeginn (negative Takte erlaubt) |
| 7  | reserviert |

**Sprung-Tabelle (`jumpKind`):**

| Wert | Bedeutung | `jumpTargetMeasure` |
|---|---|---|
| 0 | kein Sprung | 0 |
| 1 | Volta 1 → Volta 2 (am Wiederholungs­ende) | erste Volta-2-Maßnahme |
| 2 | D.C. al Fine / D.C. al Coda | 1 |
| 3 | D.S. al Fine / D.S. al Coda | Segno-Maßnahme |
| 4 | To Coda | Coda-Maßnahme |
| 5 | Generischer Sprung („Probe ab Takt N") | Ziel-Maßnahme |
| 6 | Loop-Wrap (Übungs-Modus) | Loop-Start |

Sprünge werden als **eigener Anker-Typ** gesendet, **drei mal** binnen
~150 ms wiederholt, plus ein direkt folgender regulärer Anker an der
neuen Position. Followers, die die Sprung­meldung verpassen, korrigieren
sich beim nächsten Position-Anchor.

### Score-Modus (OSMD)

* OSMD liefert pro `<measure number>` und Beat eine Cursor-Position
  (XPath/Index in der Score-SVG-Struktur).
* Ein dünner blauer **Beat-Cursor** (vertikale Linie über aktuellem
  Note-Head) wird per CSS-Transform positioniert und mit
  `requestAnimationFrame` zwischen Ankern interpoliert.
* Sprünge führen einen *Snap* aus (kein Wischen über mehrere Systeme),
  optional mit kurzem Highlight-Pulsen am Ziel.

### Bild-Modus (PDF-Render-PNGs)

Wir kennen die Pixel-Positionen pro Note **nicht zuverlässig** —
die OMR ist auf Stimmen-Trennung und MusicXML-Export optimiert,
nicht auf pixelgenaue Bounding-Boxen pro Beat. Daher Stufen-Lösung:

| Stufe | Voraussetzung | Anzeige |
|---|---|---|
| **A — System-Highlight** | nur Seite + System aus OMR bekannt | Aktuelles Notensystem (Akkolade) wird leicht hervorgehoben (Rahmen 4 px, 30 % Opazität). |
| **B — Takt-Highlight** | Takt-Bounding-Box aus OMR vorhanden (Audiveris liefert pro `<measure>` ein `<bounds>`) | Aktueller Takt wird als gelbliches Overlay markiert. |
| **C — Beat-Marker** | zusätzlich Beat-X-Positionen aus OMR | Vertikale Linie analog Score-Modus. |

Audiveris liefert in der Praxis Stufe **B** zuverlässig; Stufe C nur
bei sauberen Vorlagen. Default-Anzeige: das jeweils höchst­mögliche
Niveau, mit Fallback auf System-Highlight wenn Daten fehlen.

Die OMR-Pipeline (siehe [15-omr-pipeline-spec.md](15-omr-pipeline-spec.md))
muss daher pro Stimme zusätzlich speichern:

```jsonc
// Part.LayoutHints (neu)
{
  "pages": [{
    "pageIndex": 0,
    "pixelWidth": 2480,
    "pixelHeight": 3508,
    "systems": [{
      "yTopNorm": 0.12, "yBottomNorm": 0.22,
      "measures": [
        { "number": 1, "xLeftNorm": 0.08, "xRightNorm": 0.31,
          "beats": [0.10, 0.16, 0.22, 0.28] },
        ...
      ]
    }]
  }]
}
```

Koordinaten in 0..1 normiert (analog Annotationen, Spec 12), damit
Zoom/Resize stabil ist.

### Sprungmarken in OMR & MusicXML

* Audiveris erkennt Wiederholungs­zeichen, Volta-Klammern, Coda/Segno-
  Symbole. Diese landen in MusicXML als `<barline>`, `<ending>`,
  `<sound>` (mit `dacapo`, `dalsegno`, `tocoda`, …).
* Beim Import wird daraus eine **lineare Performance-Liste** erzeugt
  (`Piece.PerformanceTimeline`): Liste von Takt-Spannen in der
  Reihenfolge, wie sie tatsächlich gespielt werden, inkl. Volta-Wahl.
* Conductor-UI erlaubt die Performance-Liste vor dem Start
  zu editieren („alle Wiederholungen weglassen", „D.C. ohne
  Repeat"). Diese Liste ist die Quelle der Wahrheit für `jumpKind`.

### Latenz-Budget (siehe auch 17)

* BLE-Advertisement bis Empfang: **80–250 ms** typisch, p99 ≤ 500 ms.
* Anker-Frequenz 0,5–2 s ⇒ maximaler Drift zwischen zwei Ankern bei
  120 BPM ca. 0,5–1 Beat, der durch lokale BPM-Extrapolation gedeckt
  wird.
* Wall-Clock-Synchronisation aus `conductorWallClockMs` minus lokal
  gemessener Empfangs­zeit, geglättet via exponential moving average
  (α = 0,2). Ergebnis-Sync nach Einschwingen: **≤ 100 ms** zwischen
  Geräten desselben Events.
* SignalR-Fallback (iOS Phase 1): **300–800 ms**, gleiches Anker-
  Schema, gleiche Extrapolation.

### Privacy

Position-Anker enthalten keine Personen­daten, nur `pieceIdHash` und
Takt-Nummer. Außenstehende sehen weiterhin nur Beacons.

## Offene Punkte / Phase-2

* iBeacon-Style Eddystone-Encoding zusätzlich für ältere Android
  Stacks evaluieren.
* MAUI/Native-Companion-App für iOS, exposed als Local-Server
  Bridge zur PWA (loopback-Socket).
* Adaptive Anker-Frequenz: bei stabilem Tempo 2 s, bei Rubato 250 ms.
* OMR-Pass-2 für Beat-X-Koordinaten (Stufe C im Bild-Modus) als
  optionaler Hintergrund-Job.
