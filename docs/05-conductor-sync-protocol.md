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

## Offene Punkte / Phase-2

* iBeacon-Style Eddystone-Encoding zusätzlich für ältere Android
  Stacks evaluieren.
* MAUI/Native-Companion-App für iOS, exposed als Local-Server
  Bridge zur PWA (loopback-Socket).
