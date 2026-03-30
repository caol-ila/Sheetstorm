// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_link_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MediaLinkNotifier)
final mediaLinkProvider = MediaLinkNotifierFamily._();

final class MediaLinkNotifierProvider
    extends $AsyncNotifierProvider<MediaLinkNotifier, List<MediaLink>> {
  MediaLinkNotifierProvider._({
    required MediaLinkNotifierFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'mediaLinkProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mediaLinkNotifierHash();

  @override
  String toString() {
    return r'mediaLinkProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  MediaLinkNotifier create() => MediaLinkNotifier();

  @override
  bool operator ==(Object other) {
    return other is MediaLinkNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mediaLinkNotifierHash() => r'65ed4f5952116750aaca104a49cf33cbc928297e';

final class MediaLinkNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MediaLinkNotifier,
          AsyncValue<List<MediaLink>>,
          List<MediaLink>,
          FutureOr<List<MediaLink>>,
          (String, String)
        > {
  MediaLinkNotifierFamily._()
    : super(
        retry: null,
        name: r'mediaLinkProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MediaLinkNotifierProvider call(String kapelleId, String stueckId) =>
      MediaLinkNotifierProvider._(argument: (kapelleId, stueckId), from: this);

  @override
  String toString() => r'mediaLinkProvider';
}

abstract class _$MediaLinkNotifier extends $AsyncNotifier<List<MediaLink>> {
  late final _$args = ref.$arg as (String, String);
  String get kapelleId => _$args.$1;
  String get stueckId => _$args.$2;

  FutureOr<List<MediaLink>> build(String kapelleId, String stueckId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<MediaLink>>, List<MediaLink>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MediaLink>>, List<MediaLink>>,
              AsyncValue<List<MediaLink>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
