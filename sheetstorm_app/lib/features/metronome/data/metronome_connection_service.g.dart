// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'metronome_connection_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: type=lint, type=warning

@ProviderFor(metronomeSignalRService)
final metronomeSignalRServiceProvider = MetronomeSignalRServiceProvider._();

final class MetronomeSignalRServiceProvider
    extends $FunctionalProvider<MetronomeSignalRService, MetronomeSignalRService,
        MetronomeSignalRService>
    with $Provider<MetronomeSignalRService> {
  MetronomeSignalRServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'metronomeSignalRServiceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$metronomeSignalRServiceHash();

  @$internal
  @override
  $ProviderElement<MetronomeSignalRService> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MetronomeSignalRService create(Ref ref) {
    return metronomeSignalRService(ref);
  }

  Override overrideWithValue(MetronomeSignalRService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetronomeSignalRService>(value),
    );
  }
}

String _$metronomeSignalRServiceHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';