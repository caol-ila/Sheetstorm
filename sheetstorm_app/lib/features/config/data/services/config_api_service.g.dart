// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_api_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(configApiService)
final configApiServiceProvider = ConfigApiServiceProvider._();

final class ConfigApiServiceProvider
    extends
        $FunctionalProvider<
          ConfigApiService,
          ConfigApiService,
          ConfigApiService
        >
    with $Provider<ConfigApiService> {
  ConfigApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configApiServiceHash();

  @$internal
  @override
  $ProviderElement<ConfigApiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfigApiService create(Ref ref) {
    return configApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigApiService>(value),
    );
  }
}

String _$configApiServiceHash() => r'6b5fdc4466c2a54bc45aed75aef3072ba4e70c73';
