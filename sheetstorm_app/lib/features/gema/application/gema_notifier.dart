import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';
import 'package:sheetstorm/features/gema/data/services/gema_service.dart';

part 'gema_notifier.g.dart';

@Riverpod(keepAlive: true)
class GemaReportListNotifier extends _$GemaReportListNotifier {
  @override
  Future<List<GemaReport>> build(String kapelleId) async {
    final service = ref.read(gemaServiceProvider);
    return service.getReports(kapelleId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(gemaServiceProvider);
      return service.getReports(kapelleId);
    });
  }

  Future<GemaReport?> createReport({
    required String? setlistId,
    required String veranstaltungName,
    required DateTime veranstaltungDatum,
    required String veranstaltungOrt,
    required String veranstaltungArt,
    required String veranstalter,
  }) async {
    final service = ref.read(gemaServiceProvider);
    try {
      final report = await service.createReport(
        kapelleId: kapelleId,
        setlistId: setlistId,
        veranstaltungName: veranstaltungName,
        veranstaltungDatum: veranstaltungDatum,
        veranstaltungOrt: veranstaltungOrt,
        veranstaltungArt: veranstaltungArt,
        veranstalter: veranstalter,
      );
      final current = state.value ?? [];
      state = AsyncData([report, ...current]);
      return report;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteReport(String reportId) async {
    final service = ref.read(gemaServiceProvider);
    try {
      await service.deleteReport(
        kapelleId: kapelleId,
        reportId: reportId,
      );
      final current = state.value ?? [];
      state = AsyncData(current.where((r) => r.id != reportId).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

@riverpod
class GemaReportDetailNotifier extends _$GemaReportDetailNotifier {
  @override
  Future<GemaReport> build(String kapelleId, String reportId) async {
    final service = ref.read(gemaServiceProvider);
    return service.getReportDetail(kapelleId, reportId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(gemaServiceProvider);
      return service.getReportDetail(kapelleId, reportId);
    });
  }

  Future<bool> updateEvent({
    String? veranstaltungName,
    DateTime? veranstaltungDatum,
    String? veranstaltungOrt,
    String? veranstaltungArt,
    String? veranstalter,
  }) async {
    final service = ref.read(gemaServiceProvider);
    try {
      final updated = await service.updateReport(
        kapelleId: kapelleId,
        reportId: reportId,
        veranstaltungName: veranstaltungName,
        veranstaltungDatum: veranstaltungDatum,
        veranstaltungOrt: veranstaltungOrt,
        veranstaltungArt: veranstaltungArt,
        veranstalter: veranstalter,
      );
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> addEntry({
    required String werktitel,
    required String komponist,
    String? verlag,
    String? gemaWerknummer,
    String? bearbeiter,
    int? dauerSekunden,
  }) async {
    final service = ref.read(gemaServiceProvider);
    try {
      await service.addEntry(
        kapelleId: kapelleId,
        reportId: reportId,
        werktitel: werktitel,
        komponist: komponist,
        verlag: verlag,
        gemaWerknummer: gemaWerknummer,
        bearbeiter: bearbeiter,
        dauerSekunden: dauerSekunden,
      );
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateEntry({
    required String entryId,
    String? werktitel,
    String? komponist,
    String? verlag,
    String? gemaWerknummer,
    String? bearbeiter,
    int? dauerSekunden,
  }) async {
    final service = ref.read(gemaServiceProvider);
    try {
      await service.updateEntry(
        kapelleId: kapelleId,
        reportId: reportId,
        entryId: entryId,
        werktitel: werktitel,
        komponist: komponist,
        verlag: verlag,
        gemaWerknummer: gemaWerknummer,
        bearbeiter: bearbeiter,
        dauerSekunden: dauerSekunden,
      );
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> deleteEntry(String entryId) async {
    final service = ref.read(gemaServiceProvider);
    try {
      await service.deleteEntry(
        kapelleId: kapelleId,
        reportId: reportId,
        entryId: entryId,
      );
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<List<GemaWerknummerVorschlag>> searchWerknummer(String entryId) async {
    final service = ref.read(gemaServiceProvider);
    return service.searchWerknummer(
      kapelleId: kapelleId,
      reportId: reportId,
      entryId: entryId,
    );
  }

  Future<Map<String, List<GemaWerknummerVorschlag>>>
      searchAllWerknummern() async {
    final service = ref.read(gemaServiceProvider);
    return service.searchAllWerknummern(
      kapelleId: kapelleId,
      reportId: reportId,
    );
  }

  Future<String?> exportReport(ExportFormat format) async {
    final service = ref.read(gemaServiceProvider);
    try {
      final url = await service.exportReport(
        kapelleId: kapelleId,
        reportId: reportId,
        format: format,
      );
      await refresh();
      return url;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}
