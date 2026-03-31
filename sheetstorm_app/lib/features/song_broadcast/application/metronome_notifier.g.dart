// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metronome_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MetronomeNotifier)
final metronomeProvider = MetronomeNotifierProvider._();

final class MetronomeNotifierProvider
    extends $NotifierProvider<MetronomeNotifier, MetronomeState> {
  MetronomeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metronomeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metronomeNotifierHash();

  @$internal
  @override
  MetronomeNotifier create() => MetronomeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetronomeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetronomeState>(value),
    );
  }
}

String _$metronomeNotifierHash() => r'311da19132f74c50593447d6dfd87f7ab4087831';

abstract class _$MetronomeNotifier extends $Notifier<MetronomeState> {
  MetronomeState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MetronomeState, MetronomeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MetronomeState, MetronomeState>,
              MetronomeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
