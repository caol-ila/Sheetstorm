import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/tuner/data/audio_analyzer.dart';
import 'package:sheetstorm/features/tuner/data/frequency_converter.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

part 'tuner_notifier.g.dart';

/// Provider für den [AudioAnalyzer].
///
/// In Production: PlatformAudioAnalyzer (Vision implementiert den Platform Channel).
/// In Tests: [MockAudioAnalyzer] via Override.
@riverpod
AudioAnalyzer audioAnalyzer(Ref ref) {
  final analyzer = MockAudioAnalyzer();
  ref.onDispose(analyzer.dispose);
  return analyzer;
}

/// Verwaltet den Zustand des Stimmgeräts.
///
/// Startet/stoppt die Mikrofon-Analyse, verarbeitet Frequenzen in Echtzeit,
/// und konfiguriert Kammerton und Transposition.
@Riverpod(keepAlive: true)
class TunerNotifier extends _$TunerNotifier {
  StreamSubscription<double>? _subscription;

  @override
  TunerState build() => const TunerState();

  /// Startet die Mikrofon-Aufnahme und Echtzeit-Frequenz-Erkennung.
  Future<void> start() async {
    final analyzer = ref.read(audioAnalyzerProvider);
    await analyzer.startListening();
    state = state.copyWith(isListening: true);

    _subscription = analyzer.frequencyStream.listen(
      _onFrequency,
      onError: (_) => _onError(),
    );
  }

  /// Stoppt die Mikrofon-Aufnahme und gibt das Mikrofon frei.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    final analyzer = ref.read(audioAnalyzerProvider);
    await analyzer.stopListening();
    state = state.copyWith(
      isListening: false,
      note: null,
      centDeviation: 0.0,
    );
  }

  /// Setzt den Kammerton (Referenzfrequenz für A4) — Bereich 430–450 Hz.
  void setReferenceFrequency(double hz) {
    final clamped = hz.clamp(430.0, 450.0);
    state = state.copyWith(referenceFrequency: clamped);
  }

  /// Setzt den Transpositionsmodus (C/Bb/Eb/F).
  void setTransposition(TranspositionMode mode) {
    state = state.copyWith(transposition: mode);
  }

  void _onFrequency(double hz) {
    final note = FrequencyToNoteConverter.convert(
      hz,
      referenceFrequency: state.referenceFrequency,
      transposition: state.transposition,
    );
    state = state.copyWith(
      frequency: hz,
      note: note,
      centDeviation: note?.centOffset ?? 0.0,
    );
  }

  void _onError() {
    state = state.copyWith(
      isListening: false,
      errorMessage: 'Mikrofon-Fehler. Bitte Berechtigung prüfen.',
    );
  }
}
