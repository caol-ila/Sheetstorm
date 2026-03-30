// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalendarNotifier)
final calendarProvider = CalendarNotifierFamily._();

final class CalendarNotifierProvider
    extends $AsyncNotifierProvider<CalendarNotifier, List<CalendarEntry>> {
  CalendarNotifierProvider._({
    required CalendarNotifierFamily super.from,
    required ({
      String? bandId,
      DateTime? month,
      EventType? typeFilter,
      RsvpStatus? statusFilter,
      CalendarViewMode viewMode,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'calendarProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calendarNotifierHash();

  @override
  String toString() {
    return r'calendarProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  CalendarNotifier create() => CalendarNotifier();

  @override
  bool operator ==(Object other) {
    return other is CalendarNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calendarNotifierHash() => r'fe7aa1013ecbe1633ef8458ae062573f38340ca8';

final class CalendarNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          CalendarNotifier,
          AsyncValue<List<CalendarEntry>>,
          List<CalendarEntry>,
          FutureOr<List<CalendarEntry>>,
          ({
            String? bandId,
            DateTime? month,
            EventType? typeFilter,
            RsvpStatus? statusFilter,
            CalendarViewMode viewMode,
          })
        > {
  CalendarNotifierFamily._()
    : super(
        retry: null,
        name: r'calendarProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  CalendarNotifierProvider call({
    String? bandId,
    DateTime? month,
    EventType? typeFilter,
    RsvpStatus? statusFilter,
    CalendarViewMode viewMode = CalendarViewMode.month,
  }) => CalendarNotifierProvider._(
    argument: (
      bandId: bandId,
      month: month,
      typeFilter: typeFilter,
      statusFilter: statusFilter,
      viewMode: viewMode,
    ),
    from: this,
  );

  @override
  String toString() => r'calendarProvider';
}

abstract class _$CalendarNotifier extends $AsyncNotifier<List<CalendarEntry>> {
  late final _$args =
      ref.$arg
          as ({
            String? bandId,
            DateTime? month,
            EventType? typeFilter,
            RsvpStatus? statusFilter,
            CalendarViewMode viewMode,
          });
  String? get bandId => _$args.bandId;
  DateTime? get month => _$args.month;
  EventType? get typeFilter => _$args.typeFilter;
  RsvpStatus? get statusFilter => _$args.statusFilter;
  CalendarViewMode get viewMode => _$args.viewMode;

  FutureOr<List<CalendarEntry>> build({
    String? bandId,
    DateTime? month,
    EventType? typeFilter,
    RsvpStatus? statusFilter,
    CalendarViewMode viewMode = CalendarViewMode.month,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CalendarEntry>>, List<CalendarEntry>>,
              AsyncValue<List<CalendarEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        bandId: _$args.bandId,
        month: _$args.month,
        typeFilter: _$args.typeFilter,
        statusFilter: _$args.statusFilter,
        viewMode: _$args.viewMode,
      ),
    );
  }
}

@ProviderFor(SelectedDateNotifier)
final selectedDateProvider = SelectedDateNotifierProvider._();

final class SelectedDateNotifierProvider
    extends $NotifierProvider<SelectedDateNotifier, DateTime> {
  SelectedDateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedDateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedDateNotifierHash();

  @$internal
  @override
  SelectedDateNotifier create() => SelectedDateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$selectedDateNotifierHash() =>
    r'4c91d0a8e5fc47375fc982c62a17c7f92da4ca7a';

abstract class _$SelectedDateNotifier extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CalendarViewModeNotifier)
final calendarViewModeProvider = CalendarViewModeNotifierProvider._();

final class CalendarViewModeNotifierProvider
    extends $NotifierProvider<CalendarViewModeNotifier, CalendarViewMode> {
  CalendarViewModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calendarViewModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calendarViewModeNotifierHash();

  @$internal
  @override
  CalendarViewModeNotifier create() => CalendarViewModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalendarViewMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalendarViewMode>(value),
    );
  }
}

String _$calendarViewModeNotifierHash() =>
    r'8158cbe8ce8232daba1da78735aab4a69cf06c05';

abstract class _$CalendarViewModeNotifier extends $Notifier<CalendarViewMode> {
  CalendarViewMode build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalendarViewMode, CalendarViewMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalendarViewMode, CalendarViewMode>,
              CalendarViewMode,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
