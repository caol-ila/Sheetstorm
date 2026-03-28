import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';

/// Provider for persistent Spielmodus settings (Spec §4, Datenmodell §7.3).
final spielmodusSettingsNotifierProvider = StateNotifierProvider.autoDispose<
    SpielmodusSettingsNotifier, SpielmodusEinstellungen>(
  (ref) => SpielmodusSettingsNotifier(),
);

/// Manages persistent Spielmodus settings.
///
/// Settings saved per-user via SharedPreferences.
/// In production: sync with PUT /api/v1/nutzer/einstellungen/spielmodus
class SpielmodusSettingsNotifier
    extends StateNotifier<SpielmodusEinstellungen> {
  SpielmodusSettingsNotifier() : super(const SpielmodusEinstellungen()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    state = SpielmodusEinstellungen(
      halfPageTurn: prefs.getBool('spielmodus_halfPageTurn') ?? true,
      farbmodus: Farbmodus.values[prefs.getInt('spielmodus_farbmodus') ?? 0],
      helligkeit: prefs.getDouble('spielmodus_helligkeit') ?? 1.0,
      annotationPrivat: prefs.getBool('spielmodus_annotPrivat') ?? true,
      annotationStimme: prefs.getBool('spielmodus_annotStimme') ?? true,
      annotationOrchester: prefs.getBool('spielmodus_annotOrchester') ?? true,
      halfPageSplit: prefs.getDouble('spielmodus_halfPageSplit') ?? 0.5,
    );
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('spielmodus_halfPageTurn', state.halfPageTurn),
      prefs.setInt('spielmodus_farbmodus', state.farbmodus.index),
      prefs.setDouble('spielmodus_helligkeit', state.helligkeit),
      prefs.setBool('spielmodus_annotPrivat', state.annotationPrivat),
      prefs.setBool('spielmodus_annotStimme', state.annotationStimme),
      prefs.setBool('spielmodus_annotOrchester', state.annotationOrchester),
      prefs.setDouble('spielmodus_halfPageSplit', state.halfPageSplit),
    ]);
  }

  void toggleHalfPageTurn() {
    state = state.copyWith(halfPageTurn: !state.halfPageTurn);
    _saveToPrefs();
  }

  void cycleFarbmodus() {
    final next = Farbmodus
        .values[(state.farbmodus.index + 1) % Farbmodus.values.length];
    state = state.copyWith(farbmodus: next);
    _saveToPrefs();
  }

  void setFarbmodus(Farbmodus mode) {
    state = state.copyWith(farbmodus: mode);
    _saveToPrefs();
  }

  void setHelligkeit(double value) {
    state = state.copyWith(helligkeit: value.clamp(0.6, 1.0));
    _saveToPrefs();
  }

  void toggleAnnotationLayer(AnnotationLayer layer) {
    switch (layer) {
      case AnnotationLayer.privat:
        state = state.copyWith(annotationPrivat: !state.annotationPrivat);
      case AnnotationLayer.stimme:
        state = state.copyWith(annotationStimme: !state.annotationStimme);
      case AnnotationLayer.orchester:
        state = state.copyWith(annotationOrchester: !state.annotationOrchester);
    }
    _saveToPrefs();
  }

  bool isLayerVisible(AnnotationLayer layer) {
    return switch (layer) {
      AnnotationLayer.privat => state.annotationPrivat,
      AnnotationLayer.stimme => state.annotationStimme,
      AnnotationLayer.orchester => state.annotationOrchester,
    };
  }

  void setHalfPageSplit(double ratio) {
    state = state.copyWith(halfPageSplit: ratio.clamp(0.4, 0.6));
    _saveToPrefs();
  }
}
