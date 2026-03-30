// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'broadcast_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(broadcastRestService)
final broadcastRestServiceProvider = BroadcastRestServiceProvider._();

final class BroadcastRestServiceProvider
    extends
        $FunctionalProvider<
          BroadcastRestService,
          BroadcastRestService,
          BroadcastRestService
        >
    with $Provider<BroadcastRestService> {
  BroadcastRestServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'broadcastRestServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$broadcastRestServiceHash();

  @$internal
  @override
  $ProviderElement<BroadcastRestService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BroadcastRestService create(Ref ref) {
    return broadcastRestService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BroadcastRestService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BroadcastRestService>(value),
    );
  }
}

String _$broadcastRestServiceHash() =>
    r'af759b103c8702531d808ce775c4e4083c2a5e2f';

@ProviderFor(broadcastSignalRService)
final broadcastSignalRServiceProvider = BroadcastSignalRServiceProvider._();

final class BroadcastSignalRServiceProvider
    extends
        $FunctionalProvider<
          BroadcastSignalRService,
          BroadcastSignalRService,
          BroadcastSignalRService
        >
    with $Provider<BroadcastSignalRService> {
  BroadcastSignalRServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'broadcastSignalRServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$broadcastSignalRServiceHash();

  @$internal
  @override
  $ProviderElement<BroadcastSignalRService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BroadcastSignalRService create(Ref ref) {
    return broadcastSignalRService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BroadcastSignalRService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BroadcastSignalRService>(value),
    );
  }
}

String _$broadcastSignalRServiceHash() =>
    r'c44a140601b4578bf157bf72f67cde1f824163e8';
