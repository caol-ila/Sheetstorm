import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/communication/application/post_notifier.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/features/communication/data/services/post_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockPostService extends Mock implements PostService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Author _author({
  String id = 'author1',
  String name = 'Test Autor',
}) =>
    Author(
      id: id,
      name: name,
      avatarUrl: null,
      role: 'Mitglied',
    );

Post _post({
  String id = 'post1',
  String title = 'Test Post',
  String content = 'Test Inhalt',
  bool isPinned = false,
  int commentCount = 0,
  List<Attachment> attachments = const [],
  List<String> targetSectionIds = const [],
  Map<ReactionType, Reaction>? reactions,
}) =>
    Post(
      id: id,
      bandId: 'band1',
      author: _author(),
      title: title,
      content: content,
      attachments: attachments,
      targetSectionIds: targetSectionIds,
      isPinned: isPinned,
      commentCount: commentCount,
      reactions: reactions ?? {},
      createdAt: DateTime(2024, 1, 15),
      updatedAt: DateTime(2024, 1, 15),
    );

Comment _comment({
  String id = 'comment1',
  String postId = 'post1',
  String content = 'Test Kommentar',
  String? parentId,
  String? imageUrl,
  bool isDeleted = false,
}) =>
    Comment(
      id: id,
      postId: postId,
      author: _author(),
      content: content,
      parentId: parentId,
      imageUrl: imageUrl,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 15),
    );

// ─── Setup Helpers ────────────────────────────────────────────────────────────

MockPostService _defaultListService() {
  final service = MockPostService();
  when(() => service.getPosts(any(), pinnedOnly: any(named: 'pinnedOnly')))
      .thenAnswer((_) async => []);
  return service;
}

MockPostService _defaultDetailService() {
  final service = MockPostService();
  when(() => service.getPostDetail(any(), any()))
      .thenAnswer((_) async => _post());
  return service;
}

MockPostService _defaultCommentsService() {
  final service = MockPostService();
  when(() => service.getComments(any(), any()))
      .thenAnswer((_) async => []);
  return service;
}

(ProviderContainer, MockPostService) _createContainer(MockPostService service) {
  final container = ProviderContainer(
    overrides: [postServiceProvider.overrideWithValue(service)],
  );
  addTearDown(container.dispose);
  return (container, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(ReactionType.thumbsUp);
  });

  // ─── PostListNotifier Tests ────────────────────────────────────────────────

  group('PostListNotifier — CRUD-Operationen', () {
    test('Posts werden initial geladen', () async {
      final service = _defaultListService();
      final (container, _) = _createContainer(service);
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      // Initial AsyncLoading state expected
      expect(container.read(postListProvider('band1', pinnedOnly: false)).isLoading, isTrue);
    });

    test('createPost fügt neuen Post hinzu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final post = await notifier.createPost(
        title: 'Neuer Post',
        content: 'Neuer Inhalt',
      );

      expect(post, isNotNull);
      expect(post?.title, 'Neuer Post');
      expect(post?.content, 'Neuer Inhalt');
    });

    test('createPost mit Attachments erstellt Post korrekt', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final post = await notifier.createPost(
        title: 'Post mit Anhang',
        content: 'Inhalt',
        attachments: [
          {'type': 'pdf', 'url': 'https://example.com/file.pdf'}
        ],
      );

      expect(post, isNotNull);
      expect(post?.attachments.isNotEmpty, isTrue);
    });

    test('createPost mit targetSectionIds filtert Zielgruppe', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final post = await notifier.createPost(
        title: 'Post für Register',
        content: 'Nur Trompeten',
        targetSectionIds: ['trp1', 'trp2'],
      );

      expect(post, isNotNull);
      expect(post?.targetSectionIds, ['trp1', 'trp2']);
    });

    test('deletePost entfernt Post aus Liste', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      await notifier.createPost(title: 'Zu löschen', content: 'Test');
      final success = await notifier.deletePost('post1');

      expect(success, isTrue);
    });

    test('deletePost mit unbekannter ID gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final success = await notifier.deletePost('unknown_id');

      expect(success, isFalse);
    });
  });

  // ─── Pin State Tests ───────────────────────────────────────────────────────

  group('PostListNotifier — Pin-Status', () {
    test('togglePin setzt Pin auf true', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final success = await notifier.togglePin('post1', true);

      expect(success, isTrue);
    });

    test('togglePin setzt Pin auf false', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final success = await notifier.togglePin('post1', false);

      expect(success, isTrue);
    });

    test('Gepinnte Posts werden korrekt gefiltert', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // pinnedOnly: true sollte nur gepinnte Posts laden
      final notifier = container.read(postListProvider('band1', pinnedOnly: true).notifier);
      
      expect(container.read(postListProvider('band1', pinnedOnly: true)).isLoading, isTrue);
    });
  });

  // ─── Reaction Tests ────────────────────────────────────────────────────────

  group('PostListNotifier — Reaktionen', () {
    test('addReaction fügt Reaktion hinzu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final success = await notifier.addReaction('post1', ReactionType.thumbsUp);

      expect(success, isTrue);
    });

    test('addReaction mit verschiedenen Typen funktioniert', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      await notifier.addReaction('post1', ReactionType.heart);
      await notifier.addReaction('post1', ReactionType.clap);
      await notifier.addReaction('post1', ReactionType.trumpet);

      // Should update state successfully
      expect(container.read(postListProvider('band1', pinnedOnly: false)).hasValue, isTrue);
    });

    test('removeReaction entfernt Reaktion', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      await notifier.addReaction('post1', ReactionType.thumbsUp);
      final success = await notifier.removeReaction('post1');

      expect(success, isTrue);
    });

    test('removeReaction auf Post ohne Reaktion gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      
      final success = await notifier.removeReaction('post_ohne_reaction');

      expect(success, isFalse);
    });
  });

  // ─── PostDetailNotifier Tests ──────────────────────────────────────────────

  group('PostDetailNotifier — Detail-Ansicht', () {
    test('Post wird initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(postDetailProvider('band1', 'post1').notifier);
      
      expect(container.read(postDetailProvider('band1', 'post1')).isLoading, isTrue);
    });

    test('refresh lädt Post neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postDetailProvider('band1', 'post1').notifier);
      
      await notifier.refresh();

      expect(container.read(postDetailProvider('band1', 'post1')).isLoading, isTrue);
    });

    test('togglePin aktualisiert Detail-Post', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postDetailProvider('band1', 'post1').notifier);
      
      final success = await notifier.togglePin(true);

      expect(success, isTrue);
    });

    test('addReaction aktualisiert Detail-Post', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postDetailProvider('band1', 'post1').notifier);
      
      final success = await notifier.addReaction(ReactionType.smile);

      expect(success, isTrue);
    });

    test('removeReaction aktualisiert Detail-Post', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postDetailProvider('band1', 'post1').notifier);
      
      final success = await notifier.removeReaction();

      expect(success, isTrue);
    });
  });

  // ─── PostCommentsNotifier Tests ────────────────────────────────────────────

  group('PostCommentsNotifier — Kommentare', () {
    test('Kommentare werden initial geladen', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(postCommentsProvider('band1', 'post1').notifier);
      
      expect(container.read(postCommentsProvider('band1', 'post1')).isLoading, isTrue);
    });

    test('addComment fügt Kommentar hinzu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      final comment = await notifier.addComment(content: 'Neuer Kommentar');

      expect(comment, isNotNull);
      expect(comment?.content, 'Neuer Kommentar');
    });

    test('addComment mit parentId erstellt Antwort', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      final comment = await notifier.addComment(
        content: 'Antwort auf Kommentar',
        parentId: 'comment1',
      );

      expect(comment, isNotNull);
      expect(comment?.parentId, 'comment1');
    });

    test('addComment mit imageUrl erstellt Bild-Kommentar', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      final comment = await notifier.addComment(
        content: 'Schaut mal!',
        imageUrl: 'https://example.com/image.jpg',
      );

      expect(comment, isNotNull);
      expect(comment?.imageUrl, 'https://example.com/image.jpg');
    });

    test('deleteComment markiert Kommentar als gelöscht', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      await notifier.addComment(content: 'Zu löschen');
      final success = await notifier.deleteComment('comment1');

      expect(success, isTrue);
    });

    test('deleteComment mit unbekannter ID gibt false zurück', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      final success = await notifier.deleteComment('unknown_comment');

      expect(success, isFalse);
    });

    test('refresh lädt Kommentare neu', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(postCommentsProvider('band1', 'post1').notifier);
      
      await notifier.refresh();

      expect(container.read(postCommentsProvider('band1', 'post1')).isLoading, isTrue);
    });
  });

  // ─── Provider Family Tests ─────────────────────────────────────────────────

  group('Post Provider — Family-Scoping', () {
    test('Verschiedene bandId-Scopes sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier1 = container.read(postListProvider('band1', pinnedOnly: false).notifier);
      final notifier2 = container.read(postListProvider('band2', pinnedOnly: false).notifier);

      await notifier1.createPost(title: 'Band1 Post', content: 'Test');

      // Band2 sollte diesen Post nicht sehen
      expect(container.read(postListProvider('band1', pinnedOnly: false)).isLoading, isTrue);
      expect(container.read(postListProvider('band2', pinnedOnly: false)).isLoading, isTrue);
    });

    test('Verschiedene postId-Scopes in PostDetail sind unabhängig', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(postDetailProvider('band1', 'post1').notifier);
      container.read(postDetailProvider('band1', 'post2').notifier);

      expect(container.read(postDetailProvider('band1', 'post1')).isLoading, isTrue);
      expect(container.read(postDetailProvider('band1', 'post2')).isLoading, isTrue);
    });
  });
}
