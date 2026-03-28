/// API service for configuration endpoints — Issue #35
///
/// Reference: docs/feature-specs/konfigurationssystem-spec.md § 3 (API)

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'config_api_service.g.dart';

@riverpod
ConfigApiService configApiService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return ConfigApiService(dio: dio);
}

/// REST client for the 3-level configuration API.
class ConfigApiService {
  ConfigApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  // ─── Kapelle Config ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getBandConfig(String bandId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/band/$bandId',
    );
    return response.data ?? {};
  }

  Future<void> putBandConfig(
    String bandId,
    String key,
    dynamic value,
  ) async {
    await _dio.put<dynamic>(
      '/config/band/$bandId/$key',
      data: {'value': value},
    );
  }

  Future<void> deleteBandConfig(String bandId, String key) async {
    await _dio.delete<dynamic>('/config/band/$bandId/$key');
  }

  // ─── Policies ────────────────────────────────────────────────────────────

  Future<Map<String, ConfigPolicy>> getBandPolicies(
      String bandId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/band/$bandId/policies',
    );
    final data = response.data ?? {};
    return data.map((key, value) => MapEntry(
          key,
          ConfigPolicy.fromJson({
            'key': key,
            ...value as Map<String, dynamic>,
          }),
        ));
  }

  Future<void> putPolicy(
    String bandId,
    String key,
    dynamic value,
  ) async {
    await _dio.put<dynamic>(
      '/config/band/$bandId/policies/$key',
      data: {'value': value},
    );
  }

  // ─── Nutzer Config ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNutzerConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/config/nutzer');
    return response.data ?? {};
  }

  Future<void> putNutzerConfig(String key, dynamic value) async {
    await _dio.put<dynamic>('/config/nutzer/$key', data: {'value': value});
  }

  Future<void> deleteNutzerConfig(String key) async {
    await _dio.delete<dynamic>('/config/nutzer/$key');
  }

  /// Delta-sync: send local changes, receive server changes.
  Future<Map<String, dynamic>> syncUserConfig(
    List<PendingSyncEntry> changes,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/config/nutzer/sync',
      data: {
        'changes': changes.map((c) => c.toJson()).toList(),
      },
    );
    return response.data ?? {};
  }

  // ─── Resolved Config ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getResolvedConfig(String bandId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/resolved',
      queryParameters: {'band_id': bandId},
    );
    return response.data ?? {};
  }
}
