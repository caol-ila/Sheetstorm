// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(eventService)
final eventServiceProvider = EventServiceProvider._();

final class EventServiceProvider
    extends $FunctionalProvider<EventService, EventService, EventService>
    with $Provider<EventService> {
  EventServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventServiceHash();

  @$internal
  @override
  $ProviderElement<EventService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventService create(Ref ref) {
    return eventService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventService>(value),
    );
  }
}

String _$eventServiceHash() => r'132a424b2ceb4e613e7721d3ceec4c1225c91718';
