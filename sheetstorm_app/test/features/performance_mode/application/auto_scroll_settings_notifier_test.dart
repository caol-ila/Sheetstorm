import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_settings_notifier.dart';

AutoScrollSettingsState _state(ProviderContainer c) =>
    c.read(autoScrollSettingsProvider);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AutoScrollSettingsNotifier — defaults', () {
    test('initial state has spec-defined defaults', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      final state = _state(container);
      expect(state.defaultMode, AutoScrollMode.manual);
      expect(state.defaultSpeedFactor, 1.0);
      expect(state.defaultBpm, 120);
      expect(state.defaultBarsPerLine, 4);
      expect(state.defaultLeadInBars, 2);
      expect(state.defaultStartDelaySeconds, 3.0);
      expect(state.pauseOnTouch, true);
    });
  });

  group('AutoScrollSettingsNotifier — persistence', () {
    test('setDefaultSpeedFactor persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      // Wait for initial async load from build()
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      notifier.setDefaultSpeedFactor(2.0);

      expect(_state(container).defaultSpeedFactor, 2.0);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('auto_scroll_defaultSpeedFactor'), 2.0);
    });

    test('setDefaultBpm persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      notifier.setDefaultBpm(140);

      expect(_state(container).defaultBpm, 140);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('auto_scroll_defaultBpm'), 140);
    });

    test('setDefaultMode persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      notifier.setDefaultMode(AutoScrollMode.bpm);

      expect(_state(container).defaultMode, AutoScrollMode.bpm);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('auto_scroll_defaultMode'), AutoScrollMode.bpm.index);
    });

    test('togglePauseOnTouch persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      expect(_state(container).pauseOnTouch, true);
      notifier.togglePauseOnTouch();
      expect(_state(container).pauseOnTouch, false);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('auto_scroll_pauseOnTouch'), false);
    });

    test('loads saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'auto_scroll_defaultSpeedFactor': 1.5,
        'auto_scroll_defaultBpm': 140,
        'auto_scroll_defaultMode': 1, // bpm
        'auto_scroll_defaultBarsPerLine': 6,
        'auto_scroll_defaultLeadInBars': 0,
        'auto_scroll_defaultStartDelaySeconds': 5.0,
        'auto_scroll_pauseOnTouch': false,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      // Wait for async load
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final state = _state(container);
      expect(state.defaultSpeedFactor, 1.5);
      expect(state.defaultBpm, 140);
      expect(state.defaultMode, AutoScrollMode.bpm);
      expect(state.defaultBarsPerLine, 6);
      expect(state.defaultLeadInBars, 0);
      expect(state.defaultStartDelaySeconds, 5.0);
      expect(state.pauseOnTouch, false);
    });

    test('setDefaultBarsPerLine clamps 1-8', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      notifier.setDefaultBarsPerLine(0);
      expect(_state(container).defaultBarsPerLine, 1);
      notifier.setDefaultBarsPerLine(10);
      expect(_state(container).defaultBarsPerLine, 8);
    });

    test('setDefaultLeadInBars clamps 0-4', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sub = container.listen(autoScrollSettingsProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(autoScrollSettingsProvider.notifier);
      notifier.setDefaultLeadInBars(-1);
      expect(_state(container).defaultLeadInBars, 0);
      notifier.setDefaultLeadInBars(10);
      expect(_state(container).defaultLeadInBars, 4);
    });
  });
}
