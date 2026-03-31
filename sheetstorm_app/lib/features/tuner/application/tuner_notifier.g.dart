// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tuner_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider für den [AudioAnalyzer].
///
/// In Production: PlatformAudioAnalyzer (Vision implementiert den Platform Channel).
/// In Tests: [MockAudioAnalyzer] via Override.

@ProviderFor(audioAnalyzer)
final audioAnalyzerProvider = AudioAnalyzerProvider._();

/// Provider für den [AudioAnalyzer].
///
/// In Production: PlatformAudioAnalyzer (Vision implementiert den Platform Channel).
/// In Tests: [MockAudioAnalyzer] via Override.

final class AudioAnalyzerProvider
    extends $FunctionalProvider<AudioAnalyzer, AudioAnalyzer, AudioAnalyzer>
    with $Provider<AudioAnalyzer> {
  /// Provider für den [AudioAnalyzer].
  ///
  /// In Production: PlatformAudioAnalyzer (Vision implementiert den Platform Channel).
  /// In Tests: [MockAudioAnalyzer] via Override.
  AudioAnalyzerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'audioAnalyzerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$audioAnalyzerHash();

  @$internal
  @override
  $ProviderElement<AudioAnalyzer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AudioAnalyzer create(Ref ref) {
    return audioAnalyzer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioAnalyzer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioAnalyzer>(value),
    );
  }
}

String _$audioAnalyzerHash() => r'b109f4246db505366861099a630167c2f3b3482d';

/// Verwaltet den Zustand des Stimmgeräts.
///
/// Startet/stoppt die Mikrofon-Analyse, verarbeitet Frequenzen in Echtzeit,
/// und konfiguriert Kammerton und Transposition.

@ProviderFor(TunerNotifier)
final tunerProvider = TunerNotifierProvider._();

/// Verwaltet den Zustand des Stimmgeräts.
///
/// Startet/stoppt die Mikrofon-Analyse, verarbeitet Frequenzen in Echtzeit,
/// und konfiguriert Kammerton und Transposition.
final class TunerNotifierProvider
    extends $NotifierProvider<TunerNotifier, TunerState> {
  /// Verwaltet den Zustand des Stimmgeräts.
  ///
  /// Startet/stoppt die Mikrofon-Analyse, verarbeitet Frequenzen in Echtzeit,
  /// und konfiguriert Kammerton und Transposition.
  TunerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tunerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tunerNotifierHash();

  @$internal
  @override
  TunerNotifier create() => TunerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TunerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TunerState>(value),
    );
  }
}

String _$tunerNotifierHash() => r'dde46fd30094cb40ec58751a3604fbab4753f570';

/// Verwaltet den Zustand des Stimmgeräts.
///
/// Startet/stoppt die Mikrofon-Analyse, verarbeitet Frequenzen in Echtzeit,
/// und konfiguriert Kammerton und Transposition.

abstract class _$TunerNotifier extends $Notifier<TunerState> {
  TunerState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<TunerState, TunerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TunerState, TunerState>,
              TunerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
