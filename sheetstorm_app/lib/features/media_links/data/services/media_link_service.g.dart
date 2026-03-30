// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_link_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaLinkService)
final mediaLinkServiceProvider = MediaLinkServiceProvider._();

final class MediaLinkServiceProvider
    extends
        $FunctionalProvider<
          MediaLinkService,
          MediaLinkService,
          MediaLinkService
        >
    with $Provider<MediaLinkService> {
  MediaLinkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLinkServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLinkServiceHash();

  @$internal
  @override
  $ProviderElement<MediaLinkService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaLinkService create(Ref ref) {
    return mediaLinkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaLinkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaLinkService>(value),
    );
  }
}

String _$mediaLinkServiceHash() => r'ea42541df9c0d5fa7d69fb03949574f7a159b889';
