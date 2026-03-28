// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mitglieder_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MitgliederNotifier)
final mitgliederProvider = MitgliederNotifierFamily._();

final class MitgliederNotifierProvider
    extends $AsyncNotifierProvider<MitgliederNotifier, List<Mitglied>> {
  MitgliederNotifierProvider._({
    required MitgliederNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mitgliederProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mitgliederNotifierHash();

  @override
  String toString() {
    return r'mitgliederProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MitgliederNotifier create() => MitgliederNotifier();

  @override
  bool operator ==(Object other) {
    return other is MitgliederNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mitgliederNotifierHash() =>
    r'c1b175f7f5a7a8fe3859a4bf87daec0abf4ba056';

final class MitgliederNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MitgliederNotifier,
          AsyncValue<List<Mitglied>>,
          List<Mitglied>,
          FutureOr<List<Mitglied>>,
          String
        > {
  MitgliederNotifierFamily._()
    : super(
        retry: null,
        name: r'mitgliederProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MitgliederNotifierProvider call(String kapelleId) =>
      MitgliederNotifierProvider._(argument: kapelleId, from: this);

  @override
  String toString() => r'mitgliederProvider';
}

abstract class _$MitgliederNotifier extends $AsyncNotifier<List<Mitglied>> {
  late final _$args = ref.$arg as String;
  String get kapelleId => _$args;

  FutureOr<List<Mitglied>> build(String kapelleId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Mitglied>>, List<Mitglied>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Mitglied>>, List<Mitglied>>,
              AsyncValue<List<Mitglied>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
