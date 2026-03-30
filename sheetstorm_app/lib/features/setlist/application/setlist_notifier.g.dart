// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SetlistListNotifier)
final setlistListProvider = SetlistListNotifierProvider._();

final class SetlistListNotifierProvider
    extends $AsyncNotifierProvider<SetlistListNotifier, List<Setlist>> {
  SetlistListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setlistListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setlistListNotifierHash();

  @$internal
  @override
  SetlistListNotifier create() => SetlistListNotifier();
}

String _$setlistListNotifierHash() =>
    r'e31187d9381f3b1253940856a5a40865c4114799';

abstract class _$SetlistListNotifier extends $AsyncNotifier<List<Setlist>> {
  FutureOr<List<Setlist>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Setlist>>, List<Setlist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Setlist>>, List<Setlist>>,
              AsyncValue<List<Setlist>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(SetlistDetailNotifier)
final setlistDetailProvider = SetlistDetailNotifierFamily._();

final class SetlistDetailNotifierProvider
    extends $AsyncNotifierProvider<SetlistDetailNotifier, Setlist> {
  SetlistDetailNotifierProvider._({
    required SetlistDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'setlistDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setlistDetailNotifierHash();

  @override
  String toString() {
    return r'setlistDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SetlistDetailNotifier create() => SetlistDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is SetlistDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setlistDetailNotifierHash() =>
    r'795f4f0d464481920482b8c469ef7225da0e2183';

final class SetlistDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SetlistDetailNotifier,
          AsyncValue<Setlist>,
          Setlist,
          FutureOr<Setlist>,
          String
        > {
  SetlistDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'setlistDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SetlistDetailNotifierProvider call(String setlistId) =>
      SetlistDetailNotifierProvider._(argument: setlistId, from: this);

  @override
  String toString() => r'setlistDetailProvider';
}

abstract class _$SetlistDetailNotifier extends $AsyncNotifier<Setlist> {
  late final _$args = ref.$arg as String;
  String get setlistId => _$args;

  FutureOr<Setlist> build(String setlistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Setlist>, Setlist>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Setlist>, Setlist>,
              AsyncValue<Setlist>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
