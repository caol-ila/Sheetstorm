// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/spielmodus/application/spielmodus_settings_notifier.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';

Future<(ProviderContainer, SpielmodusSettingsNotifier)> _makeNotifier({
  Map<String, Object>? prefs,
}) async {
  SharedPreferences.setMockInitialValues(prefs ?? {});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // Listen to keep the autoDispose provider alive
  final sub = container.listen(spielmodusSettingsProvider, (_, __) {});
  addTearDown(sub.close);
  final notifier =
      container.read(spielmodusSettingsProvider.notifier);
  // Wait for async _loadFromPrefs
  await Future<void>.delayed(const Duration(milliseconds: 50));
  return (container, notifier);
}

SpielmodusEinstellungen _state(ProviderContainer c) =>
    c.read(spielmodusSettingsProvider);

void main() {
  group('SpielmodusSettingsNotifier — defaults', () {
    test('default halfPageTurn is true', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).halfPageTurn, isTrue);
    });

    test('default farbmodus is standard', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).farbmodus, Farbmodus.standard);
    });

    test('default helligkeit is 1.0', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).helligkeit, 1.0);
    });

    test('default annotation layers are all visible', () async {
      final (c, _) = await _makeNotifier();
      final s = _state(c);
      expect(s.annotationPrivat, isTrue);
      expect(s.annotationStimme, isTrue);
      expect(s.annotationOrchester, isTrue);
    });

    test('default halfPageSplit is 0.5', () async {
      final (c, _) = await _makeNotifier();
      expect(_state(c).halfPageSplit, 0.5);
    });
  });

  group('SpielmodusSettingsNotifier — persistence via SharedPreferences', () {
    test('loads halfPageTurn=false from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'spielmodus_halfPageTurn': false},
      );
      expect(_state(c).halfPageTurn, isFalse);
    });

    test('loads farbmodus=nacht from prefs (index 1)', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'spielmodus_farbmodus': 1},
      );
      expect(_state(c).farbmodus, Farbmodus.nacht);
    });

    test('loads farbmodus=sepia from prefs (index 2)', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'spielmodus_farbmodus': 2},
      );
      expect(_state(c).farbmodus, Farbmodus.sepia);
    });

    test('loads helligkeit from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'spielmodus_helligkeit': 0.8},
      );
      expect(_state(c).helligkeit, closeTo(0.8, 0.001));
    });

    test('loads halfPageSplit from prefs', () async {
      final (c, _) = await _makeNotifier(
        prefs: {'spielmodus_halfPageSplit': 0.4},
      );
      expect(_state(c).halfPageSplit, closeTo(0.4, 0.001));
    });
  });

  group('SpielmodusSettingsNotifier — toggleHalfPageTurn', () {
    test('toggles from true to false', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleHalfPageTurn();
      expect(_state(c).halfPageTurn, isFalse);
    });

    test('toggles from false to true', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'spielmodus_halfPageTurn': false},
      );
      notifier.toggleHalfPageTurn();
      expect(_state(c).halfPageTurn, isTrue);
    });

    test('persists value to SharedPreferences', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.toggleHalfPageTurn();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('spielmodus_halfPageTurn'), isFalse);
    });
  });

  group('SpielmodusSettingsNotifier — cycleFarbmodus (AC-31, AC-33)', () {
    test('standard → nacht', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.cycleFarbmodus();
      expect(_state(c).farbmodus, Farbmodus.nacht);
    });

    test('nacht → sepia', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'spielmodus_farbmodus': 1},
      );
      notifier.cycleFarbmodus();
      expect(_state(c).farbmodus, Farbmodus.sepia);
    });

    test('sepia → standard (wraps around)', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'spielmodus_farbmodus': 2},
      );
      notifier.cycleFarbmodus();
      expect(_state(c).farbmodus, Farbmodus.standard);
    });
  });

  group('SpielmodusSettingsNotifier — setFarbmodus', () {
    test('sets nacht mode directly', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setFarbmodus(Farbmodus.nacht);
      expect(_state(c).farbmodus, Farbmodus.nacht);
    });

    test('persists farbmodus to SharedPreferences', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.setFarbmodus(Farbmodus.sepia);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('spielmodus_farbmodus'), Farbmodus.sepia.index);
    });
  });

  group('SpielmodusSettingsNotifier — setHelligkeit (AC-34)', () {
    test('sets valid brightness value', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHelligkeit(0.8);
      expect(_state(c).helligkeit, closeTo(0.8, 0.001));
    });

    test('clamps below 0.6 to 0.6', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHelligkeit(0.3);
      expect(_state(c).helligkeit, closeTo(0.6, 0.001));
    });

    test('clamps above 1.0 to 1.0', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.setHelligkeit(1.5);
      expect(_state(c).helligkeit, closeTo(1.0, 0.001));
    });

    test('persists helligkeit', () async {
      final (_, notifier) = await _makeNotifier();
      notifier.setHelligkeit(0.75);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('spielmodus_helligkeit'), closeTo(0.75, 0.001));
    });
  });

  group('SpielmodusSettingsNotifier — toggleAnnotationLayer', () {
    test('toggles privat layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.privat);
      expect(_state(c).annotationPrivat, isFalse);
    });

    test('toggles stimme layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.stimme);
      expect(_state(c).annotationStimme, isFalse);
    });

    test('toggles orchester layer off', () async {
      final (c, notifier) = await _makeNotifier();
      notifier.toggleAnnotationLayer(AnnotationLayer.orchester);
      expect(_state(c).annotationOrchester, isFalse);
    });

    test('toggles layer back on', () async {
      final (c, notifier) = await _makeNotifier(
        prefs: {'spielmodus_annotPrivat': false},
      );
      notifier.toggleAnnotationLayer(AnnotationLayer.privat);
      expect(_state(c).annotationPrivat, isTrue);
    });
  });

  group('SpielmodusSettingsNotifier — isLayerVisible', () {
    test('returns true for privat when enabled', () async {
      final (_, notifier) = await _makeNotifier();
      expect(notifier.isLayerVisible(AnnotationLayer.privat), isTrue);
    });

    test('returns false for privat when disabled', () async {
      final (_, notifier) = await _makeNotifier(
        prefs: {'spielmodus_annotPrivat': false},
      );
      expect(notifier.isLayerVisible(AnnotationLayer.privat), isFalse);
    });
  });

  group('SpielmodusSettingsNotifier — setHalfPageSplit (AC-17)', () {
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
