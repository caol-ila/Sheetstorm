// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kapelle_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(kapelleService)
final kapelleServiceProvider = KapelleServiceProvider._();

final class KapelleServiceProvider
    extends $FunctionalProvider<KapelleService, KapelleService, KapelleService>
    with $Provider<KapelleService> {
  KapelleServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kapelleServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kapelleServiceHash();

  @$internal
  @override
  $ProviderElement<KapelleService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  KapelleService create(Ref ref) {
    return kapelleService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KapelleService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KapelleService>(value),
    );
  }
}

String _$kapelleServiceHash() => r'a955ef789ebb433cdb20f608fc2fc0307ece4744';
