import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

part 'performance_mode_settings_notifier.g.dart';

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
@riverpod
class PerformanceModeSettingsNotifier extends _$PerformanceModeSettingsNotifier {
  @override
  PerformanceModeSettings build() {
    Future<void>.microtask(_loadFromPrefs);
    return const PerformanceModeSettings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = PerformanceModeSettings(
      halfPageTurn: prefs.getBool('performance_mode_halfPageTurn') ?? true,
      colorMode: ColorMode.values[prefs.getInt('performance_mode_colorMode') ?? 0],
      brightness: prefs.getDouble('performance_mode_brightness') ?? 1.0,
      annotationPrivate: prefs.getBool('performance_mode_annotPrivate') ?? true,
      annotationVoice: prefs.getBool('performance_mode_annotVoice') ?? true,
      annotationOrchestra: prefs.getBool('performance_mode_annotOrchestra') ?? true,
      halfPageSplit: prefs.getDouble('performance_mode_halfPageSplit') ?? 0.5,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('performance_mode_halfPageTurn', state.halfPageTurn),
      prefs.setInt('performance_mode_colorMode', state.colorMode.index),
      prefs.setDouble('performance_mode_brightness', state.brightness),
      prefs.setBool('performance_mode_annotPrivate', state.annotationPrivate),
      prefs.setBool('performance_mode_annotVoice', state.annotationVoice),
      prefs.setBool('performance_mode_annotOrchestra', state.annotationOrchestra),
      prefs.setDouble('performance_mode_halfPageSplit', state.halfPageSplit),
    ]);
  }

  void toggleHalfPageTurn() {
    state = state.copyWith(halfPageTurn: !state.halfPageTurn);
    _saveToPrefs();
  }

  void cycleColorMode() {
    final next = ColorMode
        .values[(state.colorMode.index + 1) % ColorMode.values.length];
    state = state.copyWith(colorMode: next);
    _saveToPrefs();
  }

  void setColorMode(ColorMode mode) {
    state = state.copyWith(colorMode: mode);
    _saveToPrefs();
  }

  void setBrightness(double value) {
    state = state.copyWith(brightness: value.clamp(0.6, 1.0));
    _saveToPrefs();
  }

  void toggleAnnotationLayer(AnnotationLayer layer) {
    switch (layer) {
      case AnnotationLayer.private:
        state = state.copyWith(annotationPrivate: !state.annotationPrivate);
      case AnnotationLayer.voice:
        state = state.copyWith(annotationVoice: !state.annotationVoice);
      case AnnotationLayer.orchestra:
        state = state.copyWith(annotationOrchestra: !state.annotationOrchestra);
    }
    _saveToPrefs();
  }

  bool isLayerVisible(AnnotationLayer layer) {
    return switch (layer) {
      AnnotationLayer.private => state.annotationPrivate,
      AnnotationLayer.voice => state.annotationVoice,
      AnnotationLayer.orchestra => state.annotationOrchestra,
    };
  }

  void setHalfPageSplit(double ratio) {
    state = state.copyWith(halfPageSplit: ratio.clamp(0.4, 0.6));
    _saveToPrefs();
  }
}
