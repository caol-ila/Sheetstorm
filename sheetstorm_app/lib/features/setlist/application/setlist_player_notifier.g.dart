// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setlist_player_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SetlistPlayerNotifier)
final setlistPlayerProvider = SetlistPlayerNotifierFamily._();

final class SetlistPlayerNotifierProvider
    extends $NotifierProvider<SetlistPlayerNotifier, SetlistPlayerState> {
  SetlistPlayerNotifierProvider._({
    required SetlistPlayerNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'setlistPlayerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$setlistPlayerNotifierHash();

  @override
  String toString() {
    return r'setlistPlayerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SetlistPlayerNotifier create() => SetlistPlayerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SetlistPlayerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SetlistPlayerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SetlistPlayerNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$setlistPlayerNotifierHash() =>
    r'b84332aa3181a10b5f6790bc796fee3041e86bf0';

final class SetlistPlayerNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SetlistPlayerNotifier,
          SetlistPlayerState,
          SetlistPlayerState,
          SetlistPlayerState,
          String
        > {
  SetlistPlayerNotifierFamily._()
    : super(
        retry: null,
        name: r'setlistPlayerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SetlistPlayerNotifierProvider call(String setlistId) =>
      SetlistPlayerNotifierProvider._(argument: setlistId, from: this);

  @override
  String toString() => r'setlistPlayerProvider';
}

abstract class _$SetlistPlayerNotifier extends $Notifier<SetlistPlayerState> {
  late final _$args = ref.$arg as String;
  String get setlistId => _$args;

  SetlistPlayerState build(String setlistId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SetlistPlayerState, SetlistPlayerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SetlistPlayerState, SetlistPlayerState>,
              SetlistPlayerState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
