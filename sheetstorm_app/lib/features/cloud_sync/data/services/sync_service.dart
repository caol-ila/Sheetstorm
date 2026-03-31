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

  /// Fetches current sync state from server.
  Future<SyncStateResponse> getSyncState() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/sync/state');
    return SyncStateResponse.fromJson(response.data!);
  }

  /// Pulls changes from server since a given version.
  Future<PullResponse> pull(int sinceVersion) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sync/pull',
      data: {'sinceVersion': sinceVersion},
    );
    return PullResponse.fromJson(response.data!);
  }

  /// Pushes local changes to server.
  Future<PushResponse> push(int baseVersion, List<SyncDelta> changes) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/sync/push',
      data: {
        'baseVersion': baseVersion,
        'changes': changes.map((d) => d.toJson()).toList(),
      },
    );
    return PushResponse.fromJson(response.data!);
  }
}
