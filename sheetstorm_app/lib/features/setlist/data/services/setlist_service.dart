import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'setlist_service.g.dart';

@Riverpod(keepAlive: true)
SetlistService setlistService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return SetlistService(dio);
}

/// HTTP layer for Setlist endpoints.
class SetlistService {
  final Dio _dio;

  SetlistService(this._dio);

  String _base(String bandId) => '/api/v1/kapellen/$bandId/setlists';

  // ─── Setlist CRUD ──────────────────────────────────────────────────────────

  Future<SetlistPage> getSetlists(
    String bandId, {
    String? cursor,
    int limit = 30,
    SetlistTyp? typ,
    String? datumVon,
    String? datumBis,
    String? suche,
    String? sortierung,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _base(bandId),
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        if (typ != null) 'typ': typ.toJson(),
        if (datumVon != null) 'datum_von': datumVon,
        if (datumBis != null) 'datum_bis': datumBis,
        if (suche != null) 'suche': suche,
        if (sortierung != null) 'sortierung': sortierung,
      },
    );
    return SetlistPage.fromJson(res.data!);
  }

  Future<Setlist> getSetlist(String bandId, String setlistId) async {
    final res = await _dio
        .get<Map<String, dynamic>>('${_base(bandId)}/$setlistId');
    return Setlist.fromJson(res.data!);
  }

  Future<Setlist> createSetlist(
    String bandId, {
    required String name,
    required SetlistTyp typ,
    String? datum,
    String? startzeit,
    String? beschreibung,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      _base(bandId),
      data: {
        'name': name,
        'typ': typ.toJson(),
        if (datum != null) 'datum': datum,
        if (startzeit != null) 'startzeit': startzeit,
        if (beschreibung != null) 'beschreibung': beschreibung,
      },
    );
    return Setlist.fromJson(res.data!);
  }

  Future<Setlist> updateSetlist(
    String bandId,
    String setlistId, {
    String? name,
    SetlistTyp? typ,
    String? datum,
    String? startzeit,
    String? beschreibung,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId',
      data: {
        if (name != null) 'name': name,
        if (typ != null) 'typ': typ.toJson(),
        if (datum != null) 'datum': datum,
        if (startzeit != null) 'startzeit': startzeit,
        if (beschreibung != null) 'beschreibung': beschreibung,
      },
    );
    return Setlist.fromJson(res.data!);
  }

  Future<void> deleteSetlist(String bandId, String setlistId) async {
    await _dio.delete<void>('${_base(bandId)}/$setlistId');
  }

  // ─── Einträge ──────────────────────────────────────────────────────────────

  Future<SetlistEntry> addStueck(
    String bandId,
    String setlistId, {
    required String stueckId,
    int? geschaetzteDauerSekunden,
    int? position,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege',
      data: {
        'typ': 'stueck',
        'stueck_id': stueckId,
        if (geschaetzteDauerSekunden != null)
          'geschaetzte_dauer_sekunden': geschaetzteDauerSekunden,
        if (position != null) 'position': position,
      },
    );
    return SetlistEntry.fromJson(res.data!);
  }

  Future<SetlistEntry> addPlatzhalter(
    String bandId,
    String setlistId, {
    required String titel,
    String? komponist,
    String? notizen,
    int? geschaetzteDauerSekunden,
    int? position,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege',
      data: {
        'typ': 'platzhalter',
        'platzhalter': {
          'titel': titel,
          if (komponist != null) 'komponist': komponist,
          if (notizen != null) 'notizen': notizen,
        },
        if (geschaetzteDauerSekunden != null)
          'geschaetzte_dauer_sekunden': geschaetzteDauerSekunden,
        if (position != null) 'position': position,
      },
    );
    return SetlistEntry.fromJson(res.data!);
  }

  Future<SetlistEntry> addPause(
    String bandId,
    String setlistId, {
    String titel = 'Pause',
    required int dauerSekunden,
    int? position,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege',
      data: {
        'typ': 'pause',
        'pause': {
          'titel': titel,
          'dauer_sekunden': dauerSekunden,
        },
        if (position != null) 'position': position,
      },
    );
    return SetlistEntry.fromJson(res.data!);
  }

  Future<SetlistEntry> updateEntry(
    String bandId,
    String setlistId,
    String entryId, {
    PlatzhalterInfo? platzhalter,
    PauseInfo? pause,
    int? geschaetzteDauerSekunden,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege/$entryId',
      data: {
        if (platzhalter != null) 'platzhalter': platzhalter.toJson(),
        if (pause != null) 'pause': pause.toJson(),
        if (geschaetzteDauerSekunden != null)
          'geschaetzte_dauer_sekunden': geschaetzteDauerSekunden,
      },
    );
    return SetlistEntry.fromJson(res.data!);
  }

  Future<void> deleteEntry(
    String bandId,
    String setlistId,
    String entryId,
  ) async {
    await _dio
        .delete<void>('${_base(bandId)}/$setlistId/eintraege/$entryId');
  }

  // ─── Reorder ───────────────────────────────────────────────────────────────

  Future<void> reorderEntries(
    String bandId,
    String setlistId,
    List<({String id, int position})> positionen,
  ) async {
    await _dio.patch<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege/positionen',
      data: {
        'positionen': positionen
            .map((p) => {'id': p.id, 'position': p.position})
            .toList(),
      },
    );
  }

  // ─── Duplizieren ───────────────────────────────────────────────────────────

  Future<Setlist> duplicateSetlist(
    String bandId,
    String setlistId, {
    String? name,
    String? datum,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/duplizieren',
      data: {
        if (name != null) 'name': name,
        if (datum != null) 'datum': datum,
      },
    );
    return Setlist.fromJson(res.data!);
  }

  // ─── Platzhalter → Stück ──────────────────────────────────────────────────

  Future<SetlistEntry> convertToStueck(
    String bandId,
    String setlistId,
    String entryId,
    String stueckId,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/eintraege/$entryId/in-stueck-umwandeln',
      data: {'stueck_id': stueckId},
    );
    return SetlistEntry.fromJson(res.data!);
  }

  // ─── Spielmodus ────────────────────────────────────────────────────────────

  Future<SpielmodusData> getSpielmodusDaten(
    String bandId,
    String setlistId, {
    String? stimmeId,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '${_base(bandId)}/$setlistId/spielmodus',
      queryParameters: {
        if (stimmeId != null) 'stimme_id': stimmeId,
      },
    );
    return SpielmodusData.fromJson(res.data!);
  }
}
