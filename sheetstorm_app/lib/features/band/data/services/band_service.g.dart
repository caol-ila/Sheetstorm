// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'band_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(bandService)
final bandServiceProvider = BandServiceProvider._();

final class BandServiceProvider
    extends $FunctionalProvider<BandService, BandService, BandService>
    with $Provider<BandService> {
  BandServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bandServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bandServiceHash();

  @$internal
  @override
  $ProviderElement<BandService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BandService create(Ref ref) {
    return bandService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BandService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BandService>(value),
    );
  }
}

String _$bandServiceHash() => r'5ac0cf24f219d80ab58d91faf90ade991e17baf9';
