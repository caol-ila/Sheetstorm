import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'sync_service.g.dart';

@riverpod
SyncService syncService(Ref ref) {
  return SyncService(ref.read(apiClientProvider));
}

class SyncService {
  SyncService(this._dio);

  final Dio _dio;

  /// Fetches current sync state: pending count and unresolved conflicts.
  Future<SyncStateResponse> getSyncState() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/sync/state');
    return SyncStateResponse.fromJson(response.data!);
  }

  /// Pulls deltas from server, optionally since a given timestamp.
  Future<List<SyncDelta>> pull(DateTime? since) async {
    final params = since != null
        ? <String, dynamic>{'since': since.toIso8601String()}
        : null;
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/sync/pull',
      queryParameters: params,
    );
    final data = response.data!;
    return (data['deltas'] as List<dynamic>? ?? [])
        .map((d) => SyncDelta.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  /// Pushes local deltas to server.
  Future<void> push(List<SyncDelta> deltas) async {
    await _dio.post<dynamic>(
      '/api/sync/push',
      data: {
        'deltas': deltas.map((d) => d.toJson()).toList(),
      },
    );
  }
}
