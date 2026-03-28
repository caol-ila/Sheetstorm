import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'gema_service.g.dart';

@Riverpod(keepAlive: true)
GemaService gemaService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return GemaService(dio);
}

class GemaService {
  final Dio _dio;

  GemaService(this._dio);

  Future<List<GemaReport>> getReports(String kapelleId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen',
    );
    return res.data!
        .map((e) => GemaReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GemaReport> getReportDetail(String kapelleId, String reportId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId',
    );
    return GemaReport.fromJson(res.data!);
  }

  Future<GemaReport> createReport({
    required String kapelleId,
    required String? setlistId,
    required String veranstaltungName,
    required DateTime veranstaltungDatum,
    required String veranstaltungOrt,
    required String veranstaltungArt,
    required String veranstalter,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen',
      data: {
        if (setlistId != null) 'setlistId': setlistId,
        'veranstaltung': {
          'name': veranstaltungName,
          'datum': veranstaltungDatum.toIso8601String().split('T')[0],
          'ort': veranstaltungOrt,
          'art': veranstaltungArt,
          'veranstalter': veranstalter,
        },
      },
    );
    return GemaReport.fromJson(res.data!);
  }

  Future<GemaReport> updateReport({
    required String kapelleId,
    required String reportId,
    String? veranstaltungName,
    DateTime? veranstaltungDatum,
    String? veranstaltungOrt,
    String? veranstaltungArt,
    String? veranstalter,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId',
      data: {
        'veranstaltung': {
          if (veranstaltungName != null) 'name': veranstaltungName,
          if (veranstaltungDatum != null)
            'datum': veranstaltungDatum.toIso8601String().split('T')[0],
          if (veranstaltungOrt != null) 'ort': veranstaltungOrt,
          if (veranstaltungArt != null) 'art': veranstaltungArt,
          if (veranstalter != null) 'veranstalter': veranstalter,
        },
      },
    );
    return GemaReport.fromJson(res.data!);
  }

  Future<GemaEntry> addEntry({
    required String kapelleId,
    required String reportId,
    required String werktitel,
    required String komponist,
    String? verlag,
    String? gemaWerknummer,
    String? bearbeiter,
    int? dauerSekunden,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/eintraege',
      data: {
        'werktitel': werktitel,
        'komponist': komponist,
        if (verlag != null) 'verlag': verlag,
        if (gemaWerknummer != null) 'gemaWerknummer': gemaWerknummer,
        if (bearbeiter != null) 'bearbeiter': bearbeiter,
        if (dauerSekunden != null) 'dauerSekunden': dauerSekunden,
      },
    );
    return GemaEntry.fromJson(res.data!);
  }

  Future<GemaEntry> updateEntry({
    required String kapelleId,
    required String reportId,
    required String entryId,
    String? werktitel,
    String? komponist,
    String? verlag,
    String? gemaWerknummer,
    String? bearbeiter,
    int? dauerSekunden,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/eintraege/$entryId',
      data: {
        if (werktitel != null) 'werktitel': werktitel,
        if (komponist != null) 'komponist': komponist,
        if (verlag != null) 'verlag': verlag,
        if (gemaWerknummer != null) 'gemaWerknummer': gemaWerknummer,
        if (bearbeiter != null) 'bearbeiter': bearbeiter,
        if (dauerSekunden != null) 'dauerSekunden': dauerSekunden,
      },
    );
    return GemaEntry.fromJson(res.data!);
  }

  Future<void> deleteEntry({
    required String kapelleId,
    required String reportId,
    required String entryId,
  }) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/eintraege/$entryId',
    );
  }

  Future<List<GemaWerknummerVorschlag>> searchWerknummer({
    required String kapelleId,
    required String reportId,
    required String entryId,
  }) async {
    final res = await _dio.post<List<dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/eintraege/$entryId/werknummer-suche',
    );
    return res.data!
        .map((e) =>
            GemaWerknummerVorschlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, List<GemaWerknummerVorschlag>>>
      searchAllWerknummern({
    required String kapelleId,
    required String reportId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/werknummer-suche-alle',
    );
    return res.data!.map((key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((e) =>
                  GemaWerknummerVorschlag.fromJson(e as Map<String, dynamic>))
              .toList(),
        ));
  }

  Future<String> exportReport({
    required String kapelleId,
    required String reportId,
    required ExportFormat format,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId/export',
      data: {'format': format.toJson()},
    );
    return res.data!['downloadUrl'] as String;
  }

  Future<void> deleteReport({
    required String kapelleId,
    required String reportId,
  }) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$kapelleId/gema-meldungen/$reportId',
    );
  }
}
