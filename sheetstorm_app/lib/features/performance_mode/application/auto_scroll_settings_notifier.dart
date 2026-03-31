import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';

part 'auto_scroll_settings_notifier.g.dart';

/// Persisted auto-scroll default settings (Feature-Spec §5.2, UX §4).
class AutoScrollSettingsState {
  const AutoScrollSettingsState({
    this.defaultMode = AutoScrollMode.manual,
    this.defaultSpeedFactor = 1.0,
    this.defaultBpm = 120,
    this.defaultBarsPerLine = 4,
    this.defaultLeadInBars = 2,
    this.defaultStartDelaySeconds = 3.0,
    this.pauseOnTouch = true,
  });

  final AutoScrollMode defaultMode;
  final double defaultSpeedFactor;
  final int defaultBpm;
  final int defaultBarsPerLine;
  final int defaultLeadInBars;
  final double defaultStartDelaySeconds;
  final bool pauseOnTouch;

  AutoScrollSettingsState copyWith({
    AutoScrollMode? defaultMode,
    double? defaultSpeedFactor,
    int? defaultBpm,
    int? defaultBarsPerLine,
    int? defaultLeadInBars,
    double? defaultStartDelaySeconds,
    bool? pauseOnTouch,
  }) {
    return AutoScrollSettingsState(
      defaultMode: defaultMode ?? this.defaultMode,
      defaultSpeedFactor: defaultSpeedFactor ?? this.defaultSpeedFactor,
      defaultBpm: defaultBpm ?? this.defaultBpm,
      defaultBarsPerLine: defaultBarsPerLine ?? this.defaultBarsPerLine,
      defaultLeadInBars: defaultLeadInBars ?? this.defaultLeadInBars,
      defaultStartDelaySeconds:
          defaultStartDelaySeconds ?? this.defaultStartDelaySeconds,
      pauseOnTouch: pauseOnTouch ?? this.pauseOnTouch,
    );
  }
}

/// Notifier for persistent auto-scroll settings via SharedPreferences.
@riverpod
class AutoScrollSettings extends _$AutoScrollSettings {
  static const _prefix = 'auto_scroll_';

  @override
  AutoScrollSettingsState build() {
    Future<void>.microtask(_loadFromPrefs);
    return const AutoScrollSettingsState();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = AutoScrollSettingsState(
      defaultMode: AutoScrollMode.values[
          prefs.getInt('${_prefix}defaultMode') ?? 0],
      defaultSpeedFactor:
          prefs.getDouble('${_prefix}defaultSpeedFactor') ?? 1.0,
      defaultBpm: prefs.getInt('${_prefix}defaultBpm') ?? 120,
      defaultBarsPerLine:
          prefs.getInt('${_prefix}defaultBarsPerLine') ?? 4,
      defaultLeadInBars:
          prefs.getInt('${_prefix}defaultLeadInBars') ?? 2,
      defaultStartDelaySeconds:
          prefs.getDouble('${_prefix}defaultStartDelaySeconds') ?? 3.0,
      pauseOnTouch: prefs.getBool('${_prefix}pauseOnTouch') ?? true,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setInt('${_prefix}defaultMode', state.defaultMode.index),
      prefs.setDouble('${_prefix}defaultSpeedFactor', state.defaultSpeedFactor),
      prefs.setInt('${_prefix}defaultBpm', state.defaultBpm),
      prefs.setInt('${_prefix}defaultBarsPerLine', state.defaultBarsPerLine),
      prefs.setInt('${_prefix}defaultLeadInBars', state.defaultLeadInBars),
      prefs.setDouble(
          '${_prefix}defaultStartDelaySeconds', state.defaultStartDelaySeconds),
      prefs.setBool('${_prefix}pauseOnTouch', state.pauseOnTouch),
    ]);
  }

  void setDefaultMode(AutoScrollMode mode) {
    state = state.copyWith(defaultMode: mode);
    _saveToPrefs();
  }

  void setDefaultSpeedFactor(double factor) {
    state = state.copyWith(defaultSpeedFactor: factor.clamp(0.5, 3.0));
    _saveToPrefs();
  }

  void setDefaultBpm(int bpm) {
    state = state.copyWith(defaultBpm: bpm.clamp(20, 300));
    _saveToPrefs();
  }

  void setDefaultBarsPerLine(int bars) {
    state = state.copyWith(defaultBarsPerLine: bars.clamp(1, 8));
    _saveToPrefs();
  }

  void setDefaultLeadInBars(int bars) {
    state = state.copyWith(defaultLeadInBars: bars.clamp(0, 4));
    _saveToPrefs();
  }

  void setDefaultStartDelaySeconds(double seconds) {
    state = state.copyWith(
        defaultStartDelaySeconds: seconds.clamp(0.0, 10.0));
    _saveToPrefs();
  }

  void togglePauseOnTouch() {
    state = state.copyWith(pauseOnTouch: !state.pauseOnTouch);
    _saveToPrefs();
  }
}
