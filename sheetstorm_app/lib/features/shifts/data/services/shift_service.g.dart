// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shiftService)
final shiftServiceProvider = ShiftServiceProvider._();

final class ShiftServiceProvider
    extends $FunctionalProvider<ShiftService, ShiftService, ShiftService>
    with $Provider<ShiftService> {
  ShiftServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftServiceHash();

  @$internal
  @override
  $ProviderElement<ShiftService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShiftService create(Ref ref) {
    return shiftService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftService>(value),
    );
  }
}

String _$shiftServiceHash() => r'496b774cc3ad832ddc287c8617a3afc69dcbccc1';
