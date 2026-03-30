import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';

/// Unit-Tests für Setlist.copyWith Sentinel-Pattern — Issue #101
void main() {
  SetlistCreator _creator() => const SetlistCreator(
        id: 'user-1',
        name: 'Max Mustermann',
      );

  Setlist _setlist({
    String? datum = '2025-06-15',
    String? startzeit = '18:00',
    String? beschreibung = 'Sommerkonzert',
  }) =>
      Setlist(
        id: 'sl-1',
        name: 'Sommerkonzert 2025',
        typ: SetlistTyp.konzert,
        datum: datum,
        startzeit: startzeit,
        beschreibung: beschreibung,
        erstelltVon: _creator(),
        erstelltAm: DateTime(2025, 1, 1),
        aktualisiertAm: DateTime(2025, 1, 1),
      );

  group('Setlist.copyWith — Sentinel-Pattern (#101)', () {
    // ── datum ─────────────────────────────────────────────────────────────

    test('datum kann auf null gesetzt werden', () {
      final sl = _setlist(datum: '2025-06-15');
      final updated = sl.copyWith(datum: null);
      expect(updated.datum, isNull,
          reason: 'copyWith(datum: null) muss null setzen');
    });

    test('datum bleibt erhalten wenn nicht übergeben', () {
      final sl = _setlist(datum: '2025-06-15');
      final updated = sl.copyWith(name: 'Neuer Name');
      expect(updated.datum, '2025-06-15');
    });

    test('datum kann auf neuen Wert gesetzt werden', () {
      final sl = _setlist(datum: '2025-06-15');
      final updated = sl.copyWith(datum: '2025-07-20');
      expect(updated.datum, '2025-07-20');
    });

    // ── startzeit ─────────────────────────────────────────────────────────

    test('startzeit kann auf null gesetzt werden', () {
      final sl = _setlist(startzeit: '18:00');
      final updated = sl.copyWith(startzeit: null);
      expect(updated.startzeit, isNull,
          reason: 'copyWith(startzeit: null) muss null setzen');
    });

    test('startzeit bleibt erhalten wenn nicht übergeben', () {
      final sl = _setlist(startzeit: '18:00');
      final updated = sl.copyWith(name: 'Neuer Name');
      expect(updated.startzeit, '18:00');
    });

    // ── beschreibung ──────────────────────────────────────────────────────

    test('beschreibung kann auf null gesetzt werden', () {
      final sl = _setlist(beschreibung: 'Sommerkonzert');
      final updated = sl.copyWith(beschreibung: null);
      expect(updated.beschreibung, isNull,
          reason: 'copyWith(beschreibung: null) muss null setzen');
    });

    test('beschreibung bleibt erhalten wenn nicht übergeben', () {
      final sl = _setlist(beschreibung: 'Sommerkonzert');
      final updated = sl.copyWith(name: 'Neuer Name');
      expect(updated.beschreibung, 'Sommerkonzert');
    });

    // ── Kombinationen ─────────────────────────────────────────────────────

    test('Alle nullable Felder können gleichzeitig auf null gesetzt werden',
        () {
      final sl = _setlist(datum: '2025-06-15', startzeit: '18:00', beschreibung: 'Text');
      final updated = sl.copyWith(datum: null, startzeit: null, beschreibung: null);
      expect(updated.datum, isNull);
      expect(updated.startzeit, isNull);
      expect(updated.beschreibung, isNull);
    });

    test('Non-nullable Felder bleiben unverändert bei null-Reset', () {
      final sl = _setlist(datum: '2025-06-15');
      final updated = sl.copyWith(datum: null);
      expect(updated.id, sl.id);
      expect(updated.name, sl.name);
      expect(updated.typ, sl.typ);
    });
  });
}
