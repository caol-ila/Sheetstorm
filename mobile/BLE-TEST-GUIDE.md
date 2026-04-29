# BLE-Test-Setup für Sheetstorm

Hier ist die Schritt-für-Schritt-Anleitung, wie du **mit deinen Geräten**
(Android-Phone, Windows-Laptop, Windows-Tablet) den BLE-Sync testen kannst.

## Was geht mit deinem Setup

| Gerät | Rolle | Status |
|---|---|---|
| **Android-Phone** | Conductor (sendet) | ✅ — braucht das mitgelieferte Native-Plugin (siehe unten) |
| **Android-Phone** | Follower (empfängt) | ✅ — Chrome auf Android hat WebBluetooth |
| **Windows-Laptop / -Tablet** | Follower | ✅ — Edge / Chrome haben WebBluetooth (Bluetooth muss am Laptop an sein) |
| **Windows-Laptop / -Tablet** | Conductor | ❌ — WebBluetooth kann kein Advertising. Ginge nur über native UWP-App (kein Aufwand wert) |

**Empfehlung für ersten Test:** Android = Conductor, Windows = Follower.

---

## Voraussetzungen am PC

* Node.js ≥ 20 ([nodejs.org](https://nodejs.org))
* Android Studio (mit Android-SDK 34) — gibt's gratis bei Google
* USB-Debugging am Phone aktiv:
  - Phone: **Einstellungen → Über das Telefon → Build-Nummer 7× tippen**
  - Dann **Einstellungen → Entwickleroptionen → USB-Debugging an**
* Phone per USB an den Laptop angesteckt; Phone fragt „USB-Debugging zulassen?" → Ja.

## Schritt 1 — Sheetstorm-Mobile-App bauen

```powershell
cd mobile
npm install                    # einmalig
npx cap add android            # einmalig — erzeugt mobile/android/

# Native Plugin einkopieren — das ist der Conductor-BLE-Code:
$src = "native\android\SheetstormBleAdvertiserPlugin.kt"
$dst = "android\app\src\main\java\de\sheetstorm\app\SheetstormBleAdvertiserPlugin.kt"
New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
Copy-Item $src $dst -Force

# In MainActivity.java vor super.onCreate(savedInstanceState):
#   registerPlugin(SheetstormBleAdvertiserPlugin.class);
# (wird unten als sed-Skript automatisiert)
.\scripts\patch-mainactivity.ps1
```

`patch-mainactivity.ps1` ist im Repo (`mobile/scripts/`).

## Schritt 2 — Android-Manifest-Permissions

In `mobile/android/app/src/main/AndroidManifest.xml` müssen unter `<manifest>`
diese Permissions stehen (das Setup-Skript trägt sie ein):

```xml
<uses-permission android:name="android.permission.BLUETOOTH_ADVERTISE" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
```

Außerdem in `mobile/android/app/build.gradle`: `minSdkVersion 26`.

## Schritt 3 — Server-URL

Setze die Sheetstorm-Server-URL, die das Phone aufrufen soll. Drei Optionen:

### Option A — Phone und PC im selben WLAN

```powershell
# Lokale IP des PCs herausfinden:
ipconfig | findstr IPv4

# In mobile/capacitor.config.ts:
# server.url = "https://192.168.1.x:7180"  (deine IP)
```

Beachte: `https://localhost:7180` mit Self-Signed-Cert akzeptiert das Phone ohne
weitere Schritte nicht. Workaround: einen `cleartext`-`http://`-Build verwenden,
oder unten Option B nutzen.

### Option B — Cloudflare-Tunnel (öffentliche HTTPS-URL)

```powershell
# einmalig:
winget install Cloudflare.cloudflared

# in einem separaten Terminal:
cloudflared tunnel --url https://localhost:7180

# dann in mobile/capacitor.config.ts:
# server.url = "https://abc-123.trycloudflare.com"
```

### Option C — Statisches Build

```powershell
cd mobile
$env:SHEETSTORM_PROD_URL = "https://your-deployed-instance.example.com"
npm run build:www
# Lädt dann von der konfigurierten Production-URL.
```

## Schritt 4 — APK bauen und installieren

```powershell
cd mobile
npx cap sync android
cd android
.\gradlew.bat installDebug

# App startet automatisch auf dem Phone.
```

Wenn alles geht: Sheetstorm-Login-Bildschirm auf dem Phone.

## Schritt 5 — Conductor starten (Phone)

1. Phone: Sheetstorm-App ist offen, einloggen mit `dirigent@demo.local` / `demo`
2. Demo-Verein → Termine → Termin (z.B. `Sommer-Probe`) öffnen
3. **„Conductor-Sync"** öffnen
4. Im **„BLE-Sync (Pilot)"-Panel** → Knopf **„BLE starten"** drücken
5. Android fragt nach Bluetooth-Berechtigung → erlauben
6. Status sollte auf **„BLE-Advertising aktiv"** wechseln
7. Public-Key wird unten angezeigt

Auf einem zweiten Gerät (Bluetooth-Sniffer wie nRF Connect) sollte das Phone
jetzt als Sheetstorm-Service mit UUID `0000F517-7E5F-7E57-...` sichtbar sein.

## Schritt 6 — Follower starten (Windows-Laptop / -Tablet)

1. Edge oder Chrome öffnen
2. `https://your-sheetstorm.example.com/ble-test` ansteuern (oder lokal
   `https://localhost:7180/ble-test` wenn der Web-Server am Laptop läuft)
3. Klick auf **„Conductor in der Nähe finden & verbinden"**
4. Der Browser öffnet einen System-Picker mit allen sichtbaren BLE-Geräten
5. **„Sheetstorm"** auswählen → **Pair**
6. Status oben wechselt auf **„verbunden"**

## Schritt 7 — Test der Notification-Übertragung

1. Phone → BLE-Sync-Panel → **„Demo-Tick senden"** drücken
2. Windows-Browser → Liste **„Empfangene Pakete"** zeigt das Paket mit Hex-Dump
   und Timestamp

Erwartung: Latenz zwischen Phone-Klick und Windows-Anzeige ist **30–80 ms**.
Mehrere Phones gleichzeitig im Empfang → BLE schafft typisch 5–10 Subscriber
ohne sichtbare Verzögerung.

---

## Was geht (mit dieser Iteration) und was nicht

✅ Android-Phone advertised Sheetstorm-Service
✅ Multiple Browser-Followers können verbinden
✅ Notify-Pakete kommen an + werden im UI gezeigt
✅ Public-Key wird beim Backend hinterlegt + abrufbar
✅ Web-Bridge funktioniert auf Windows-Edge / Chrome / Android-Chrome

⏳ **Signaturprüfung** ist im JS implementiert (`SheetstormNative.verifySchedule`)
   aber im Tester noch nicht eingehakt. Folge-Iteration.
⏳ **Click-Sync mit Schedule-Lookahead** ist noch nicht eingebaut — der Demo-Tick
   ist nur eine Test-Payload.
❌ **iOS Conductor** — braucht eine vergleichbare Swift-Plugin-Datei
   (`mobile/native/ios/`). Ist in der Spec, kommt mit echter iOS-Hardware.

---

## Troubleshooting

* **„BLE-Advertising not supported":** Phone unterstützt kein Peripheral-Mode.
  Trifft auf manche älteren Android-Phones < 5.0 zu. Modernes Phone nehmen.
* **„Picker zeigt kein Sheetstorm":** Phone-Bluetooth aus, oder Phone ist nicht
  im Modus „BLE starten". Phone neu auf das Sync-Panel schicken.
* **Browser-Picker findet nichts:** Bluetooth am Laptop überprüfen, anderes
  Gerät zeigt es im nRF-Connect-App?
* **HTTPS-Cert-Probleme:** Cloudflare-Tunnel (Option B) ist der einfachste Weg.

