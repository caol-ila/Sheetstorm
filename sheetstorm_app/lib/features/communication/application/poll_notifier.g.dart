// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poll_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PollListNotifier)
final pollListProvider = PollListNotifierFamily._();

final class PollListNotifierProvider
    extends $AsyncNotifierProvider<PollListNotifier, List<Poll>> {
  PollListNotifierProvider._({
    required PollListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pollListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollListNotifierHash();

  @override
  String toString() {
    return r'pollListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  PollListNotifier create() => PollListNotifier();

  @override
  bool operator ==(Object other) {
    return other is PollListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollListNotifierHash() => r'710264dc5062bbcb922a0f3457e79923fcebb4ef';

final class PollListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PollListNotifier,
          AsyncValue<List<Poll>>,
          List<Poll>,
          FutureOr<List<Poll>>,
          String
        > {
  PollListNotifierFamily._()
    : super(
        retry: null,
        name: r'pollListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PollListNotifierProvider call(String bandId) =>
      PollListNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'pollListProvider';
}

abstract class _$PollListNotifier extends $AsyncNotifier<List<Poll>> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<List<Poll>> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Poll>>, List<Poll>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Poll>>, List<Poll>>,
              AsyncValue<List<Poll>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(PollDetailNotifier)
final pollDetailProvider = PollDetailNotifierFamily._();

final class PollDetailNotifierProvider
    extends $AsyncNotifierProvider<PollDetailNotifier, Poll> {
  PollDetailNotifierProvider._({
    required PollDetailNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'pollDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pollDetailNotifierHash();

  @override
  String toString() {
    return r'pollDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  PollDetailNotifier create() => PollDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is PollDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pollDetailNotifierHash() =>
    r'd41c58a1685af2ca9f1cfc764f8a3313fc4702f1';

final class PollDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          PollDetailNotifier,
          AsyncValue<Poll>,
          Poll,
          FutureOr<Poll>,
          (String, String)
        > {
  PollDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'pollDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PollDetailNotifierProvider call(String bandId, String pollId) =>
      PollDetailNotifierProvider._(argument: (bandId, pollId), from: this);

  @override
  String toString() => r'pollDetailProvider';
}

abstract class _$PollDetailNotifier extends $AsyncNotifier<Poll> {
  late final _$args = ref.$arg as (String, String);
  String get bandId => _$args.$1;
  String get pollId => _$args.$2;

  FutureOr<Poll> build(String bandId, String pollId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Poll>, Poll>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Poll>, Poll>,
              AsyncValue<Poll>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
