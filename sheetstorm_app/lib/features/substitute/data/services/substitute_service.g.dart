// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'substitute_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(substituteService)
final substituteServiceProvider = SubstituteServiceProvider._();

final class SubstituteServiceProvider
    extends
        $FunctionalProvider<
          SubstituteService,
          SubstituteService,
          SubstituteService
        >
    with $Provider<SubstituteService> {
  SubstituteServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'substituteServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$substituteServiceHash();

  @$internal
  @override
  $ProviderElement<SubstituteService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubstituteService create(Ref ref) {
    return substituteService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubstituteService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubstituteService>(value),
    );
  }
}

String _$substituteServiceHash() => r'2f523775244bdbaff4cb31767dcabd876a494f1d';
