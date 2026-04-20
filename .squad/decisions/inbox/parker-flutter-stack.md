# Decision: Flutter Stack Setup

**Date:** 2025-01-19  
**Author:** Parker (Squad Frontend)  
**Context:** Issue #126 — Phase 4 Flutter App Scaffold  
**Status:** Proposed (pending team review)

## Summary

Manually scaffolded Flutter app structure due to missing Flutter SDK on dev machine. All core Dart code, dependencies, and test structure created. Platform-specific files (Android, iOS, Windows, Web) require `flutter create` once SDK is available.

## Decisions

### 1. Riverpod Version: 2.5.1 (not 3.x)

**Rationale:**  
- Riverpod 3.x is still in pre-release/beta as of Jan 2025
- Chose stable 2.5.1 for production reliability
- Riverpod 2.x is well-documented, mature, fully feature-complete for our needs
- Migration path to 3.x is straightforward when stable

**Alternative Considered:**  
Riverpod 3.x — rejected due to stability concerns for a new project

### 2. i18n Approach: ARB-based Code Generation

**Rationale:**  
- Flutter's official `flutter_localizations` + ARB files
- Type-safe: `AppLocalizations.of(context).appTitle` vs hardcoded strings
- `generate: true` in pubspec.yaml → auto-generates on `flutter run` / `flutter gen-l10n`
- Default locale: `de` (German), fallback: `en` (English)
- Prevents hardcoded strings (copilot-instructions.md compliance)

**Alternative Considered:**  
Hardcoded strings with manual `Localizations.override` — rejected, violates internationalization policy

### 3. Platform Scope: android, ios, windows, web

**Rationale:**  
- Per copilot-instructions.md: Multi-platform support
- Android + iOS: Mobile deployment
- Windows: Desktop (dev environment is Windows)
- Web: Quickest iteration, E2E testing with Playwright
- **Current Status:** Platform folders scaffolded with TODOs — actual files need `flutter create --platforms=...`

**Deferred:**  
Linux, macOS — can be added later if needed

### 4. Manual Scaffold (No Flutter SDK)

**Rationale:**  
- Flutter SDK not installed on current machine (`flutter` command not found)
- Task requirement: "Falls Flutter-SDK nicht installiert: dokumentiere das, aber erstelle die Struktur MANUELL"
- Created all Dart source files, pubspec.yaml, l10n.yaml, test structure manually
- Platform-specific build files (Gradle, Xcode, CMake, index.html) require Flutter tooling
- Documented in `SETUP_NOTES.md` for next developer

**Verification:**  
Cannot run `flutter analyze` or `flutter test` without SDK. Tests are syntactically correct and follow Riverpod testing patterns (mocktail, overrideWithValue).

## Impact

- ✅ Dart code structure complete, follows copilot-instructions.md conventions
- ✅ Dependencies defined: Riverpod, GoRouter, Drift, http, mocktail
- ✅ i18n configured (ARB files, l10n.yaml)
- ✅ Tests written (home_screen_test.dart, semantics_test.dart)
- ❌ Cannot execute `flutter pub get`, `flutter analyze`, `flutter test` without SDK
- ❌ Platform-specific files not generated (android/, ios/, windows/, web/ are placeholders)

## Next Steps

1. **Install Flutter SDK** on CI or dev machine
2. Run `flutter create --platforms=android,ios,windows,web --org de.sheetstorm .` in `sheetstorm_app/`
3. Run `flutter pub get && flutter gen-l10n`
4. Verify `flutter analyze` (zero warnings)
5. Verify `flutter test` (all tests green)

## Files Changed

- `sheetstorm_app/pubspec.yaml`
- `sheetstorm_app/l10n.yaml`
- `sheetstorm_app/lib/main.dart`
- `sheetstorm_app/lib/core/theme/app_theme.dart`
- `sheetstorm_app/lib/core/routing/app_router.dart`
- `sheetstorm_app/lib/core/config/api_config.dart`
- `sheetstorm_app/lib/features/home/home_screen.dart`
- `sheetstorm_app/lib/features/home/home_providers.dart`
- `sheetstorm_app/lib/shared/services/api_client.dart`
- `sheetstorm_app/lib/l10n/app_de.arb`
- `sheetstorm_app/lib/l10n/app_en.arb`
- `sheetstorm_app/test/home_screen_test.dart`
- `sheetstorm_app/test/semantics_test.dart`
- `sheetstorm_app/SETUP_NOTES.md`
- `sheetstorm_app/README.md`

## Compliance

- ✅ Copilot-instructions.md: Riverpod for state, GoRouter for routing, ARB for i18n
- ✅ File-Structure-Mapping: See below
- ✅ TDD: Tests written (cannot verify RED → GREEN without Flutter SDK)
- ✅ Escalation-Grade: `DONE_WITH_CONCERNS` (see below)

## File-Structure-Map

**CREATE:**
- `sheetstorm_app/pubspec.yaml` — Zweck: Dependencies (Riverpod, GoRouter, Drift, http, mocktail) — Abhängigkeiten: None
- `sheetstorm_app/l10n.yaml` — Zweck: i18n config (ARB dir, output class) — Abhängigkeiten: pubspec.yaml (generate: true)
- `sheetstorm_app/lib/main.dart` — Zweck: App entry point, ProviderScope + MaterialApp.router — Abhängigkeiten: app_router.dart, app_theme.dart
- `sheetstorm_app/lib/core/theme/app_theme.dart` — Zweck: Material 3 light/dark themes — Abhängigkeiten: None
- `sheetstorm_app/lib/core/routing/app_router.dart` — Zweck: GoRouter config, route '/' → HomeScreen — Abhängigkeiten: home_screen.dart
- `sheetstorm_app/lib/core/config/api_config.dart` — Zweck: API base URL (from --dart-define or default) — Abhängigkeiten: None
- `sheetstorm_app/lib/features/home/home_screen.dart` — Zweck: HomeScreen widget, responsive (NavigationRail/NavigationBar), calls ping — Abhängigkeiten: home_providers.dart, AppLocalizations (generated)
- `sheetstorm_app/lib/features/home/home_providers.dart` — Zweck: pingProvider (FutureProvider) — Abhängigkeiten: api_client.dart
- `sheetstorm_app/lib/shared/services/api_client.dart` — Zweck: HTTP client, ping() method — Abhängigkeiten: package:http, api_config.dart
- `sheetstorm_app/lib/l10n/app_de.arb` — Zweck: German strings (appTitle, helloBand, homeNavLabel) — Abhängigkeiten: None
- `sheetstorm_app/lib/l10n/app_en.arb` — Zweck: English strings — Abhängigkeiten: None
- `sheetstorm_app/test/home_screen_test.dart` — Zweck: Widget test for HomeScreen with MockApiClient — Abhängigkeiten: home_screen.dart, api_client.dart, mocktail
- `sheetstorm_app/test/semantics_test.dart` — Zweck: Accessibility test (ensureSemantics) — Abhängigkeiten: home_screen.dart
- `sheetstorm_app/SETUP_NOTES.md` — Zweck: Manual scaffold docs, flutter create instructions — Abhängigkeiten: None
- `sheetstorm_app/README.md` — Zweck: Developer onboarding, run instructions — Abhängigkeiten: None
- `sheetstorm_app/{android,ios,windows,web}/README.md` — Zweck: Placeholder TODOs for platform files — Abhängigkeiten: Flutter SDK (flutter create)

**MODIFY:** None (all new files)

**DELETE:** None
