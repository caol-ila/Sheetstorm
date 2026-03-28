// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/performance_mode/application/performance_mode_settings_notifier.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

Future<(ProviderContainer, PerformanceModeSettingsNotifier)> _makeNotifier({
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // Listen to keep the autoDispose provider alive
  final sub = container.listen(performanceModeSettingsProvider, (_, __) {});
  addTearDown(sub.close);
  final notifier =
      container.read(performanceModeSettingsProvider.notifier);
  // Wait for async _loadFromPrefs
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return (container, notifier);
}

PerformanceModeSettings _state(ProviderContainer c) =>
    c.read(performanceModeSettingsProvider);

void main() {
  group('PerformanceModeSettingsNotifier — defaults', () {
    test('default halfPageTurn is true', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).halfPageTurn, isTrue);
    });

    test('default colorMode is standard', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).colorMode, ColorMode.standard);
    });

    test('default brightness is 1.0', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).brightness, 1.0);
    });

    test('default annotation layers are all visible', () async {
      final (c, _) = await _makeNotifier();
      final s = _state(c);
      expect(s.annotationPrivate, isTrue);
      expect(s.annotationVoice, isTrue);
      expect(s.annotationOrchestra, isTrue);
    });

    test('default halfPageSplit is 0.5', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).halfPageSplit, 0.5);
    });
  });

  group('PerformanceModeSettingsNotifier — persistence via SharedPreferences', () {
    test('loads halfPageTurn=false from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'performance_mode_halfPageTurn': false},
      );
      expect(_state(c).halfPageTurn, isFalse);
    });

    test('loads colorMode=nacht from prefs (index 1)', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'performance_mode_colorMode': 1},
      );
      expect(_state(c).colorMode, ColorMode.night);
    });

    test('loads colorMode=sepia from prefs (index 2)', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'performance_mode_colorMode': 2},
      );
      expect(_state(c).colorMode, ColorMode.sepia);
    });

    test('loads brightness from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'performance_mode_brightness': 0.8},
      );
      expect(_state(c).brightness, closeTo(0.8, 0.001));
    });

    test('loads halfPageSplit from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'performance_mode_halfPageSplit': 0.4},
      );
      expect(_state(c).halfPageSplit, closeTo(0.4, 0.001));
    });
  });

  group('PerformanceModeSettingsNotifier — toggleHalfPageTurn', () {
    test('toggles from true to false', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleHalfPageTurn();
      expect(_state(c).halfPageTurn, isFalse);
    });

    test('toggles from false to true', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'performance_mode_halfPageTurn': false},
      );
      notifier.toggleHalfPageTurn();
      expect(_state(c).halfPageTurn, isTrue);
    });

    test('persists value to SharedPreferences', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.toggleHalfPageTurn();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('performance_mode_halfPageTurn'), isFalse);
    });
  });

  group('PerformanceModeSettingsNotifier — cycleColorMode (AC-31, AC-33)', () {
    test('standard → nacht', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.cycleColorMode();
      expect(_state(c).colorMode, ColorMode.night);
    });

    test('nacht → sepia', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'performance_mode_colorMode': 1},
      );
      notifier.cycleColorMode();
      expect(_state(c).colorMode, ColorMode.sepia);
    });

    test('sepia → standard (wraps around)', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'performance_mode_colorMode': 2},
      );
      notifier.cycleColorMode();
      expect(_state(c).colorMode, ColorMode.standard);
    });
  });

  group('PerformanceModeSettingsNotifier — setColorMode', () {
    test('sets nacht mode directly', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setColorMode(ColorMode.night);
      expect(_state(c).colorMode, ColorMode.night);
    });

    test('persists colorMode to SharedPreferences', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.setColorMode(ColorMode.sepia);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('performance_mode_colorMode'), ColorMode.sepia.index);
    });
  });

  group('PerformanceModeSettingsNotifier — setBrightness (AC-34)', () {
    test('sets valid brightness value', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setBrightness(0.8);
      expect(_state(c).brightness, closeTo(0.8, 0.001));
    });

    test('clamps below 0.6 to 0.6', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setBrightness(0.3);
      expect(_state(c).brightness, closeTo(0.6, 0.001));
    });

    test('clamps above 1.0 to 1.0', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setBrightness(1.5);
      expect(_state(c).brightness, closeTo(1.0, 0.001));
    });

    test('persists brightness', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.setBrightness(0.75);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('performance_mode_brightness'), closeTo(0.75, 0.001));
    });
  });

  group('PerformanceModeSettingsNotifier — toggleAnnotationLayer', () {
    test('toggles privat layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.private);
      expect(_state(c).annotationPrivate, isFalse);
    });

    test('toggles stimme layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.voice);
      expect(_state(c).annotationVoice, isFalse);
    });

    test('toggles orchester layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.orchestra);
      expect(_state(c).annotationOrchestra, isFalse);
    });

    test('toggles layer back on', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'performance_mode_annotPrivate': false},
      );
      notifier.toggleAnnotationLayer(AnnotationLayer.private);
      expect(_state(c).annotationPrivate, isTrue);
    });
  });

  group('PerformanceModeSettingsNotifier — isLayerVisible', () {
    test('returns true for privat when enabled', () async {
      final (_, notifier) = await _makeNotifier();
      expect(notifier.isLayerVisible(AnnotationLayer.private), isTrue);
    });

    test('returns false for privat when disabled', () async {
      final (_, notifier) = await _makeNotifier(
        prefs: {'performance_mode_annotPrivate': false},
      );
      expect(notifier.isLayerVisible(AnnotationLayer.private), isFalse);
    });
  });

  group('PerformanceModeSettingsNotifier — setHalfPageSplit (AC-17)', () {
    test('sets 0.4 split', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHalfPageSplit(0.4);
      expect(_state(c).halfPageSplit, closeTo(0.4, 0.001));
    });

    test('sets 0.6 split', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHalfPageSplit(0.6);
      expect(_state(c).halfPageSplit, closeTo(0.6, 0.001));
    });

    test('clamps below 0.4 to 0.4', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHalfPageSplit(0.2);
      expect(_state(c).halfPageSplit, closeTo(0.4, 0.001));
    });

    test('clamps above 0.6 to 0.6', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHalfPageSplit(0.8);
      expect(_state(c).halfPageSplit, closeTo(0.6, 0.001));
    });
  });
}
