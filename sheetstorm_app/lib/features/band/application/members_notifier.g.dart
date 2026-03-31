// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'members_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MembersNotifier)
final membersProvider = MembersNotifierFamily._();

final class MembersNotifierProvider
    extends $AsyncNotifierProvider<MembersNotifier, List<Member>> {
  MembersNotifierProvider._({
    required MembersNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'membersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$membersNotifierHash();

  @override
  String toString() {
    return r'membersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MembersNotifier create() => MembersNotifier();

  @override
  bool operator ==(Object other) {
    return other is MembersNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$membersNotifierHash() => r'0b1731bcdc8da348436b29a7e78bc39c84012bea';

final class MembersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MembersNotifier,
          AsyncValue<List<Member>>,
          List<Member>,
          FutureOr<List<Member>>,
          String
        > {
  MembersNotifierFamily._()
    : super(
        retry: null,
        name: r'membersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MembersNotifierProvider call(String bandId) =>
      MembersNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'membersProvider';
}

abstract class _$MembersNotifier extends $AsyncNotifier<List<Member>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<Member>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Member>>, List<Member>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Member>>, List<Member>>,
              AsyncValue<List<Member>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
