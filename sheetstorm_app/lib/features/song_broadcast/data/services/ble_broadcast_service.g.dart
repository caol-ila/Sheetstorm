// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ble_broadcast_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bleBroadcastService)
final bleBroadcastServiceProvider = BleBroadcastServiceProvider._();

final class BleBroadcastServiceProvider
    extends
        $FunctionalProvider<
          BleBroadcastService,
          BleBroadcastService,
          BleBroadcastService
        >
    with $Provider<BleBroadcastService> {
  BleBroadcastServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bleBroadcastServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bleBroadcastServiceHash();

  @$internal
  @override
  $ProviderElement<BleBroadcastService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BleBroadcastService create(Ref ref) {
    return bleBroadcastService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BleBroadcastService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BleBroadcastService>(value),
    );
  }
}

String _$bleBroadcastServiceHash() =>
    r'8158b7d50aa43ccc6bb083ae392c8c2b2586a1f7';
