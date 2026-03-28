// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importService)
final importServiceProvider = ImportServiceProvider._();

final class ImportServiceProvider
    extends $FunctionalProvider<ImportService, ImportService, ImportService>
    with $Provider<ImportService> {
  ImportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'importServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$importServiceHash();

  @$internal
  @override
  $ProviderElement<ImportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportService create(Ref ref) {
    return importService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportService>(value),
    );
  }
}

String _$importServiceHash() => r'24c4b348de7d0800c4825a4a2f69c8d2dd036f43';
