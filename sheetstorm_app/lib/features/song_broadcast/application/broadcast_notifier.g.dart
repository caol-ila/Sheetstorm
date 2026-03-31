// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BroadcastNotifier)
final broadcastProvider = BroadcastNotifierProvider._();

final class BroadcastNotifierProvider
    extends $NotifierProvider<BroadcastNotifier, BroadcastState> {
  BroadcastNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'broadcastProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$broadcastNotifierHash();

  @$internal
  @override
  BroadcastNotifier create() => BroadcastNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BroadcastState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BroadcastState>(value),
    );
  }
}

String _$broadcastNotifierHash() => r'eeaf63794e63ed57a23dcb772a23af26277aa7a7';

abstract class _$BroadcastNotifier extends $Notifier<BroadcastState> {
  BroadcastState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BroadcastState, BroadcastState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BroadcastState, BroadcastState>,
              BroadcastState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
