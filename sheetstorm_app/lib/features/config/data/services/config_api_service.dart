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

  Future<Map<String, dynamic>> getKapelleConfig(String kapelleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/kapelle/$kapelleId',
    );
    return response.data ?? {};
  }

  Future<void> putKapelleConfig(
    String kapelleId,
    String key,
    dynamic wert,
  ) async {
    await _dio.put<dynamic>(
      '/config/kapelle/$kapelleId/$key',
      data: {'wert': wert},
    );
  }

  Future<void> deleteKapelleConfig(String kapelleId, String key) async {
    await _dio.delete<dynamic>('/config/kapelle/$kapelleId/$key');
  }

  // ─── Policies ────────────────────────────────────────────────────────────

  Future<Map<String, ConfigPolicy>> getKapellePolicies(
      String kapelleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/kapelle/$kapelleId/policies',
    );
    final data = response.data ?? {};
    return data.map((key, value) => MapEntry(
          key,
          ConfigPolicy.fromJson({
            'schluessel': key,
            ...value as Map<String, dynamic>,
          }),
        ));
  }

  Future<void> putPolicy(
    String kapelleId,
    String key,
    dynamic wert,
  ) async {
    await _dio.put<dynamic>(
      '/config/kapelle/$kapelleId/policies/$key',
      data: {'wert': wert},
    );
  }

  // ─── Nutzer Config ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getNutzerConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/config/nutzer');
    return response.data ?? {};
  }

  Future<void> putNutzerConfig(String key, dynamic wert) async {
    await _dio.put<dynamic>('/config/nutzer/$key', data: {'wert': wert});
  }

  Future<void> deleteNutzerConfig(String key) async {
    await _dio.delete<dynamic>('/config/nutzer/$key');
  }

  /// Delta-sync: send local changes, receive server changes.
  Future<Map<String, dynamic>> syncNutzerConfig(
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

  Future<Map<String, dynamic>> getResolvedConfig(String kapelleId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/config/resolved',
      queryParameters: {'kapelle_id': kapelleId},
    );
    return response.data ?? {};
  }
}
