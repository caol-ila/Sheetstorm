import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/media_links/data/models/media_link_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'media_link_service.g.dart';

@Riverpod(keepAlive: true)
MediaLinkService mediaLinkService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return MediaLinkService(dio);
}

class MediaLinkService {
  final Dio _dio;

  MediaLinkService(this._dio);

  Future<List<MediaLink>> getLinks(String kapelleId, String stueckId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/stuecke/$stueckId/media-links',
    );
    final items = res.data!['items'] as List<dynamic>;
    return items
        .map((e) => MediaLink.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MediaLink> addLink({
    required String kapelleId,
    required String stueckId,
    required String url,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$kapelleId/stuecke/$stueckId/media-links',
      data: {'url': url},
    );
    return MediaLink.fromJson(res.data!);
  }

  Future<void> deleteLink({
    required String kapelleId,
    required String stueckId,
    required String linkId,
  }) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$kapelleId/stuecke/$stueckId/media-links/$linkId',
    );
  }

  Future<List<MediaLinkVorschlag>> getVorschlaege({
    required String kapelleId,
    required String stueckId,
  }) async {
    final res = await _dio.post<List<dynamic>>(
      '/api/v1/kapellen/$kapelleId/stuecke/$stueckId/media-links/vorschlaege',
    );
    return res.data!
        .map((e) => MediaLinkVorschlag.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
