// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spielmodus_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Family provider: one notifier instance per notenId.

@ProviderFor(SpielmodusNotifier)
final spielmodusProvider = SpielmodusNotifierFamily._();

/// Family provider: one notifier instance per notenId.
final class SpielmodusNotifierProvider
    extends $NotifierProvider<SpielmodusNotifier, SpielmodusState> {
  /// Family provider: one notifier instance per notenId.
  SpielmodusNotifierProvider._({
    required SpielmodusNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'spielmodusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$spielmodusNotifierHash();

  @override
  String toString() {
    return r'spielmodusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SpielmodusNotifier create() => SpielmodusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpielmodusState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SpielmodusState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SpielmodusNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spielmodusNotifierHash() =>
    r'3ffbbd6fd28a8ba3169bd5e046b6a3b2dee45668';

/// Family provider: one notifier instance per notenId.

final class SpielmodusNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SpielmodusNotifier,
          SpielmodusState,
          SpielmodusState,
          SpielmodusState,
          String
        > {
  SpielmodusNotifierFamily._()
    : super(
        retry: null,
        name: r'spielmodusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider: one notifier instance per notenId.

  SpielmodusNotifierProvider call(String notenId) =>
      SpielmodusNotifierProvider._(argument: notenId, from: this);

  @override
  String toString() => r'spielmodusProvider';
}

/// Family provider: one notifier instance per notenId.

abstract class _$SpielmodusNotifier extends $Notifier<SpielmodusState> {
  late final _$args = ref.$arg as String;
  String get notenId => _$args;

  SpielmodusState build(String notenId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SpielmodusState, SpielmodusState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SpielmodusState, SpielmodusState>,
              SpielmodusState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
