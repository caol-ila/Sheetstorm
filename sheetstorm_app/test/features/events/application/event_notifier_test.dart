import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/events/application/event_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/data/services/event_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockEventService extends Mock implements EventService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Event _event({
  String id = 'evt1',
  String title = 'Frühjahrskonzert',
  EventType type = EventType.konzert,
  RsvpStatus myRsvpStatus = RsvpStatus.offen,
}) =>
    Event(
      id: id,
      bandId: 'band1',
      title: title,
      type: type,
      date: DateTime(2025, 5, 1),
      startTime: '19:00',
      createdAt: DateTime(2025, 1, 1),
      createdByName: 'Max',
      statistics: const EventStatistics(
        zugesagt: 5,
        abgesagt: 2,
        unsicher: 1,
        offen: 2,
      ),
      myRsvpStatus: myRsvpStatus,
    );

Rsvp _rsvp({
  String id = 'rsvp1',
  String memberName = 'Max Mustermann',
  RsvpStatus status = RsvpStatus.zugesagt,
}) =>
    Rsvp(
      id: id,
      eventId: 'evt1',
      memberId: 'u1',
      memberName: memberName,
      status: status,
      submittedAt: DateTime(2025, 1, 15),
    );

(ProviderContainer, EventListNotifier, MockEventService) _setupList() {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final service = MockEventService();
  container.updateOverrides([
    eventServiceProvider.overrideWithValue(service),
  ]);

  final notifier = container.read(eventListProvider().notifier);
  return (container, notifier, service);
}

(ProviderContainer, EventDetailNotifier, MockEventService) _setupDetail(
    String eventId) {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final service = MockEventService();
  container.updateOverrides([
    eventServiceProvider.overrideWithValue(service),
  ]);

  final notifier = container.read(eventDetailProvider(eventId).notifier);
  return (container, notifier, service);
}

(ProviderContainer, RsvpListNotifier, MockEventService) _setupRsvpList(
    String eventId) {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final service = MockEventService();
  container.updateOverrides([
    eventServiceProvider.overrideWithValue(service),
  ]);

  final notifier = container.read(rsvpListProvider(eventId).notifier);
  return (container, notifier, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(EventType.konzert);
    registerFallbackValue(RsvpStatus.offen);
    registerFallbackValue(DateTime(2025, 1, 1));
  });

  // ─── EventListNotifier — CRUD ─────────────────────────────────────────────

  group('EventListNotifier — Event erstellen', () {
    test('Event wird erstellt und zur Liste hinzugefügt', () async {
      final (c, n, service) = _setupList();
      final newEvent = _event(id: 'new1', title: 'Neues Konzert');

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      when(() => service.createEvent(
            bandId: 'band1',
            title: 'Neues Konzert',
            type: EventType.konzert,
            date: any(named: 'date'),
            startTime: '19:00',
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
            recurring: any(named: 'recurring'),
            recurringWeeks: any(named: 'recurringWeeks'),
          )).thenAnswer((_) async => newEvent);

      await c.read(eventListProvider().future);

      final result = await n.createEvent(
        bandId: 'band1',
        title: 'Neues Konzert',
        type: EventType.konzert,
        date: DateTime(2025, 6, 1),
        startTime: '19:00',
      );

      expect(result, isNotNull);
      expect(result?.title, 'Neues Konzert');

      final state = c.read(eventListProvider()).value;
      expect(state, isNotNull);
      expect(state!.any((e) => e.id == 'new1'), isTrue);
    });

    test('Fehler bei Erstellung setzt AsyncError', () async {
      final (c, n, service) = _setupList();

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      when(() => service.createEvent(
            bandId: any(named: 'bandId'),
            title: any(named: 'title'),
            type: any(named: 'type'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
            recurring: any(named: 'recurring'),
            recurringWeeks: any(named: 'recurringWeeks'),
          )).thenThrow(Exception('API error'));

      await c.read(eventListProvider().future);

      final result = await n.createEvent(
        bandId: 'band1',
        title: 'Fehler Event',
        type: EventType.probe,
        date: DateTime(2025, 6, 1),
        startTime: '18:00',
      );

      expect(result, isNull);
      expect(c.read(eventListProvider()).hasError, isTrue);
    });
  });

  group('EventListNotifier — Event löschen', () {
    test('Event wird aus Liste entfernt', () async {
      final (c, n, service) = _setupList();
      final events = [
        _event(id: 'evt1', title: 'Event 1'),
        _event(id: 'evt2', title: 'Event 2'),
      ];

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => events);

      when(() => service.deleteEvent('evt1')).thenAnswer((_) async => {});

      await c.read(eventListProvider().future);

      final success = await n.deleteEvent('evt1');

      expect(success, isTrue);
      final state = c.read(eventListProvider()).value;
      expect(state?.length, 1);
      expect(state?.first.id, 'evt2');
    });

    test('Fehler beim Löschen setzt AsyncError', () async {
      final (c, n, service) = _setupList();
      final events = [_event(id: 'evt1')];

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => events);

      when(() => service.deleteEvent('evt1'))
          .thenThrow(Exception('Delete failed'));

      await c.read(eventListProvider().future);

      final success = await n.deleteEvent('evt1');

      expect(success, isFalse);
      expect(c.read(eventListProvider()).hasError, isTrue);
    });
  });

  // ─── EventDetailNotifier — Details & Updates ─────────────────────────────

  group('EventDetailNotifier — Details laden', () {
    test('Event-Details werden geladen', () async {
      final (c, n, service) = _setupDetail('evt1');
      final event = _event(id: 'evt1', title: 'Testkonzert');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => event);

      await c.read(eventDetailProvider('evt1').future);

      final state = c.read(eventDetailProvider('evt1')).value;
      expect(state?.title, 'Testkonzert');
    });
  });

  group('EventDetailNotifier — Event aktualisieren', () {
    test('Event-Titel wird aktualisiert', () async {
      final (c, n, service) = _setupDetail('evt1');
      final original = _event(id: 'evt1', title: 'Alter Titel');
      final updated = _event(id: 'evt1', title: 'Neuer Titel');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => original);
      when(() => service.updateEvent(
            'evt1',
            title: 'Neuer Titel',
            type: any(named: 'type'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
          )).thenAnswer((_) async => updated);

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.updateEvent(title: 'Neuer Titel');

      expect(success, isTrue);
      final state = c.read(eventDetailProvider('evt1')).value;
      expect(state?.title, 'Neuer Titel');
    });

    test('Fehler bei Aktualisierung setzt AsyncError', () async {
      final (c, n, service) = _setupDetail('evt1');
      final original = _event(id: 'evt1');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => original);
      when(() => service.updateEvent(
            any(),
            title: any(named: 'title'),
            type: any(named: 'type'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
          )).thenThrow(Exception('Update failed'));

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.updateEvent(title: 'Neuer Titel');

      expect(success, isFalse);
      expect(c.read(eventDetailProvider('evt1')).hasError, isTrue);
    });
  });

  // ─── EventDetailNotifier — RSVP ──────────────────────────────────────────

  group('EventDetailNotifier — RSVP absenden', () {
    test('RSVP mit Zusage wird abgesendet', () async {
      final (c, n, service) = _setupDetail('evt1');
      final event = _event(
        id: 'evt1',
        myRsvpStatus: RsvpStatus.offen,
      );

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => event);
      when(() => service.submitRsvp(
            'evt1',
            status: RsvpStatus.zugesagt,
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => {});

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.submitRsvp(status: RsvpStatus.zugesagt);

      expect(success, isTrue);
      verify(() => service.submitRsvp(
            'evt1',
            status: RsvpStatus.zugesagt,
            reason: any(named: 'reason'),
          )).called(1);
    });

    test('RSVP mit Absage und Grund wird abgesendet', () async {
      final (c, n, service) = _setupDetail('evt1');
      final event = _event(id: 'evt1');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => event);
      when(() => service.submitRsvp(
            'evt1',
            status: RsvpStatus.abgesagt,
            reason: 'Urlaub',
          )).thenAnswer((_) async => {});

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.submitRsvp(
        status: RsvpStatus.abgesagt,
        reason: 'Urlaub',
      );

      expect(success, isTrue);
      verify(() => service.submitRsvp(
            'evt1',
            status: RsvpStatus.abgesagt,
            reason: 'Urlaub',
          )).called(1);
    });

    test('RSVP mit Unsicher-Status', () async {
      final (c, n, service) = _setupDetail('evt1');
      final event = _event(id: 'evt1');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => event);
      when(() => service.submitRsvp(
            'evt1',
            status: RsvpStatus.unsicher,
            reason: any(named: 'reason'),
          )).thenAnswer((_) async => {});

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.submitRsvp(status: RsvpStatus.unsicher);

      expect(success, isTrue);
    });

    test('Fehler bei RSVP setzt AsyncError', () async {
      final (c, n, service) = _setupDetail('evt1');
      final event = _event(id: 'evt1');

      when(() => service.getEventDetail('evt1'))
          .thenAnswer((_) async => event);
      when(() => service.submitRsvp(
            'evt1',
            status: any(named: 'status'),
            reason: any(named: 'reason'),
          )).thenThrow(Exception('RSVP failed'));

      await c.read(eventDetailProvider('evt1').future);

      final success = await n.submitRsvp(status: RsvpStatus.zugesagt);

      expect(success, isFalse);
      expect(c.read(eventDetailProvider('evt1')).hasError, isTrue);
    });
  });

  // ─── RsvpListNotifier — RSVP-Liste ───────────────────────────────────────

  group('RsvpListNotifier — Liste laden', () {
    test('RSVPs werden geladen', () async {
      final (c, n, service) = _setupRsvpList('evt1');
      final rsvps = [
        _rsvp(id: 'r1', memberName: 'Max', status: RsvpStatus.zugesagt),
        _rsvp(id: 'r2', memberName: 'Anna', status: RsvpStatus.abgesagt),
      ];

      when(() => service.getRsvps('evt1')).thenAnswer((_) async => rsvps);

      await c.read(rsvpListProvider('evt1').future);

      final state = c.read(rsvpListProvider('evt1')).value;
      expect(state?.length, 2);
    });
  });

  group('RsvpListNotifier — Nach Status filtern', () {
    test('filterByStatus() zeigt nur Zusagen', () async {
      final (c, n, service) = _setupRsvpList('evt1');
      final rsvps = [
        _rsvp(id: 'r1', status: RsvpStatus.zugesagt),
        _rsvp(id: 'r2', status: RsvpStatus.abgesagt),
        _rsvp(id: 'r3', status: RsvpStatus.zugesagt),
      ];

      when(() => service.getRsvps('evt1')).thenAnswer((_) async => rsvps);

      await c.read(rsvpListProvider('evt1').future);

      final zusagen = n.filterByStatus(RsvpStatus.zugesagt);

      expect(zusagen.length, 2);
      expect(zusagen.every((r) => r.status == RsvpStatus.zugesagt), isTrue);
    });

    test('filterByStatus() zeigt nur Absagen', () async {
      final (c, n, service) = _setupRsvpList('evt1');
      final rsvps = [
        _rsvp(id: 'r1', status: RsvpStatus.zugesagt),
        _rsvp(id: 'r2', status: RsvpStatus.abgesagt),
      ];

      when(() => service.getRsvps('evt1')).thenAnswer((_) async => rsvps);

      await c.read(rsvpListProvider('evt1').future);

      final absagen = n.filterByStatus(RsvpStatus.abgesagt);

      expect(absagen.length, 1);
      expect(absagen.first.status, RsvpStatus.abgesagt);
    });

    test('filterByStatus() mit leerem Ergebnis', () async {
      final (c, n, service) = _setupRsvpList('evt1');
      final rsvps = [
        _rsvp(id: 'r1', status: RsvpStatus.zugesagt),
      ];

      when(() => service.getRsvps('evt1')).thenAnswer((_) async => rsvps);

      await c.read(rsvpListProvider('evt1').future);

      final unsicher = n.filterByStatus(RsvpStatus.unsicher);

      expect(unsicher, isEmpty);
    });
  });

  // ─── Event Typen ──────────────────────────────────────────────────────────

  group('EventListNotifier — Event-Typen', () {
    test('Probe-Events werden erstellt', () async {
      final (c, n, service) = _setupList();
      final probe = _event(id: 'p1', title: 'Probe', type: EventType.probe);

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      when(() => service.createEvent(
            bandId: any(named: 'bandId'),
            title: any(named: 'title'),
            type: EventType.probe,
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
            recurring: any(named: 'recurring'),
            recurringWeeks: any(named: 'recurringWeeks'),
          )).thenAnswer((_) async => probe);

      await c.read(eventListProvider().future);

      final result = await n.createEvent(
        bandId: 'band1',
        title: 'Probe',
        type: EventType.probe,
        date: DateTime(2025, 6, 1),
        startTime: '19:00',
      );

      expect(result?.type, EventType.probe);
    });

    test('Ausflug-Events werden erstellt', () async {
      final (c, n, service) = _setupList();
      final ausflug =
          _event(id: 'a1', title: 'Ausflug', type: EventType.ausflug);

      when(() => service.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => []);

      when(() => service.createEvent(
            bandId: any(named: 'bandId'),
            title: any(named: 'title'),
            type: EventType.ausflug,
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            location: any(named: 'location'),
            meetingPoint: any(named: 'meetingPoint'),
            description: any(named: 'description'),
            setlistId: any(named: 'setlistId'),
            dressCode: any(named: 'dressCode'),
            rsvpDeadline: any(named: 'rsvpDeadline'),
            recurring: any(named: 'recurring'),
            recurringWeeks: any(named: 'recurringWeeks'),
          )).thenAnswer((_) async => ausflug);

      await c.read(eventListProvider().future);

      final result = await n.createEvent(
        bandId: 'band1',
        title: 'Ausflug',
        type: EventType.ausflug,
        date: DateTime(2025, 7, 15),
        startTime: '10:00',
      );

      expect(result?.type, EventType.ausflug);
    });
  });
}
