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
