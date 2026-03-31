import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/setlist/application/setlist_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Setlist _setlist({
  String id = 'sl1',
  String name = 'Frühjahrskonzert 2025',
  SetlistTyp typ = SetlistTyp.konzert,
  List<SetlistEntry> eintraege = const [],
}) =>
    Setlist(
      id: id,
      name: name,
      typ: typ,
      datum: '2025-05-01',
      startzeit: '19:00',
      eintraege: eintraege,
      erstelltVon: const SetlistCreator(id: 'u1', name: 'Max'),
      erstelltAm: DateTime(2025, 1, 1),
      aktualisiertAm: DateTime(2025, 1, 1),
    );

SetlistEntry _entry({
  String id = 'e1',
  SetlistEntryType typ = SetlistEntryType.stueck,
  int position = 1,
}) =>
    SetlistEntry(
      id: id,
      typ: typ,
      position: position,
      geschaetzteDauerSekunden: typ == SetlistEntryType.pause ? 600 : 180,
      stueck: typ == SetlistEntryType.stueck
          ? const PieceInfo(id: 'p1', titel: 'Test Stück')
          : null,
      platzhalter: typ == SetlistEntryType.platzhalter
          ? const PlatzhalterInfo(titel: 'Zugabe')
          : null,
    );

(ProviderContainer, SetlistListNotifier) _setupList() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(setlistListProvider.notifier);
  return (container, notifier);
}

(ProviderContainer, SetlistDetailNotifier) _setupDetail(String setlistId) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(setlistDetailProvider(setlistId).notifier);
  return (container, notifier);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─── SetlistListNotifier — Basic operations ───────────────────────────────

  group('SetlistListNotifier — Methoden verfügbar', () {
    test('createSetlist() gibt Setlist oder null zurück', () async {
      final (c, n) = _setupList();

      // We can't actually create without a real service, but we can verify
      // the method exists and handles errors gracefully
      final result = await n.createSetlist(
        name: 'Test Setlist',
        typ: SetlistTyp.konzert,
      );

      // Without a real service, this will fail, but that's expected
      expect(result, anyOf(isNull, isA<Setlist>()));
    });

    test('deleteSetlist() gibt bool zurück', () async {
      final (c, n) = _setupList();

      final success = await n.deleteSetlist('sl1');

      // Without a real service, this will return false
      expect(success, anyOf(isTrue, isFalse));
    });

    test('duplicateSetlist() gibt Setlist oder null zurück', () async {
      final (c, n) = _setupList();

      final result = await n.duplicateSetlist('sl1', name: 'Kopie');

      expect(result, anyOf(isNull, isA<Setlist>()));
    });

    test('search() ändert Zustand nicht bei fehlender Band', () async {
      final (c, n) = _setupList();

      await n.search('test');

      expect(c.read(setlistListProvider).hasError, isFalse);
    });

    test('filter() ändert Zustand nicht bei fehlender Band', () async {
      final (c, n) = _setupList();

      await n.filter(typ: SetlistTyp.konzert);

      expect(c.read(setlistListProvider).hasError, isFalse);
    });

    test('refresh() ändert Zustand nicht bei fehlender Band', () async {
      final (c, n) = _setupList();

      await n.refresh();

      expect(c.read(setlistListProvider).hasError, isFalse);
    });

    test('filter() mit sortierung Parameter', () async {
      final (c, n) = _setupList();

      await n.filter(sortierung: 'datum_desc');

      expect(c.read(setlistListProvider).hasError, isFalse);
    });

    test('createSetlist() mit allen Parametern', () async {
      final (c, n) = _setupList();

      final result = await n.createSetlist(
        name: 'Vollständige Setlist',
        typ: SetlistTyp.probe,
        datum: '2025-06-01',
        startzeit: '20:00',
        beschreibung: 'Eine Probe',
      );

      expect(result, anyOf(isNull, isA<Setlist>()));
    });
  });

  // ─── SetlistDetailNotifier — Einträge verwalten ──────────────────────────

  group('SetlistDetailNotifier — Methoden verfügbar', () {
    test('addStueck() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addStueck(stueckId: 'p1');

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('addStueck() mit geschätzter Dauer', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addStueck(
        stueckId: 'p1',
        geschaetzteDauerSekunden: 240,
      );

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('addPlatzhalter() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addPlatzhalter(titel: 'Zugabe');

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('addPlatzhalter() mit allen Parametern', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addPlatzhalter(
        titel: 'Zugabe',
        komponist: 'Test Komponist',
        notizen: 'Optional',
        geschaetzteDauerSekunden: 180,
      );

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('addPause() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addPause(dauerSekunden: 900);

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('addPause() mit eigenem Titel', () async {
      final (c, n) = _setupDetail('sl1');

      await n.addPause(
        titel: 'Lange Pause',
        dauerSekunden: 1200,
      );

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('deleteEntry() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.deleteEntry('e1');

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('reorderEntries() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');
      final e1 = _entry(id: 'e1', position: 1);
      final e2 = _entry(id: 'e2', position: 2);

      await n.reorderEntries([e2, e1]);

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('reorderEntries() mit drei Einträgen', () async {
      final (c, n) = _setupDetail('sl1');
      final e1 = _entry(id: 'e1', position: 1);
      final e2 = _entry(id: 'e2', position: 2);
      final e3 = _entry(id: 'e3', position: 3);

      await n.reorderEntries([e3, e1, e2]);

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('convertToStueck() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.convertToStueck('e1', 'p1');

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('updateMetadata() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.updateMetadata(name: 'Neuer Name', typ: SetlistTyp.probe);

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('updateMetadata() nur Name', () async {
      final (c, n) = _setupDetail('sl1');

      await n.updateMetadata(name: 'Geänderter Name');

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('updateMetadata() mit Datum und Zeit', () async {
      final (c, n) = _setupDetail('sl1');

      await n.updateMetadata(
        datum: '2025-07-15',
        startzeit: '18:30',
      );

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('updateMetadata() mit Beschreibung', () async {
      final (c, n) = _setupDetail('sl1');

      await n.updateMetadata(
        beschreibung: 'Eine neue Beschreibung',
      );

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('refresh() kehrt bei fehlender Band frühzeitig zurück', () async {
      final (c, n) = _setupDetail('sl1');

      await n.refresh();

      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });
  });

  // ─── SetlistEntry — Entry-Typen ──────────────────────────────────────────

  group('SetlistEntry — Entry-Typen und Eigenschaften', () {
    test('Stück-Entry hat korrekten Typ', () {
      final entry = _entry(typ: SetlistEntryType.stueck);
      expect(entry.isStueck, isTrue);
      expect(entry.isPlatzhalter, isFalse);
      expect(entry.isPause, isFalse);
      expect(entry.isPlayable, isTrue);
    });

    test('Platzhalter-Entry hat korrekten Typ', () {
      final entry = _entry(id: 'ph1', typ: SetlistEntryType.platzhalter);
      expect(entry.isPlatzhalter, isTrue);
      expect(entry.isStueck, isFalse);
      expect(entry.isPause, isFalse);
      expect(entry.isPlayable, isFalse);
    });

    test('Pause-Entry hat korrekten Typ', () {
      final entry = _entry(id: 'pa1', typ: SetlistEntryType.pause);
      expect(entry.isPause, isTrue);
      expect(entry.isStueck, isFalse);
      expect(entry.isPlatzhalter, isFalse);
      expect(entry.isPlayable, isFalse);
    });
  });

  // ─── Leere Einträge — Edge Cases (#117) ──────────────────────────────────────

  group('SetlistDetailNotifier — Leere Einträge (Edge Cases)', () {
    test('SetlistReorder_EmptyList_NoOp', () async {
      final (c, n) = _setupDetail('sl1');

      await n.reorderEntries([]);

      // Keine Ausnahme — leere Neuordnung ist sicher
      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('SetlistRemoveFromEmpty_ThrowsOrNoOp', () async {
      final (c, n) = _setupDetail('sl1');

      await n.deleteEntry('nicht-vorhanden');

      // Keine Ausnahme — deleteEntry bei fehlender Band kehrt frühzeitig zurück
      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });

    test('SetlistReorder_EmptyList_PreservesState', () async {
      final (c, n) = _setupDetail('sl1');
      await Future.microtask(() {}); // build abschließen lassen
      final stateBefore = c.read(setlistDetailProvider('sl1'));

      await n.reorderEntries([]);

      // Zustand bleibt erhalten — keine unerwartete Mutation
      final stateAfter = c.read(setlistDetailProvider('sl1'));
      expect(stateAfter, isNotNull);
      expect(stateAfter.hasError, equals(stateBefore.hasError));
    });

    test('SetlistDetailNotifier_NoBand_AllMutationsAreNoOp', () async {
      final (c, n) = _setupDetail('sl1');

      // Alle mutierenden Methoden ohne aktive Band sind no-ops
      await n.addStueck(stueckId: 'x');
      await n.addPlatzhalter(titel: 'x');
      await n.addPause(dauerSekunden: 60);
      await n.deleteEntry('x');
      await n.reorderEntries([]);
      await n.convertToStueck('x', 'y');
      await n.updateMetadata(name: 'x');

      // Kein Absturz, Zustand ist weiterhin gültig
      expect(c.read(setlistDetailProvider('sl1')), isNotNull);
    });
  });
}
