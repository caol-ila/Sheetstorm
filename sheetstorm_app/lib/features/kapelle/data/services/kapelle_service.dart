import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'kapelle_service.g.dart';

@Riverpod(keepAlive: true)
KapelleService kapelleService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return KapelleService(dio);
}

/// HTTP layer for Kapellen endpoints.
class KapelleService {
  final Dio _dio;

  KapelleService(this._dio);

  // ─── Kapellen CRUD ──────────────────────────────────────────────────────────

  Future<List<Kapelle>> getKapellen() async {
    final res = await _dio.get<List<dynamic>>('/api/v1/kapellen');
    return res.data!
        .map((e) => Kapelle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Kapelle> getKapelleDetail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/kapellen/$id');
    return Kapelle.fromJson(res.data!);
  }

  Future<Kapelle> createKapelle({
    required String name,
    String? beschreibung,
    String? ort,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen',
      data: {
        'name': name,
        if (beschreibung != null) 'beschreibung': beschreibung,
        if (ort != null) 'ort': ort,
      },
    );
    return Kapelle.fromJson(res.data!);
  }

  Future<Kapelle> updateKapelle(
    String id, {
    String? name,
    String? beschreibung,
    String? ort,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/kapellen/$id',
      data: {
        if (name != null) 'name': name,
        if (beschreibung != null) 'beschreibung': beschreibung,
        if (ort != null) 'ort': ort,
      },
    );
    return Kapelle.fromJson(res.data!);
  }

  Future<void> deleteKapelle(String id) async {
    await _dio.delete<void>('/api/v1/kapellen/$id');
  }

  // ─── Mitglieder ─────────────────────────────────────────────────────────────

  Future<List<Mitglied>> getMitglieder(String kapelleId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/kapellen/$kapelleId/mitglieder');
    return res.data!
        .map((e) => Mitglied.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Mitglied> updateMemberRoles(
    String kapelleId,
    String musikerId,
    List<KapelleRolle> rollen,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/mitglieder/$musikerId/rollen',
      data: {'rollen': rollen.map((r) => r.toJson()).toList()},
    );
    return Mitglied.fromJson(res.data!);
  }

  Future<void> removeMember(String kapelleId, String musikerId) async {
    await _dio
        .delete<void>('/api/v1/kapellen/$kapelleId/mitglieder/$musikerId');
  }

  Future<void> leaveKapelle(String kapelleId) async {
    await _dio.post<void>('/api/v1/kapellen/$kapelleId/verlassen');
  }

  // ─── Einladungen ────────────────────────────────────────────────────────────

  Future<List<Einladung>> getEinladungen(String kapelleId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/kapellen/$kapelleId/einladungen');
    return res.data!
        .map((e) => Einladung.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Einladung> createEmailEinladung(
    String kapelleId,
    String email,
    KapelleRolle rolle, {
    int ablaufTage = 7,
    String? nachricht,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/einladungen',
      data: {
        'typ': 'email',
        'email': email,
        'rolle': rolle.toJson(),
        'ablauf_tage': ablaufTage,
        if (nachricht != null) 'nachricht': nachricht,
      },
    );
    return Einladung.fromJson(res.data!);
  }

  Future<Einladung> createLinkEinladung(
    String kapelleId,
    KapelleRolle rolle, {
    int ablaufTage = 7,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/einladungen',
      data: {
        'typ': 'link',
        'rolle': rolle.toJson(),
        'ablauf_tage': ablaufTage,
      },
    );
    return Einladung.fromJson(res.data!);
  }

  Future<void> revokeEinladung(String kapelleId, String einladungId) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$kapelleId/einladungen/$einladungId',
    );
  }

  Future<void> acceptEinladung(String token) async {
    await _dio.post<void>('/api/v1/einladungen/$token/annehmen');
  }

  // ─── Register ───────────────────────────────────────────────────────────────

  Future<List<Register>> getRegister(String kapelleId) async {
    final res = await _dio
        .get<List<dynamic>>('/api/v1/kapellen/$kapelleId/register');
    return res.data!
        .map((e) => Register.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Register> createRegister(
    String kapelleId,
    String name, {
    String? beschreibung,
    String? farbe,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/register',
      data: {
        'name': name,
        if (beschreibung != null) 'beschreibung': beschreibung,
        if (farbe != null) 'farbe': farbe,
      },
    );
    return Register.fromJson(res.data!);
  }

  Future<Register> updateRegister(
    String kapelleId,
    String registerId,
    String name, {
    String? beschreibung,
    String? farbe,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/register/$registerId',
      data: {
        'name': name,
        if (beschreibung != null) 'beschreibung': beschreibung,
        if (farbe != null) 'farbe': farbe,
      },
    );
    return Register.fromJson(res.data!);
  }

  Future<void> deleteRegister(String kapelleId, String registerId) async {
    await _dio
        .delete<void>('/api/v1/kapellen/$kapelleId/register/$registerId');
  }
}
