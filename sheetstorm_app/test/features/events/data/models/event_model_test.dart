import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

/// Unit-Tests für Event.fromJson Null-Sicherheit und copyWith Sentinel — Issue #104, #101
void main() {
  group('Event.fromJson — Null-Sicherheit (#104)', () {
    test('stürzt nicht ab wenn erstellt_von fehlt', () {
      // RED: Wirft aktuell einen Cast-Fehler:
      //   "Null check operator used on a null value" bei
      //   (json['erstellt_von'] as Map<String, dynamic>)['name']
      // GREEN: Gibt '' zurück nach der Korrektur
      final json = <String, dynamic>{
        'id': 'evt-null-test',
        'kapelle_id': 'band-1',
        'titel': 'Nulltest Konzert',
        'typ': 'Konzert',
        'datum': '2025-05-01',
        'start_uhrzeit': '19:00',
        'erstellt_am': '2025-01-01T00:00:00.000Z',
        'statistik': {
          'zugesagt': 5,
          'abgesagt': 2,
          'unsicher': 1,
          'offen': 2,
        },
        // 'erstellt_von' absichtlich weggelassen
      };

      expect(
        () => Event.fromJson(json),
        returnsNormally,
        reason: 'Event.fromJson darf bei fehlendem erstellt_von nicht abstürzen',
      );
      final event = Event.fromJson(json);
      expect(event.id, 'evt-null-test');
      expect(
        event.createdByName,
        isEmpty,
        reason: 'createdByName soll leer sein wenn erstellt_von fehlt',
      );
    });

    test('stürzt nicht ab wenn statistik fehlt', () {
      // RED: Wirft aktuell einen Cast-Fehler bei
      //   EventStatistics.fromJson(null as Map<String, dynamic>)
      // GREEN: Gibt Standard-Statistik zurück nach der Korrektur
      final json = <String, dynamic>{
        'id': 'evt-no-stats',
        'kapelle_id': 'band-1',
        'titel': 'Probe ohne Statistik',
        'typ': 'Probe',
        'datum': '2025-06-01',
        'start_uhrzeit': '18:00',
        'erstellt_am': '2025-01-01T00:00:00.000Z',
        // 'statistik' absichtlich weggelassen
        // 'erstellt_von' absichtlich weggelassen
      };

      expect(
        () => Event.fromJson(json),
        returnsNormally,
        reason: 'Event.fromJson darf bei fehlender statistik nicht abstürzen',
      );
      final event = Event.fromJson(json);
      expect(event.statistics.total, 0,
          reason: 'Statistik soll auf 0 defaulten');
    });

    test('parst korrekt wenn alle Felder vorhanden', () {
      final json = <String, dynamic>{
        'id': 'evt-full',
        'kapelle_id': 'band-1',
        'titel': 'Vollständiges Konzert',
        'typ': 'Konzert',
        'datum': '2025-05-01',
        'start_uhrzeit': '20:00',
        'erstellt_am': '2025-01-01T00:00:00.000Z',
        'erstellt_von': {'id': 'u1', 'name': 'Max Dirigent'},
        'statistik': {
          'zugesagt': 10,
          'abgesagt': 2,
          'unsicher': 3,
          'offen': 5,
        },
      };

      final event = Event.fromJson(json);
      expect(event.createdByName, 'Max Dirigent');
      expect(event.statistics.zugesagt, 10);
      expect(event.statistics.total, 20);
    });

    test('parst meine_teilnahme korrekt wenn vorhanden', () {
      final json = <String, dynamic>{
        'id': 'evt-rsvp',
        'kapelle_id': 'band-1',
        'titel': 'Konzert mit RSVP',
        'typ': 'Konzert',
        'datum': '2025-05-01',
        'start_uhrzeit': '20:00',
        'erstellt_am': '2025-01-01T00:00:00.000Z',
        'meine_teilnahme': 'Zugesagt',
      };

      final event = Event.fromJson(json);
      expect(event.myRsvpStatus, RsvpStatus.zugesagt);
    });

    test('setzt meine_teilnahme auf offen wenn nicht vorhanden', () {
      final json = <String, dynamic>{
        'id': 'evt-no-rsvp',
        'kapelle_id': 'band-1',
        'titel': 'Konzert ohne RSVP',
        'typ': 'Konzert',
        'datum': '2025-05-01',
        'start_uhrzeit': '20:00',
        'erstellt_am': '2025-01-01T00:00:00.000Z',
        // 'meine_teilnahme' weggelassen
      };

      final event = Event.fromJson(json);
      expect(event.myRsvpStatus, RsvpStatus.offen);
    });
  });

  // ─── Event.copyWith — Sentinel-Pattern ────────────────────────────────────

  Event _eventWithOptionals() => Event(
        id: 'evt-1',
        bandId: 'band-1',
        title: 'Konzert',
        type: EventType.konzert,
        date: DateTime(2025, 6, 15),
        startTime: '20:00',
        endTime: '22:00',
        location: 'Markplatz',
        meetingPoint: 'Bühneneingang',
        description: 'Jahreskonzert',
        setlistId: 'sl-1',
        setlistName: 'Programm 2025',
        dressCode: 'Schwarze Tracht',
        rsvpDeadline: DateTime(2025, 6, 10),
        createdAt: DateTime(2025, 1, 1),
        createdByName: 'Max Dirigent',
        statistics: const EventStatistics(),
      );

  group('Event.copyWith — Sentinel-Pattern (#101)', () {
    test('setlistId kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(setlistId: null);
      expect(updated.setlistId, isNull,
          reason: 'copyWith(setlistId: null) muss null setzen');
    });

    test('setlistId bleibt erhalten wenn nicht übergeben', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(title: 'Neuer Titel');
      expect(updated.setlistId, 'sl-1');
    });

    test('setlistName kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(setlistName: null);
      expect(updated.setlistName, isNull);
    });

    test('rsvpDeadline kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(rsvpDeadline: null);
      expect(updated.rsvpDeadline, isNull,
          reason: 'Deadline soll löschbar sein');
    });

    test('rsvpDeadline bleibt erhalten wenn nicht übergeben', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(title: 'Neuer Titel');
      expect(updated.rsvpDeadline, DateTime(2025, 6, 10));
    });

    test('location kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(location: null);
      expect(updated.location, isNull);
    });

    test('meetingPoint kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(meetingPoint: null);
      expect(updated.meetingPoint, isNull);
    });

    test('description kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(description: null);
      expect(updated.description, isNull);
    });

    test('dressCode kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(dressCode: null);
      expect(updated.dressCode, isNull);
    });

    test('endTime kann auf null gesetzt werden', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(endTime: null);
      expect(updated.endTime, isNull);
    });

    test('endTime bleibt erhalten wenn nicht übergeben', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(title: 'Neuer Titel');
      expect(updated.endTime, '22:00');
    });

    test('Alle nullable Felder gleichzeitig auf null setzbar', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(
        endTime: null,
        location: null,
        meetingPoint: null,
        description: null,
        setlistId: null,
        setlistName: null,
        dressCode: null,
        rsvpDeadline: null,
      );
      expect(updated.endTime, isNull);
      expect(updated.location, isNull);
      expect(updated.meetingPoint, isNull);
      expect(updated.description, isNull);
      expect(updated.setlistId, isNull);
      expect(updated.setlistName, isNull);
      expect(updated.dressCode, isNull);
      expect(updated.rsvpDeadline, isNull);
    });

    test('Non-nullable Felder bleiben unverändert', () {
      final event = _eventWithOptionals();
      final updated = event.copyWith(setlistId: null);
      expect(updated.id, event.id);
      expect(updated.bandId, event.bandId);
      expect(updated.title, event.title);
    });
  });
}
