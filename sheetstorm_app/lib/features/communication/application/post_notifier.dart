import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/features/communication/data/services/post_service.dart';

part 'post_notifier.g.dart';

// ─── Post List ────────────────────────────────────────────────────────────────

@riverpod
class PostListNotifier extends _$PostListNotifier {
  @override
  Future<List<Post>> build(String bandId, {bool? pinnedOnly}) async {
    final service = ref.read(postServiceProvider);
    return service.getPosts(bandId, pinnedOnly: pinnedOnly);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(postServiceProvider);
      return service.getPosts(bandId, pinnedOnly: pinnedOnly);
    });
  }

  Future<Post?> createPost({
    required String title,
    required String content,
    List<Map<String, dynamic>>? attachments,
    List<String>? targetSectionIds,
  }) async {
    final service = ref.read(postServiceProvider);
    try {
      final post = await service.createPost(
        bandId,
        title: title,
        content: content,
        attachments: attachments,
        targetSectionIds: targetSectionIds,
      );
      final current = state.value ?? [];
      state = AsyncData([post, ...current]);
      return post;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    final service = ref.read(postServiceProvider);
    try {
      await service.deletePost(bandId, postId);
      final current = state.value ?? [];
      state = AsyncData(current.where((p) => p.id != postId).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> togglePin(String postId, bool pin) async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.togglePin(bandId, postId, pin);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((p) => p.id == postId ? updated : p).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> addReaction(String postId, ReactionType type) async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.addReaction(bandId, postId, type);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((p) => p.id == postId ? updated : p).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeReaction(String postId) async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.removeReaction(bandId, postId);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((p) => p.id == postId ? updated : p).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Post Detail ──────────────────────────────────────────────────────────────

@riverpod
class PostDetailNotifier extends _$PostDetailNotifier {
  @override
  Future<Post> build(String bandId, String postId) async {
    final service = ref.read(postServiceProvider);
    return service.getPostDetail(bandId, postId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(postServiceProvider);
      return service.getPostDetail(bandId, postId);
    });
  }

  Future<bool> togglePin(bool pin) async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.togglePin(bandId, postId, pin);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> addReaction(ReactionType type) async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.addReaction(bandId, postId, type);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeReaction() async {
    final service = ref.read(postServiceProvider);
    try {
      final updated = await service.removeReaction(bandId, postId);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Comments ─────────────────────────────────────────────────────────────────

@riverpod
class PostCommentsNotifier extends _$PostCommentsNotifier {
  @override
  Future<List<Comment>> build(String bandId, String postId) async {
    final service = ref.read(postServiceProvider);
    return service.getComments(bandId, postId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(postServiceProvider);
      return service.getComments(bandId, postId);
    });
  }

  Future<Comment?> addComment({
    required String content,
    String? parentId,
    String? imageUrl,
  }) async {
    final service = ref.read(postServiceProvider);
    try {
      final comment = await service.addComment(
        bandId,
        postId,
        content: content,
        parentId: parentId,
        imageUrl: imageUrl,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, comment]);
      return comment;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    final service = ref.read(postServiceProvider);
    try {
      await service.deleteComment(bandId, postId, commentId);
      final current = state.value ?? [];
      state = AsyncData(
        current
            .map((c) => c.id == commentId ? c.copyWith(isDeleted: true) : c)
            .toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
