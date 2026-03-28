// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_mode_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Family provider: one notifier instance per sheetId.

@ProviderFor(PerformanceModeNotifier)
final performanceModeProvider = PerformanceModeNotifierFamily._();

/// Family provider: one notifier instance per sheetId.
final class PerformanceModeNotifierProvider
    extends $NotifierProvider<PerformanceModeNotifier, PerformanceModeState> {
  /// Family provider: one notifier instance per sheetId.
  PerformanceModeNotifierProvider._({
    required PerformanceModeNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'performanceModeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$performanceModeNotifierHash();

  @override
  String toString() {
    return r'performanceModeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PerformanceModeNotifier create() => PerformanceModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PerformanceModeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PerformanceModeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PerformanceModeNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$performanceModeNotifierHash() =>
    r'97736aec815bb17c94cb00fa67fcffd0b797bd8b';

/// Family provider: one notifier instance per sheetId.

final class PerformanceModeNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PerformanceModeNotifier,
          PerformanceModeState,
          PerformanceModeState,
          PerformanceModeState,
          String
        > {
  PerformanceModeNotifierFamily._()
    : super(
        retry: null,
        name: r'performanceModeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Family provider: one notifier instance per sheetId.

  PerformanceModeNotifierProvider call(String sheetId) =>
      PerformanceModeNotifierProvider._(argument: sheetId, from: this);

  @override
  String toString() => r'performanceModeProvider';
}

/// Family provider: one notifier instance per sheetId.

abstract class _$PerformanceModeNotifier
    extends $Notifier<PerformanceModeState> {
  late final _$args = ref.$arg as String;
  String get sheetId => _$args;

  PerformanceModeState build(String sheetId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<PerformanceModeState, PerformanceModeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PerformanceModeState, PerformanceModeState>,
              PerformanceModeState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
