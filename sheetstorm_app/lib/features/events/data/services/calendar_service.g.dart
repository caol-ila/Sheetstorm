// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calendarService)
final calendarServiceProvider = CalendarServiceProvider._();

final class CalendarServiceProvider
    extends
        $FunctionalProvider<CalendarService, CalendarService, CalendarService>
    with $Provider<CalendarService> {
  CalendarServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarServiceHash();

  @$internal
  @override
  $ProviderElement<CalendarService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CalendarService create(Ref ref) {
    return calendarService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarService>(value),
    );
  }
}

String _$calendarServiceHash() => r'243616f7cdbeba4d5d59fcfaec268577de2720fd';
