// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitations_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(InvitationsNotifier)
final invitationsProvider = InvitationsNotifierFamily._();

final class InvitationsNotifierProvider
    extends $AsyncNotifierProvider<InvitationsNotifier, List<Invitation>> {
  InvitationsNotifierProvider._({
    required InvitationsNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'invitationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$invitationsNotifierHash();

  @override
  String toString() {
    return r'invitationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  InvitationsNotifier create() => InvitationsNotifier();

  @override
  bool operator ==(Object other) {
    return other is InvitationsNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invitationsNotifierHash() =>
    r'f6ae9c4f4f9f8bcf5c80f519d44b07b408a29650';

final class InvitationsNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          InvitationsNotifier,
          AsyncValue<List<Invitation>>,
          List<Invitation>,
          FutureOr<List<Invitation>>,
          String
        > {
  InvitationsNotifierFamily._()
    : super(
        retry: null,
        name: r'invitationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InvitationsNotifierProvider call(String bandId) =>
      InvitationsNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'invitationsProvider';
}

abstract class _$InvitationsNotifier extends $AsyncNotifier<List<Invitation>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<Invitation>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<Invitation>>, List<Invitation>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Invitation>>, List<Invitation>>,
              AsyncValue<List<Invitation>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
