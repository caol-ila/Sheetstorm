// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kapelle_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveKapelleNotifier)
final activeKapelleProvider = ActiveKapelleNotifierProvider._();

final class ActiveKapelleNotifierProvider
    extends $NotifierProvider<ActiveKapelleNotifier, String?> {
  ActiveKapelleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeKapelleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeKapelleNotifierHash();

  @$internal
  @override
  ActiveKapelleNotifier create() => ActiveKapelleNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$activeKapelleNotifierHash() =>
    r'ff787470da5a4064c7106566556523b6e7e91dea';

abstract class _$ActiveKapelleNotifier extends $Notifier<String?> {
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

@ProviderFor(KapelleListNotifier)
final kapelleListProvider = KapelleListNotifierProvider._();

final class KapelleListNotifierProvider
    extends $AsyncNotifierProvider<KapelleListNotifier, List<Kapelle>> {
  KapelleListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'kapelleListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$kapelleListNotifierHash();

  @$internal
  @override
  KapelleListNotifier create() => KapelleListNotifier();
}

String _$kapelleListNotifierHash() =>
    r'71c0dd616746833e7754121531af2385528f10cd';

abstract class _$KapelleListNotifier extends $AsyncNotifier<List<Kapelle>> {
  FutureOr<List<Kapelle>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Kapelle>>, List<Kapelle>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Kapelle>>, List<Kapelle>>,
              AsyncValue<List<Kapelle>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
