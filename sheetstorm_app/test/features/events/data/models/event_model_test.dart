import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

/// Unit-Tests für Event.fromJson Null-Sicherheit — Issue #104
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
}
