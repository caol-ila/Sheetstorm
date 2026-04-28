# 14 — Native Clients und BLE

> **Status:** Spec, mit Scaffold-Schritten. Ersetzt Konzept aus
> `08-ble-native-apps-concept.md` mit konkretem Stack.
> **Verwandt:** 05 (Conductor-Sync), 10 (Metronom-Sync).

## 14.1 Plattform-Strategie

| Plattform | Stack | Bemerkung |
|---|---|---|
| **iOS** | Capacitor 6 + WKWebView | Code-Reuse 1:1 mit Android |
| **Android** | Capacitor 6 + WebView | Standard |
| **Windows-Desktop** | Primär: PWA-Install (Edge/Chrome).<br>Optional: Tauri 2 als nativer Wrapper | PWA reicht für die meisten Fälle, Tauri für File-System / BLE-API-Zugriff |
| **macOS-Desktop** | PWA-Install (Safari ab 17) oder Tauri 2 | analog Windows |
| **Linux-Desktop** | PWA-Install | Backup, da kleine Zielgruppe |

**Begründung:**
- Web-Frontend ist Blazor SSR. Capacitor lädt unsere Web-App in einer
  Native-WebView, das geht für Mobile sauber.
- Tauri 2 nutzt die system-eigene WebView (WebView2 auf Windows, WebKit auf
  macOS), Binary ~10–30 MB. Ist parallel zu Capacitor wartbar, da das
  Plugin-System ähnlich ist.
- Capacitor-Windows existiert, ist aber noch zu unfertig für Production.

## 14.2 Repo-Layout

```
sheetstorm/
├── src/                    # Bestehendes ASP.NET-Backend + Blazor-Web
├── docs/
└── mobile/                 # NEU: Capacitor-Projekt
    ├── package.json
    ├── capacitor.config.ts
    ├── android/            # generiert
    ├── ios/                # generiert
    └── www/                # Build-Output (kopiert von Blazor-Static-Build)
desktop/                    # NEU: Tauri-Projekt (optional, Phase 2)
    ├── src-tauri/
    └── src/
```

`mobile/www` wird von einem `npm run sync`-Skript befüllt: es lädt die
Blazor-Web-App aus `https://app.sheetstorm.local` als statische Dateien (oder
zeigt direkt auf Production-URL via `capacitor.config.ts:server.url`).

## 14.3 Capacitor-Setup

### Initial-Scaffold

```bash
cd mobile
npm init -y
npm install --save-dev @capacitor/cli typescript
npm install @capacitor/core @capacitor/android @capacitor/ios
npx cap init Sheetstorm de.sheetstorm.app --web-dir=www
npm install @capacitor-community/bluetooth-le
npm install @capacitor/push-notifications @capacitor/preferences @capacitor/network
npx cap add android
npx cap add ios
```

### `capacitor.config.ts`

```ts
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'de.sheetstorm.app',
  appName: 'Sheetstorm',
  webDir: 'www',
  server: {
    // Dev: lokaler Blazor-Server. Prod: leer lassen, www-Bundle wird verwendet.
    url: process.env.SHEETSTORM_DEV_URL,
    cleartext: process.env.SHEETSTORM_DEV_URL?.startsWith('http://'),
  },
  plugins: {
    BluetoothLe: { displayStrings: { scanning: 'Suche Mitspieler …' } },
    PushNotifications: { presentationOptions: ['badge', 'sound', 'alert'] },
  },
};

export default config;
```

### Native Permissions

**Android (`AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" /> <!-- Tuner -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
```

**iOS (`Info.plist`):**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Sheetstorm braucht Bluetooth, um Click und Conductor-Sync mit anderen Musikern zu teilen.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Für den Stimm-Modus wird das Mikrofon benötigt — der Sound verlässt das Gerät nicht.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
    <string>audio</string>
</array>
```

## 14.4 BLE-Plugin

### Plugin: `@capacitor-community/bluetooth-le`

Dokumentation: https://github.com/capacitor-community/bluetooth-le

Features die wir brauchen:
- **Scan** nach Sheetstorm-Service-UUID
- **Advertise** (nur Android: Conductor wird Beacon)
- **Connect / Notify** für gerichteten Schedule-Push

### iOS-Limitation: kein Advertising aus Background

iOS-Apps können im Background **lesen**, aber **kein** Manufacturer-Specific
Advertising senden — nur die GATT-Service-UUIDs werden in eine Overflow-Area
geschrieben, ohne Custom-Payload. Daher ist auf iOS-only-Setups der
WLAN-Multicast (siehe `docs/10-metronom-and-sync-click.md`) der primäre
Sync-Weg, BLE nur als Backup.

### Service- und Characteristic-UUIDs

```
SHEETSTORM_SERVICE       = 0000F517-7E5F-7E57-0000-000000000000
CHAR_CONDUCTOR_SCHEDULE  = 0000F517-7E5F-7E57-0000-000000000001  (notify)
CHAR_CONDUCTOR_PIECE     = 0000F517-7E5F-7E57-0000-000000000002  (notify)
CHAR_TUNING_REFERENCE    = 0000F517-7E5F-7E57-0000-000000000003  (read)
```

### Pairing-Flow

1. **Conductor öffnet Event** → App generiert lokal Ed25519-Keypair und
   meldet Public-Key an Backend (`POST /api/events/{id}/conductor-key`).
2. **Mitglieder joinen Event** → App holt Public-Key beim ersten Sync ab.
3. Bei **WLAN-Multicast** und **BLE** wird jedes Schedule-Paket mit dem
   Conductor-Private-Key signiert. Follower verifiziert.
4. Manipulationen unbekannter Geräte werden ignoriert (kein UI-Pop-up,
   nur Log).

## 14.5 Bridge zwischen Blazor und Capacitor

Blazor-Web kann nicht direkt JavaScript-Plugin-APIs sehen. Wir brauchen
eine schmale Abstraktion:

```js
// mobile/www/sheetstorm-native.js — wird in App.razor zusätzlich geladen
window.SheetstormNative = {
  isCapacitor: !!(window.Capacitor && window.Capacitor.isNativePlatform()),
  async scanForConductor(serviceUuid) {
    if (!this.isCapacitor) return null; // PWA-Browser-Fallback: WebBluetooth oder UDP
    const { BleClient } = await import('@capacitor-community/bluetooth-le');
    await BleClient.initialize({ androidNeverForLocation: true });
    const result = [];
    await BleClient.requestLEScan({ services: [serviceUuid] }, (r) => result.push(r));
    return new Promise(resolve => setTimeout(async () => {
      await BleClient.stopLEScan();
      resolve(result);
    }, 4000));
  },
  // … weitere Wrapper
};
```

Aus Blazor:
```csharp
var found = await JS.InvokeAsync<object?>("SheetstormNative.scanForConductor",
    "0000F517-7E5F-7E57-0000-000000000000");
```

Wenn nicht im Capacitor-Wrapper läuft (`isCapacitor === false`), greifen
wir auf **WebBluetooth-API** (Chrome Desktop, Android Chrome) zurück, oder
auf den WLAN-Multicast-Pfad.

## 14.6 Tauri-Setup (Windows, optional)

### Initial-Scaffold

```bash
cargo install create-tauri-app
cd .. && cargo create-tauri-app desktop --template vanilla-ts
cd desktop
npm install @tauri-apps/api
```

### `tauri.conf.json`

```json
{
  "build": {
    "frontendDist": "../src/Sheetstorm.Web/wwwroot",
    "devUrl": "https://localhost:7180"
  },
  "app": {
    "windows": [{ "title": "Sheetstorm", "width": 1280, "height": 800 }],
    "security": { "csp": null }
  },
  "bundle": { "active": true, "targets": ["msi", "nsis"] }
}
```

### BLE auf Windows

Tauri 2 hat noch keinen offiziellen BLE-Plugin. Optionen:
1. Rust-Crate `btleplug` direkt in `src-tauri/` integrieren und
   per IPC-Command exposen.
2. WebBluetooth-API in WebView2 nutzen (Edge unterstützt es seit ~2022).

Empfehlung: **WebBluetooth über WebView2** — gleiche API wie Mobile-PWA-Pfad,
kein doppelter Maintainer-Aufwand.

## 14.7 Test-Setup

### Android-Emulator (lokal, Windows-Host)

Voraussetzung: Android Studio + SDK 34.

```powershell
# 1) Emulator erstellen (einmalig)
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
& "$sdk\cmdline-tools\latest\bin\sdkmanager.bat" `
    "platforms;android-34" "system-images;android-34;google_apis;x86_64" "build-tools;34.0.0"
& "$sdk\cmdline-tools\latest\bin\avdmanager.bat" create avd `
    -n sheetstorm-test -k "system-images;android-34;google_apis;x86_64"

# 2) Emulator starten
& "$sdk\emulator\emulator.exe" -avd sheetstorm-test -no-snapshot-load &

# 3) App bauen + installieren
cd mobile
npm run build
npx cap sync android
cd android
.\gradlew.bat installDebug
```

Nach `installDebug` öffnet die App und lädt die Web-App entweder aus `www/`
oder von der `SHEETSTORM_DEV_URL` (für Live-Debugging gegen Dev-Server).

### iOS-Test (optional, nur auf macOS möglich)

Auf einem Mac analog:
```bash
cd mobile && npx cap sync ios && npx cap open ios
# Xcode öffnet, Simulator iPhone 15 Pro auswählen, ⌘R
```

Auf Windows-only-Setup: iOS-Build erfolgt über GitHub-Actions
(`macos-latest`-Runner) im CI; lokales Testen ist nicht möglich.

### Windows-PWA-Test

```powershell
# 1) Web-App bauen + lokal hosten
cd src\Sheetstorm.Web
dotnet run

# 2) In Edge https://localhost:7180 oeffnen
# 3) Adressleiste: Symbol "App installieren" → installiert als PWA
# 4) PWA-Fenster oeffnet, Push-Notifications testen via Profil-Seite
```

### Windows-Tauri-Test (optional)

```powershell
cd desktop
npm install
npm run tauri dev          # Dev-Modus mit Hot-Reload aus Blazor-Server
npm run tauri build        # Erzeugt MSI in src-tauri/target/release/bundle/msi/
```

### E2E auf Native (Phase 2)

- **Android**: Appium 2.x mit UiAutomator2-Driver, Tests in `e2e/native/`
  (TypeScript, gleiches Playwright-Test-Framework über
  `@wdio/appium-service` als Bridge).
- **iOS**: Appium 2.x mit XCUITest-Driver (nur auf macOS-CI ausführbar).

## 14.8 Akzeptanzkriterien Implementation

- [ ] `mobile/`-Capacitor-Projekt scaffolded, `npx cap sync` funktioniert.
- [ ] Android-APK installiert auf Emulator und zeigt Sheetstorm-Web-App.
- [ ] BLE-Plugin erkennt Sheetstorm-Service-UUID nach Conductor-Start.
- [ ] iOS-Projekt baut auf macOS-CI (GitHub Actions).
- [ ] PWA installiert auf Windows 11 + zeigt App-Icon im Startmenü.
- [ ] Optional: Tauri-Build erzeugt MSI und startet auf Windows.
- [ ] Test-Skripte in `mobile/scripts/` und `desktop/scripts/` für lokale
      Setups dokumentiert.
