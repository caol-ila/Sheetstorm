// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EventListNotifier)
final eventListProvider = EventListNotifierFamily._();

final class EventListNotifierProvider
    extends $AsyncNotifierProvider<EventListNotifier, List<Event>> {
  EventListNotifierProvider._({
    required EventListNotifierFamily super.from,
    required ({String? bandId, EventType? type, RsvpStatus? status})
    super.argument,
  }) : super(
         retry: null,
         name: r'eventListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventListNotifierHash();

  @override
  String toString() {
    return r'eventListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  EventListNotifier create() => EventListNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventListNotifierHash() => r'374b2e01347b60028d0d670f7d1180a3151776e8';

final class EventListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventListNotifier,
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>,
          ({String? bandId, EventType? type, RsvpStatus? status})
        > {
  EventListNotifierFamily._()
    : super(
        retry: null,
        name: r'eventListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  EventListNotifierProvider call({
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  }) => EventListNotifierProvider._(
    argument: (bandId: bandId, type: type, status: status),
    from: this,
  );

  @override
  String toString() => r'eventListProvider';
}

abstract class _$EventListNotifier extends $AsyncNotifier<List<Event>> {
  late final _$args =
      ref.$arg as ({String? bandId, EventType? type, RsvpStatus? status});
  String? get bandId => _$args.bandId;
  EventType? get type => _$args.type;
  RsvpStatus? get status => _$args.status;

  FutureOr<List<Event>> build({
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  });
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Event>>, List<Event>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Event>>, List<Event>>,
              AsyncValue<List<Event>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(
        bandId: _$args.bandId,
        type: _$args.type,
        status: _$args.status,
      ),
    );
  }
}

@ProviderFor(EventDetailNotifier)
final eventDetailProvider = EventDetailNotifierFamily._();

final class EventDetailNotifierProvider
    extends $AsyncNotifierProvider<EventDetailNotifier, Event> {
  EventDetailNotifierProvider._({
    required EventDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventDetailNotifierHash();

  @override
  String toString() {
    return r'eventDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EventDetailNotifier create() => EventDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is EventDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailNotifierHash() =>
    r'ccd9da764db05ccfa0547e4edebfef0f434f0e13';

final class EventDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EventDetailNotifier,
          AsyncValue<Event>,
          Event,
          FutureOr<Event>,
          String
        > {
  EventDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'eventDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventDetailNotifierProvider call(String eventId) =>
      EventDetailNotifierProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailProvider';
}

abstract class _$EventDetailNotifier extends $AsyncNotifier<Event> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<Event> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Event>, Event>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Event>, Event>,
              AsyncValue<Event>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(RsvpListNotifier)
final rsvpListProvider = RsvpListNotifierFamily._();

final class RsvpListNotifierProvider
    extends $AsyncNotifierProvider<RsvpListNotifier, List<Rsvp>> {
  RsvpListNotifierProvider._({
    required RsvpListNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'rsvpListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$rsvpListNotifierHash();

  @override
  String toString() {
    return r'rsvpListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  RsvpListNotifier create() => RsvpListNotifier();

  @override
  bool operator ==(Object other) {
    return other is RsvpListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$rsvpListNotifierHash() => r'd3aa54ebd6824a241daa119c570a3644cfe80a4a';

final class RsvpListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          RsvpListNotifier,
          AsyncValue<List<Rsvp>>,
          List<Rsvp>,
          FutureOr<List<Rsvp>>,
          String
        > {
  RsvpListNotifierFamily._()
    : super(
        retry: null,
        name: r'rsvpListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RsvpListNotifierProvider call(String eventId) =>
      RsvpListNotifierProvider._(argument: eventId, from: this);

  @override
  String toString() => r'rsvpListProvider';
}

abstract class _$RsvpListNotifier extends $AsyncNotifier<List<Rsvp>> {
  late final _$args = ref.$arg as String;
  String get eventId => _$args;

  FutureOr<List<Rsvp>> build(String eventId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Rsvp>>, List<Rsvp>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Rsvp>>, List<Rsvp>>,
              AsyncValue<List<Rsvp>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
