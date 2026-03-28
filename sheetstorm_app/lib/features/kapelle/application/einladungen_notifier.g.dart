// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'einladungen_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EinladungenNotifier)
final einladungenProvider = EinladungenNotifierFamily._();

final class EinladungenNotifierProvider
    extends $AsyncNotifierProvider<EinladungenNotifier, List<Einladung>> {
  EinladungenNotifierProvider._({
    required EinladungenNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'einladungenProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$einladungenNotifierHash();

  @override
  String toString() {
    return r'einladungenProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EinladungenNotifier create() => EinladungenNotifier();

  @override
  bool operator ==(Object other) {
    return other is EinladungenNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$einladungenNotifierHash() =>
    r'adda51e79a4670e614c06a3cb9b07e7b286f3016';

final class EinladungenNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EinladungenNotifier,
          AsyncValue<List<Einladung>>,
          List<Einladung>,
          FutureOr<List<Einladung>>,
          String
        > {
  EinladungenNotifierFamily._()
    : super(
        retry: null,
        name: r'einladungenProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EinladungenNotifierProvider call(String kapelleId) =>
      EinladungenNotifierProvider._(argument: kapelleId, from: this);

  @override
  String toString() => r'einladungenProvider';
}

abstract class _$EinladungenNotifier extends $AsyncNotifier<List<Einladung>> {
  late final _$args = ref.$arg as String;
  String get kapelleId => _$args;

  FutureOr<List<Einladung>> build(String kapelleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Einladung>>, List<Einladung>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Einladung>>, List<Einladung>>,
              AsyncValue<List<Einladung>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
