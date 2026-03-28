import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'substitute_service.g.dart';

@Riverpod(keepAlive: true)
SubstituteService substituteService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return SubstituteService(dio);
}

/// HTTP layer for Substitute Access endpoints.
class SubstituteService {
  final Dio _dio;

  SubstituteService(this._dio);

  // ─── Create Access Link ─────────────────────────────────────────────────────

  Future<SubstituteLink> createAccessLink(
    String bandId, {
    required String name,
    required String instrument,
    required String voice,
    String? eventId,
    DateTime? expiresAt,
    String? note,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/aushilfen',
      data: {
        'name': name,
        'instrument': instrument,
        'voice': voice,
        if (eventId != null) 'event_id': eventId,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        if (note != null) 'note': note,
      },
    );
    return SubstituteLink.fromJson(res.data!);
  }

  // ─── List Access ────────────────────────────────────────────────────────────

  Future<List<SubstituteAccess>> listAccess(
    String bandId, {
    SubstituteStatus? status,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/kapellen/$bandId/aushilfen',
      queryParameters: {
        if (status != null) 'status': status.toJson(),
      },
    );
    return res.data!
        .map((e) => SubstituteAccess.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── Get Access Detail ──────────────────────────────────────────────────────

  Future<SubstituteAccess> getAccessDetail(String bandId, String accessId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/aushilfen/$accessId',
    );
    return SubstituteAccess.fromJson(res.data!);
  }

  // ─── Revoke Access ──────────────────────────────────────────────────────────

  Future<void> revokeAccess(String bandId, String accessId) async {
    await _dio.delete<void>('/api/v1/kapellen/$bandId/aushilfen/$accessId');
  }

  // ─── Extend Expiry ──────────────────────────────────────────────────────────

  Future<SubstituteAccess> extendExpiry(
    String bandId,
    String accessId,
    DateTime newExpiresAt,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/aushilfen/$accessId',
      data: {'expires_at': newExpiresAt.toIso8601String()},
    );
    return SubstituteAccess.fromJson(res.data!);
  }
}
