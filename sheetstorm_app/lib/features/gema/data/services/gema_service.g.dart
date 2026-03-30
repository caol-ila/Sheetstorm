// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gema_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gemaService)
final gemaServiceProvider = GemaServiceProvider._();

final class GemaServiceProvider
    extends $FunctionalProvider<GemaService, GemaService, GemaService>
    with $Provider<GemaService> {
  GemaServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gemaServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gemaServiceHash();

  @$internal
  @override
  $ProviderElement<GemaService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GemaService create(Ref ref) {
    return gemaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GemaService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GemaService>(value),
    );
  }
}

String _$gemaServiceHash() => r'76884e7338bd3ad009554bf089d919cb4267da86';
