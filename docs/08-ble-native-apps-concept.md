# 08 — BLE + Native Apps: Konzept und Architektur

## Ausgangslage

Sheetstorm-PWA läuft heute auf allen modernen Browsern. **Web Bluetooth**
ist aber nur in Chrome/Edge auf Desktop+Android verfügbar — und es
kann nur **scannen**, nicht **broadcasten** (zumindest nicht ohne
Custom-Hardware). iOS Safari hat **gar kein** Web Bluetooth.

Phase-1-Sync (`iter-4-conductor-sync`) läuft daher über **Server-Polling
alle 1,5s**. Das funktioniert immer, braucht aber Datenverbindung.

Phase-1.5 (`iter-4b-ble-crypto`) hat den **Krypto-Layer** schon im
Browser: Ed25519-Schlüsselpaar + Sign+Verify funktionieren überall, wo
WebCrypto verfügbar ist. Die Public-Key-Verteilung läuft über den
Server — d.h. die Keys müssen vor dem Konzert online verteilt sein.

Was fehlt für **echtes Festzelt-Offline-Sync**: ein
**Broadcast-Mechanismus** der ohne Server zwischen Geräten kommuniziert.

## Optionen im Vergleich

| Option | Plattformen | Offline | Aufwand | Bemerkung |
|---|---|---|---|---|
| **A. PWA mit Web Bluetooth Scan** | Chrome/Edge Desktop + Android | ✅ ja | klein | Mitglied scannt — aber wer broadcastet? |
| **B. Native Companion-Apps (BT-Brücke)** | iOS, Android, Windows, macOS | ✅ ja | groß | Native App nur für BT-Layer, PWA für Rest |
| **C. WiFi-Direct / mDNS LAN-Sync** | Plattformabhängig | ✅ ja, aber Setup nötig | mittel | Funktioniert wenn alle im selben WLAN/Hotspot sind |
| **D. Konzert-Hotspot mit Lokalem Server** | universal | ✅ ja | mittel | Dirigent macht Hotspot auf, Mitglieder verbinden sich |
| **E. Externes BT-Gateway (Hardware)** | universal | ✅ ja | groß + Hardware | ESP32 als Brücke; teuer |

### Empfehlung: **B + D als Kombination**

* **B** für ernsthaftes Festzelt-Szenario auf Mobiltelefonen
* **D** als pragmatischer Fallback für Vereine, die kein Companion installieren wollen

## Konzept B: Native Companion-Apps

### Architektur

```
┌─────────────────────────────────────────────────────────────┐
│              Sheetstorm-PWA (Browser)                       │
│   - alle UI / Logik / Werke / Termine                       │
│   - Conductor-Sync-Page                                     │
└──────────────────┬──────────────────────────────────────────┘
                   │ JS-Bridge (Custom URL Scheme + WebSocket)
                   │ z.B. sheetstorm-bt://broadcast?...
                   ▼
┌─────────────────────────────────────────────────────────────┐
│           Sheetstorm-BT-Companion (Native App)              │
│   - Minimal-UI: nur "Aktiv/Inaktiv" + Logs                  │
│   - Hört lokalen WebSocket :47823 auf Loopback              │
│   - Vermittelt Befehle zwischen PWA und Bluetooth-Stack     │
└──────────────────┬──────────────────────────────────────────┘
                   │ Plattform-BT-API
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  Plattform-Bluetooth (Core Bluetooth iOS / Android BLE /   │
│  Windows BluetoothLE / IOBluetooth macOS)                   │
└─────────────────────────────────────────────────────────────┘
```

### Protokoll PWA ↔ Companion

WebSocket auf `ws://localhost:47823` (Companion startet beim System,
hört auf Loopback). Token-basiert (Token wird beim Pairing einmalig
ausgetauscht).

```
PWA → Companion:
{ "cmd": "broadcast", "payloadB64": "...", "signatureB64": "..." }

Companion → PWA:
{ "evt": "received", "payloadB64": "...", "signatureB64": "...",
  "rssi": -65, "ts": 1234567890 }

Companion → PWA:
{ "evt": "status", "active": true, "scanning": true, "advertising": true }
```

### Native-App-Stack je Plattform

| Plattform | Empfohlener Stack | BT-API | Größe | Distribution |
|---|---|---|---|---|
| **iOS** | Swift + SwiftUI | Core Bluetooth (kann broadcasten + scannen) | <10 MB | App Store |
| **Android** | Kotlin + Jetpack Compose | Android BluetoothLeAdvertiser + Scanner | <5 MB | Play Store + APK |
| **Windows** | .NET MAUI oder WinUI 3 | Windows.Devices.Bluetooth | <30 MB | Microsoft Store + MSIX |
| **macOS** | Swift + SwiftUI | Core Bluetooth | <10 MB | App Store + DMG |

Alternativ: **eine Codebase mit .NET MAUI** für alle vier Plattformen.
Einsparung: ein Team, eine Code-Sprache. Nachteil: macOS-MAUI ist
weniger ausgereift, iOS-BT-Integration mit MAUI hat Edge-Cases.

### Pairing-Flow (Erst-Setup)

1. User installiert Companion-App.
2. PWA-Seite zeigt QR-Code mit `{ token, websocketPort }`.
3. Companion-App scannt QR-Code → kennt nun den Token.
4. WebSocket-Verbindung mit Token-Header authentifiziert.
5. PWA + Companion sind permanent gekoppelt.

### BLE-Protokoll auf der Funk-Schicht

Wir nutzen **BLE Manufacturer-Specific-Data** in Advertisements (kein
GATT-Connect, weil zu viele Geräte = zu langsam).

```
Adv-Frame (max 31 Bytes Legacy, bis 255 mit Extended Adv):

  Header (1)  Length (1)   Type=0xFF   ManufacturerID (2)   Data...
                                       0xFFFF (Sheetstorm)  Payload + Sig
```

Payload-Schema siehe `docs/05-conductor-sync-protocol.md`:
* Magic (2 Bytes)
* Version (1)
* Kind (1) — PieceOpened / Heartbeat / Stop
* SessionId (8)
* MonoCounter (4)
* PieceIdHash (4)
* Signature (Ed25519, 64 Bytes)

Insgesamt ~85 Bytes → Extended Advertising nötig (BLE 5.0+).
Für ältere Geräte: nur Hash übertragen, PieceId-Mapping vorab cached.

### Energie / Reichweite

* Advertising-Intervall 250–500ms während aktiver Aktion, sonst 2s
  Heartbeat
* Reichweite 10–30m (Smartphone-BT-Stärken variieren)
* Battery: <2% pro Stunde Konzert (bei 500ms-Intervall)

## Konzept D: Konzert-Hotspot mit lokalem Server

Für Vereine, die keine Companion installieren wollen:

1. Dirigenten-Gerät startet ein **Sheetstorm-Lite-Server** (ein
   einzelnes Binary, ~30 MB) das den Conductor-Sync-Endpoint
   bereitstellt.
2. Dirigent öffnet WLAN-Hotspot („Sheetstorm-XYZ", Passwort wird im
   Hotspot-Setup-Schritt angezeigt).
3. Mitglieder verbinden sich mit dem Hotspot.
4. PWA erkennt den lokalen Server via mDNS und switcht von
   Cloud-Polling auf LAN-Polling.

Vorteil: keine native App nötig, funktioniert zwischen iOS und Android.
Nachteil: Hotspot-Betrieb verbraucht Akku, Mitglieder müssen WLAN
wechseln.

## Roadmap-Vorschlag

### Stufe 1 (1 Woche)
- **Companion-Skeleton** für **Android** (Kotlin) — die offenste
  Plattform, am schnellsten Prototyp-fähig
- Pairing-Flow + WebSocket-Bridge
- BLE-Broadcast eines Test-Frames

### Stufe 2 (2 Wochen)
- iOS-Companion (Swift)
- Crypto-Verifikation auf Empfänger-Seite
- E2E-Test mit zwei realen Geräten

### Stufe 3 (1 Woche)
- Windows-Companion (.NET / WinUI)
- macOS-Companion (Swift)
- Gemeinsame Distribution / Version-Tracking

### Stufe 4 (2 Wochen)
- Konzert-Hotspot-Modus als Fallback
- Auto-Detection: PWA versucht Companion, dann Hotspot, dann
  Cloud-Polling
- UI: User sieht klar welcher Pfad aktiv ist

## Risiken

* **iOS-App-Store-Review**: Apple kann Apps ablehnen die "nur" als
  Bluetooth-Brücke zu einer Web-Seite agieren. Lösung: minimaler
  Eigenwert (z.B. Verein-Übersicht, Notenliste read-only)
* **Android-Background-Restrictions**: BLE-Scan im Hintergrund ist
  ab Android 8 stark limitiert. Lösung: Foreground-Service mit
  persistenter Notification während Konzert-Modus
* **Web-Bluetooth-Standard ändert sich**: aktuell wird `requestLEScan`
  in einigen Chrome-Versionen behind-flag — wir können nicht darauf
  zählen. Companion-Architektur ist daher robuster als reine
  Web-Bluetooth-Lösung
* **MAUI vs. Native**: MAUI spart Code, aber Bluetooth-Stacks haben
  je Plattform Edge-Cases die in MAUI schlechter abgefangen werden

## Was Sheetstorm heute schon vorbereitet

* `wwwroot/js/conductor-sync.js`: WebCrypto-Layer für Ed25519, kompatibel
  mit dem zukünftigen BLE-Payload-Format
* `EventSyncSession.PublicKey`: Server speichert Public Key, sodass
  Mitglieder ihn beim Online-Sync laden und für Offline-Verifikation
  cachen können
* `EventSyncSession.CurrentCounter`: monoton steigend, Replay-Schutz
* PWA als Service-Worker installierbar — Companion kann dann eine
  Eingebettete-Webview verwenden statt Browser

## Entscheidungs-Hilfe für später

| Wenn dein Verein… | dann nimm… |
|---|---|
| nur Android-Geräte hat | Android-Companion + Web-Bluetooth-Scan auf Mitglieder |
| iOS + Android gemischt | Beide Companions ODER Konzert-Hotspot |
| meist DLAN/WLAN im Saal | Cloud-Polling oder Hotspot-Fallback |
| reines Festzelt ohne Netz | Companions + lokales Sync zwingend |

Sheetstorm bleibt **Companion-optional**: Cloud-Polling funktioniert
immer, Companions verbessern den Festzelt-Fall.
