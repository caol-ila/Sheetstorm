# Platform Scaffolding TODOs

This directory structure is scaffolded manually due to missing Flutter SDK during setup.

## Required Actions

When Flutter SDK is available, run:

```bash
flutter create --platforms=android,ios,windows,web --org de.sheetstorm .
```

This will generate:
- `android/` - Android platform configuration
- `ios/` - iOS platform configuration  
- `windows/` - Windows platform configuration
- `web/` - Web platform configuration

## Current Status

✅ Core Dart code structure (`lib/`, `test/`) manually created
✅ Dependencies defined in `pubspec.yaml`
✅ Localization configured (`l10n.yaml`, `.arb` files)
❌ Platform-specific build files (Android Gradle, iOS Xcode, Windows CMake, Web index.html) NOT generated

## Build Commands (once Flutter is available)

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```
