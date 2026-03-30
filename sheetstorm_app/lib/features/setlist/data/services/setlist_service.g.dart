// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(setlistService)
final setlistServiceProvider = SetlistServiceProvider._();

final class SetlistServiceProvider
    extends $FunctionalProvider<SetlistService, SetlistService, SetlistService>
    with $Provider<SetlistService> {
  SetlistServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setlistServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setlistServiceHash();

  @$internal
  @override
  $ProviderElement<SetlistService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SetlistService create(Ref ref) {
    return setlistService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetlistService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetlistService>(value),
    );
  }
}

String _$setlistServiceHash() => r'acbf52d5f3c452f2ac76f0ace6fa6263d8a22a85';
