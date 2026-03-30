# Decision: BLE-Broadcast Sicherheitskonzept

**Autor:** Strange (Principal Backend Engineer)
**Datum:** 2026-03-30
**Kontext:** BLE-Broadcast-Spezifikation (`docs/specs/2026-03-30-ble-broadcast-dirigent.md`)
**Status:** Draft — Zur Prüfung durch Thomas

---

## Kernentscheidungen

### 1. Pre-Shared Session Key via REST API

**Entscheidung:** Jede Broadcast-Session erhält einen kryptographischen 256-Bit-Key, der über die authentifizierte REST-API (JWT) an alle Teilnehmer verteilt wird.

**Begründung:** Nur Kapellenmitglieder mit gültigem JWT können den Key abrufen. Der Key wird an die Session-ID gebunden — neue Session = neuer Key. Maximale Gültigkeit: 4 Stunden.

**Alternative verworfen:** Key im BLE-Advertising verteilen — zu unsicher, da Advertising öffentlich ist.

### 2. HMAC-SHA256 Nachrichtensignaturen

**Entscheidung:** Jede BLE-Nachricht wird mit HMAC-SHA256(sessionKey, payload) signiert. 32 Bytes Signatur pro Nachricht.

**Begründung:** HMAC-SHA256 ist kryptographisch stark, schnell in Software, und passt in BLE-MTU (247 Bytes). Constant-Time-Vergleich gegen Timing-Angriffe.

**Alternative verworfen:** AES-GCM Encryption — höherer Overhead, unnötig da BLE-Daten nicht vertraulich sind (Stücktitel, BPM sind keine Geheimnisse), nur Authentizität zählt.

### 3. Trust-Modell nach Event-Typ

**Entscheidung:** Differenziertes Vertrauen je nach Message Type:
- **Dirigenten-exklusiv** (höchste Stufe): Song-Wechsel, Metronom, Session-Kontrolle
- **Alle authentifizierten Mitglieder** (Standard): Annotations-Invalidierung

**Begründung:** Stückwechsel und Tempo sind Dirigenten-Hoheit. Annotationen können von jedem Musiker geändert werden (eigene Notizen). Die Differenzierung verhindert, dass ein kompromittiertes Musiker-Gerät die Session steuern kann.

### 4. Challenge-Response Authentifizierung

**Entscheidung:** Beim BLE-Verbindungsaufbau beweisen beide Seiten (Musiker + Dirigent) den Besitz des Session Keys durch Challenge-Response mit Random Nonce.

**Begründung:** Beidseitige Verifikation: Musiker weiß, dass der Dirigent echt ist (und nicht ein Angreifer-Peripheral). Dirigent weiß, dass der Musiker den Key hat. Kein Key wird über BLE übertragen.

### 5. Replay-Protection

**Entscheidung:** Sequenznummern (uint16, monoton steigend) + Timestamps (max 5 Sekunden Drift) in jeder signierten Nachricht.

**Begründung:** Verhindert, dass aufgezeichnete BLE-Pakete erneut abgespielt werden (z.B. alter Stückwechsel). 5-Sekunden-Toleranz ist ein Kompromiss zwischen Clock-Drift verschiedener Geräte und Sicherheit.

### 6. Offline Key-Distribution

**Entscheidung:** Wenn kein Server erreichbar ist, generiert der Dirigent den Key lokal und verteilt ihn per QR-Code oder 6-stelligem PIN.

**Begründung:** Offline-Proben müssen funktionieren ohne Server. QR-Code ist schnell (ein Scan pro Musiker), PIN ist Fallback. Der Challenge-Response über BLE bestätigt anschließend den Besitz.

### 7. BLE als primärer Transport, SignalR als Fallback

**Entscheidung:** Auto-Detection beim Session-Start: BLE wird bevorzugt (3-Sekunden-Scan), SignalR nur wenn BLE nicht verfügbar. Der Dirigent agiert als Bridge im Hybrid-Modus.

**Begründung:** BLE bietet < 20ms Latenz (vs. 50–200ms SignalR), funktioniert offline, und spart Server-Kosten. SignalR bleibt für Remote-Teilnehmer und als Fallback.

---

## Auswirkungen

### Backend
- `SongBroadcastModels.cs`: Neue Felder `SessionKey`, `LeaderDeviceId`, `ExpiresAt`
- Key-Generierung mit `RandomNumberGenerator.GetBytes(32)` bei Session-Start
- REST-Endpoint liefert Key an authentifizierte Teilnehmer

### Flutter
- 7 neue Dateien (BLE Service, Security Service, Transport Interface, Models, Codec, Detector, UI-Widget)
- 4 modifizierte Dateien (broadcast_models, broadcast_service, broadcast_notifier, Plattform-Configs)
- Neue Dependencies: `flutter_blue_plus`, `flutter_ble_peripheral`, `crypto`

### Plattform
- Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` Berechtigungen
- iOS: `NSBluetoothAlwaysUsageDescription`, Background Modes

---

## Offene Fragen für Thomas

1. **BLE 4.2 vs 5.x als Minimum?** — BLE 4.2 = max 7 Verbindungen, BLE 5.x = max 20
2. **Offline-Key-Verteilung:** QR-Code/PIN ausreichend oder weiterer Mechanismus nötig?
3. **flutter_ble_peripheral Reife:** Fallback-Plan via Platform Channels erforderlich?
