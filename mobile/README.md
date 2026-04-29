# Sheetstorm Mobile (Capacitor)

Wrapper, der die Sheetstorm-PWA in einer nativen App auf iOS und Android startet.
Identische Codebasis wie Web — nur die App-Shell + native Plugins (BLE, Push,
Preferences) sind hier.

## Voraussetzungen

- Node.js ≥ 20
- Android Studio mit SDK 34 (für Android-Builds)
- macOS + Xcode (nur für iOS-Builds)
- Java 21 (für Android-Builds)

## Erstes Setup

```bash
cd mobile
npm install

# Plattformen erst beim ersten Build initialisieren
npx cap add android
npx cap add ios     # nur auf macOS
```

## Dev-Modus (gegen lokalen Blazor-Server)

```bash
# Stelle sicher dass dotnet run --project src/Sheetstorm.Web läuft auf
# https://localhost:7180. Tunnele es per ngrok / cloudflared zu einer
# öffentlichen URL, dann:

set SHEETSTORM_DEV_URL=https://abcd.trycloudflare.com
npm run sync
npx cap run android
```

## Prod-Build

```bash
set SHEETSTORM_PROD_URL=https://sheetstorm.example.com
npm run sync
npx cap open android   # öffnet Android Studio → Build → APK/AAB
npx cap open ios       # öffnet Xcode → Archive
```

## BLE-Plugin

Das `@capacitor-community/bluetooth-le`-Plugin ist als Dependency drin. In der
Web-App (Blazor) wird es über `window.SheetstormNative` benutzt — siehe
`docs/14-native-clients-and-ble.md`.

## Test-Setup

### Android-Emulator

Skripte unter `scripts/`:

```powershell
# einmalig: AVD erzeugen
.\scripts\android-create-avd.ps1

# Emulator starten + App installieren
.\scripts\android-run.ps1
```
