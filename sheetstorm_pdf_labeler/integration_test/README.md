# Integration Tests

## Overview

This directory contains E2E-style integration tests for the PDF Labeler Flutter app. These tests exercise full user workflows from the UI layer through business logic.

## Files

- `smoke_test.dart` — Basic UI smoke tests (app launches, inputs work, buttons behave correctly)
- `app_test.dart` — Full E2E tests with mocked `LabelingService` to validate:
  - Progress UI updates as labeling events arrive
  - Confidence badges (HIGH/MEDIUM/LOW) display correctly
  - Error handling UI
  - Settings persistence via `FlutterSecureStorage`

## Running Tests

```powershell
# Standard test run (requires Windows Developer Mode enabled for symlink support)
flutter test integration_test/

# If Developer Mode is not enabled, tests will fail with:
# "Building with plugins requires symlink support"
```

## Local Execution Limitations

**Known Issue:** These tests cannot run locally on Windows without Developer Mode enabled, because Flutter treats `integration_test/` specially and attempts to build for the desktop platform, which requires symlink support for plugin registration.

**Workaround:** These tests are designed to run in CI environments where Developer Mode or equivalent symlink support is available.

## Test Architecture

### Mocking Strategy

The tests use provider overrides to inject a `FakeLabelingService` that emits scripted events:

```dart
ProviderScope(
  overrides: [
    labelingProvider.overrideWith(
      (ref) => LabelingNotifier.withService(mockService),
    ),
  ],
  child: const PdfLabelerApp(),
)
```

This approach:
- Avoids spawning the actual CLI process in tests
- Allows deterministic testing of UI responses to various event sequences
- Keeps tests fast and hermetic

### Coverage

- ✅ App launch and main UI elements
- ✅ Token field input and persistence checkbox
- ✅ Folder picker buttons (UI presence)
- ✅ Start button enabled/disabled logic
- ✅ Progress bar and status text during labeling
- ✅ Confidence badge rendering (check_circle, warning, error icons)
- ✅ Error event handling

## CI Integration

These tests are expected to run in CI with:

```bash
flutter test integration_test/ --coverage
```

CI environments should have Developer Mode equivalent enabled or use a Linux/macOS runner where symlinks are natively supported.
