// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'config_local_storage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(configLocalStorage)
final configLocalStorageProvider = ConfigLocalStorageProvider._();

final class ConfigLocalStorageProvider
    extends
        $FunctionalProvider<
          ConfigLocalStorage,
          ConfigLocalStorage,
          ConfigLocalStorage
        >
    with $Provider<ConfigLocalStorage> {
  ConfigLocalStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configLocalStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configLocalStorageHash();

  @$internal
  @override
  $ProviderElement<ConfigLocalStorage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConfigLocalStorage create(Ref ref) {
    return configLocalStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfigLocalStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfigLocalStorage>(value),
    );
  }
}

String _$configLocalStorageHash() =>
    r'f4cf7f1a1488f55291a2fd1e7771b178d8adf6cb';
