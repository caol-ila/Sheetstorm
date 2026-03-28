import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'post_service.g.dart';

@Riverpod(keepAlive: true)
PostService postService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return PostService(dio);
}

/// HTTP layer for Posts endpoints.
class PostService {
  final Dio _dio;

  PostService(this._dio);

  // ─── Posts CRUD ───────────────────────────────────────────────────────────

  Future<List<Post>> getPosts(
    String bandId, {
    String? cursor,
    int limit = 20,
    bool? pinnedOnly,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        if (pinnedOnly != null) 'pinned': pinnedOnly,
      },
    );
    final posts = res.data!['posts'] as List<dynamic>;
    return posts
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Post> getPostDetail(String bandId, String postId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId',
    );
    return Post.fromJson(res.data!);
  }

  Future<Post> createPost(
    String bandId, {
    required String title,
    required String content,
    List<Map<String, dynamic>>? attachments,
    List<String>? targetSectionIds,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts',
      data: {
        'title': title,
        'content': content,
        if (attachments != null) 'attachments': attachments,
        if (targetSectionIds != null) 'targetSectionIds': targetSectionIds,
      },
    );
    return Post.fromJson(res.data!);
  }

  Future<Post> updatePost(
    String bandId,
    String postId, {
    String? title,
    String? content,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId',
      data: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
      },
    );
    return Post.fromJson(res.data!);
  }

  Future<void> deletePost(String bandId, String postId) async {
    await _dio.delete<void>('/api/v1/bands/$bandId/posts/$postId');
  }

  Future<Post> togglePin(String bandId, String postId, bool pin) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId/pin',
      data: {'pinned': pin},
    );
    return Post.fromJson(res.data!);
  }

  // ─── Reactions ────────────────────────────────────────────────────────────

  Future<Post> addReaction(
    String bandId,
    String postId,
    ReactionType type,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId/reactions',
      data: {'type': type.toJson()},
    );
    return Post.fromJson(res.data!);
  }

  Future<Post> removeReaction(
    String bandId,
    String postId,
  ) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId/reactions',
    );
    return Post.fromJson(res.data!);
  }

  // ─── Comments ─────────────────────────────────────────────────────────────

  Future<List<Comment>> getComments(String bandId, String postId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId/comments',
    );
    return res.data!
        .map((e) => Comment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Comment> addComment(
    String bandId,
    String postId, {
    required String content,
    String? parentId,
    String? imageUrl,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/posts/$postId/comments',
      data: {
        'content': content,
        if (parentId != null) 'parentId': parentId,
        if (imageUrl != null) 'imageUrl': imageUrl,
      },
    );
    return Comment.fromJson(res.data!);
  }

  Future<void> deleteComment(
    String bandId,
    String postId,
    String commentId,
  ) async {
    await _dio.delete<void>(
      '/api/v1/bands/$bandId/posts/$postId/comments/$commentId',
    );
  }
}
