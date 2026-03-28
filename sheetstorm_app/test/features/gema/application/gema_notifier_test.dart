import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/gema/application/gema_notifier.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

GemaReport _report({
  String id = 'gr1',
  String veranstaltungName = 'Frühjahrskonzert',
  List<GemaEntry> eintraege = const [],
  GemaReportStatus status = GemaReportStatus.entwurf,
}) =>
    GemaReport(
      id: id,
      kapelleId: 'band1',
      status: status,
      veranstaltungName: veranstaltungName,
      veranstaltungDatum: DateTime(2025, 5, 1),
      veranstaltungOrt: 'Stadthalle',
      veranstaltungArt: 'Konzert',
      veranstalter: 'Musikverein',
      eintraege: eintraege,
      erstelltAm: DateTime(2025, 1, 1),
      erstelltVon: 'Max Mustermann',
    );

GemaEntry _entry({
  String id = 'ge1',
  String werktitel = 'Test Werk',
  String komponist = 'Test Komponist',
}) =>
    GemaEntry(
      id: id,
      meldungId: 'gr1',
      werktitel: werktitel,
      komponist: komponist,
      verlag: 'Musikverlag',
      gemaWerknummer: 'WN123456',
      dauerSekunden: 180,
    );

GemaWerknummerVorschlag _vorschlag({
  String werknummer = 'WN123456',
  String werktitel = 'Test Werk',
}) =>
    GemaWerknummerVorschlag(
      werknummer: werknummer,
      werktitel: werktitel,
      komponist: 'Komponist',
      verlag: 'Verlag',
      confidence: 0.9,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── GemaReportListNotifier — Provider ────────────────────────────────────

  group('GemaReportListNotifier — Provider', () {
    test('provider exists and initial state is AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(gemaReportListProvider('band1'));
      expect(state, isA<AsyncLoading<List<GemaReport>>>());
    });

    test('notifier can be read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier =
          container.read(gemaReportListProvider('band1').notifier);
      expect(notifier, isA<GemaReportListNotifier>());
    });
  });

  // ─── GemaReportDetailNotifier — Provider ──────────────────────────────────

  group('GemaReportDetailNotifier — Provider', () {
    test('provider exists and initial state is AsyncLoading', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state =
          container.read(gemaReportDetailProvider('band1', 'gr1'));
      expect(state, isA<AsyncLoading<GemaReport>>());
    });

    test('notifier can be read', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container
          .read(gemaReportDetailProvider('band1', 'gr1').notifier);
      expect(notifier, isA<GemaReportDetailNotifier>());
    });
  });

  // ─── GemaReport — Model Tests ─────────────────────────────────────────────

  group('GemaReport — Model', () {
    test('GemaReport model construction', () {
      final report = _report(id: 'gr1', veranstaltungName: 'Test');
      expect(report.id, 'gr1');
      expect(report.veranstaltungName, 'Test');
      expect(report.kapelleId, 'band1');
      expect(report.status, GemaReportStatus.entwurf);
    });

    test('GemaReport with entries', () {
      final entry = _entry(id: 'ge1', werktitel: 'Mein Werk');
      final report = _report(eintraege: [entry]);
      expect(report.eintraege.length, 1);
      expect(report.eintraege.first.werktitel, 'Mein Werk');
    });

    test('GemaEntry model construction', () {
      final entry = _entry(id: 'ge1', werktitel: 'Werk', komponist: 'Bach');
      expect(entry.id, 'ge1');
      expect(entry.werktitel, 'Werk');
      expect(entry.komponist, 'Bach');
      expect(entry.dauerSekunden, 180);
    });

    test('GemaWerknummerVorschlag model construction', () {
      final vorschlag = _vorschlag(werknummer: 'WN999', werktitel: 'Titel');
      expect(vorschlag.werknummer, 'WN999');
      expect(vorschlag.werktitel, 'Titel');
      expect(vorschlag.komponist, 'Komponist');
    });
  });

  // ─── Report Status & Export Format ────────────────────────────────────────

  group('GemaReport — Status und Export', () {
    test('GemaReportStatus values exist', () {
      expect(GemaReportStatus.entwurf, isNotNull);
    });

    test('ExportFormat values exist', () {
      expect(ExportFormat.xml, isNotNull);
      expect(ExportFormat.csv, isNotNull);
      expect(ExportFormat.pdf, isNotNull);
    });

    test('Report with Entwurf status', () {
      final report = _report(status: GemaReportStatus.entwurf);
      expect(report.status, GemaReportStatus.entwurf);
    });
  });
}
