# Sheetstorm App

Flutter-Frontend für Sheetstorm Notenmanagement.

## Stack

- **Flutter SDK:** 3.5+
- **State Management:** Riverpod 2.x
- **Routing:** GoRouter 14.x
- **Lokale DB:** Drift (SQLite)
- **HTTP:** package:http
- **i18n:** ARB-basiert (de, en)

## Setup

### 1. Flutter SDK installieren

Falls noch nicht geschehen: https://docs.flutter.dev/get-started/install

### 2. Dependencies installieren

```bash
cd sheetstorm_app
flutter pub get
```

### 3. Localization generieren

```bash
flutter gen-l10n
```

(Oder automatisch via `flutter run` — `pubspec.yaml` hat `generate: true`)

### 4. Plattformen scaffolden

Erste Installation (generiert Plattform-Code):

```bash
flutter create --platforms=android,ios,windows,web --org de.sheetstorm .
```

## Development

### Run App (Web)

```bash
flutter run -d chrome --web-port 8080
```

Backend-URL per Environment-Variable:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=https://localhost:7001
```

### Run Tests

```bash
flutter test
```

### Analyze

```bash
flutter analyze
```

### Build (Release)

**Android APK:**

```bash
flutter build apk --release
```

**Android App Bundle:**

```bash
flutter build appbundle --release
```

**iOS (requires macOS + Xcode):**

```bash
flutter build ios --release
```

**Windows Desktop:**

```bash
flutter build windows --release
```

**Web:**

```bash
flutter build web --release
```

## i18n-Workflow

Alle User-sichtbaren Strings MÜSSEN über ARB-Dateien externalisiert werden.

### Neue Übersetzung hinzufügen

1. **ARB-Datei editieren:** `lib/l10n/app_de.arb` (Deutsch, default) oder `app_en.arb` (Englisch)

```json
{
  "welcomeMessage": "Willkommen bei Sheetstorm",
  "@welcomeMessage": {
    "description": "Begrüßungstext auf dem Home-Screen"
  }
}
```

2. **Code generieren:**

```bash
flutter gen-l10n
```

(Oder automatisch beim nächsten `flutter run`)

3. **Im Code nutzen:**

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.welcomeMessage)
```

### Platzhalter/Parameter

ARB unterstützt Platzhalter:

```json
{
  "greetUser": "Hallo, {name}!",
  "@greetUser": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  }
}
```

Im Code:

```dart
Text(AppLocalizations.of(context)!.greetUser('Thomas'))
```

## Architektur

```
lib/
├── core/          # Routing, Theme, Config
├── features/      # Feature-Module (Home, Noten, ...)
├── shared/        # Geteilte Widgets, Services
└── l10n/          # ARB-Dateien (Übersetzungen)
```

## Backend-Integration

API-Client: `lib/shared/services/api_client.dart`

- Default: `https://localhost:7001`
- Override via `--dart-define=API_BASE_URL=...`

## Testing

- Widget-Tests: `test/`
- Mocking: `mocktail`
- Provider-Overrides für DI in Tests

## Material 3

UI nutzt Material 3 (`useMaterial3: true`).

Theme: `lib/core/theme/app_theme.dart`

## E2E-Tests (Playwright)

E2E-Tests für User-Workflows sind im `e2e/`-Verzeichnis.

**Setup:**

```bash
npm install
npx playwright install
```

**Ausführen:**

```bash
npm run test:e2e          # Headless
npm run test:e2e:ui       # Interaktiv mit UI
npm run test:e2e:headed   # Mit Browser-Fenster
```

**Voraussetzung:** Backend + Flutter Web müssen laufen (siehe Root-README).

## Weitere Infos

- **DevLoop-Guide:** `../docs/operations/devloop.md`
- **Root-README:** `../README.md`
- **Pubspec-Dependencies:** Siehe `pubspec.yaml`
