// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'band_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveBandNotifier)
final activeBandProvider = ActiveBandNotifierProvider._();

final class ActiveBandNotifierProvider
    extends $NotifierProvider<ActiveBandNotifier, String?> {
  ActiveBandNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBandProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBandNotifierHash();

  @$internal
  @override
  ActiveBandNotifier create() => ActiveBandNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeBandNotifierHash() =>
    r'ff787470da5a4064c7106566556523b6e7e91dea';

abstract class _$ActiveBandNotifier extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(BandListNotifier)
final bandListProvider = BandListNotifierProvider._();

final class BandListNotifierProvider
    extends $AsyncNotifierProvider<BandListNotifier, List<Band>> {
  BandListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bandListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bandListNotifierHash();

  @$internal
  @override
  BandListNotifier create() => BandListNotifier();
}

String _$bandListNotifierHash() =>
    r'71c0dd616746833e7754121531af2385528f10cd';

abstract class _$BandListNotifier extends $AsyncNotifier<List<Band>> {
  FutureOr<List<Band>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Band>>, List<Band>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Band>>, List<Band>>,
              AsyncValue<List<Band>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
