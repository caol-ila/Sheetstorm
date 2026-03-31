/// Integration Tests für kritische User-Journeys (CR#10)
///
/// Notifier-Level-Tests: Mehrere Notifier arbeiten zusammen über einen
/// gemeinsamen Mock-Service. Kein Widget-Tree — reine State-Logik.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/communication/application/post_notifier.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/features/communication/data/services/post_service.dart';
import 'package:sheetstorm/features/events/application/event_notifier.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/data/services/event_service.dart';
import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockEventService extends Mock implements EventService {}

class MockPostService extends Mock implements PostService {}

class MockBroadcastRestService extends Mock implements BroadcastRestService {}

class MockBroadcastSignalRService extends Mock
    implements BroadcastSignalRService {
  @override
  Stream<SessionStartedPayload> get onSessionStarted => const Stream.empty();
  @override
  Stream<SongChangedPayload> get onSongChanged => const Stream.empty();
  @override
  Stream<SessionEndedPayload> get onSessionEnded => const Stream.empty();
  @override
  Stream<ConnectionCountPayload> get onConnectionCountUpdated =>
      const Stream.empty();
  @override
  Stream<SignalRConnectionState> get onConnectionStateChanged =>
      const Stream.empty();
}

/// Test-Only ActiveBandNotifier mit festem Wert.
class _FixedActiveBandNotifier extends ActiveBandNotifier {
  _FixedActiveBandNotifier(this._fixedId);
  final String? _fixedId;

  @override
  String? build() => _fixedId;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

Event _event({
  String id = 'evt1',
  String title = 'Frühjahrskonzert',
  EventType type = EventType.konzert,
  RsvpStatus myRsvpStatus = RsvpStatus.offen,
}) =>
    Event(
      id: id,
      bandId: 'band1',
      title: title,
      type: type,
      date: DateTime(2025, 5, 1),
      startTime: '19:00',
      createdAt: DateTime(2025, 1, 1),
      createdByName: 'Max',
      statistics: const EventStatistics(
        zugesagt: 5,
        abgesagt: 2,
        unsicher: 1,
        offen: 2,
      ),
      myRsvpStatus: myRsvpStatus,
    );

Post _post({
  String id = 'post1',
  String title = 'Probenankündigung',
  String content = 'Nächste Probe ist am Dienstag',
}) =>
    Post(
      id: id,
      bandId: 'band1',
      author: const Author(id: 'u1', name: 'Max Mustermann'),
      title: title,
      content: content,
      createdAt: DateTime(2025, 3, 1),
      updatedAt: DateTime(2025, 3, 1),
    );

Comment _comment({
  String id = 'c1',
  String postId = 'post1',
  String content = 'Ich bin dabei!',
  String? parentId,
}) =>
    Comment(
      id: id,
      postId: postId,
      author: const Author(id: 'u2', name: 'Anna Muster'),
      content: content,
      parentId: parentId,
      createdAt: DateTime(2025, 3, 2),
    );

BroadcastSession _session({
  String sessionId = 'sess1',
  String aktiveStueckId = 'stueck1',
  String? setlistId,
}) =>
    BroadcastSession(
      sessionId: sessionId,
      kapelleId: 'band1',
      dirigentId: 'dir1',
      dirigentName: 'Max Dirigent',
      status: BroadcastSessionStatus.active,
      erstelltAm: DateTime(2025, 1, 1),
      verbundeneMusiker: 0,
      aktiveStueckId: aktiveStueckId,
      aktiveStueckTitel: 'Stück 1',
    );

Rsvp _rsvpResult({RsvpStatus status = RsvpStatus.zugesagt}) => Rsvp(
      eventId: 'evt1',
      musicianId: 'u1',
      name: 'Max Mustermann',
      instrument: 'Trompete',
      status: status,
      changedAt: DateTime(2025, 1, 1),
    );

UpdateSongResponse _updateSongResponse(String stueckId) => UpdateSongResponse(
      sessionId: 'sess1',
      aktiveStueckId: stueckId,
      broadcastedAt: DateTime(2025, 1, 1),
      erreichteMusikerCount: 5,
    );

// ─── Main ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(EventType.konzert);
    registerFallbackValue(RsvpStatus.offen);
    registerFallbackValue(DateTime(2025, 1, 1));
    registerFallbackValue(ReactionType.thumbsUp);
  });

  // ─── Journey 1: Event RSVP ─────────────────────────────────────────────────

  group('Integration: Event RSVP Journey', () {
    late ProviderContainer container;
    late MockEventService mockEventService;

    setUp(() {
      mockEventService = MockEventService();
      container = ProviderContainer(
        overrides: [
          eventServiceProvider.overrideWithValue(mockEventService),
        ],
      );
      addTearDown(container.dispose);
    });

    test('eventRsvpJourney_ZusageThenAbsage_UpdatesState', () async {
      // ── Arrange ──────────────────────────────────────────────────────────
      final eventOffen = _event(myRsvpStatus: RsvpStatus.offen);
      final eventZugesagt = _event(myRsvpStatus: RsvpStatus.zugesagt);
      final eventAbgesagt = _event(myRsvpStatus: RsvpStatus.abgesagt);

      when(() => mockEventService.getEvents(
            bandId: any(named: 'bandId'),
            type: any(named: 'type'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => [eventOffen]);

      when(() => mockEventService.getEventDetail('evt1'))
          .thenAnswer((_) async => eventOffen);

      when(() => mockEventService.submitRsvp(
            'evt1',
            status: any(named: 'status'),
            reason: any(named: 'reason'),
          )).thenAnswer((invocation) async {
        final status =
            invocation.namedArguments[#status] as RsvpStatus? ??
                RsvpStatus.offen;
        return _rsvpResult(status: status);
      });

      // ── Schritt 1: Event-Liste laden ──────────────────────────────────────
      await container.read(eventListProvider().future);

      final listState = container.read(eventListProvider()).value!;
      expect(listState.first.myRsvpStatus, RsvpStatus.offen,
          reason: 'Event startet ohne RSVP (offen)');

      // ── Schritt 2: Event-Details laden ────────────────────────────────────
      await container.read(eventDetailProvider('evt1').future);

      expect(container.read(eventDetailProvider('evt1')).value?.myRsvpStatus,
          RsvpStatus.offen);

      final detailNotifier =
          container.read(eventDetailProvider('evt1').notifier);

      // ── Schritt 3: Zusage abschicken ──────────────────────────────────────
      // Nach submitRsvp() ruft der Notifier refresh() auf → getEventDetail
      // liefert beim nächsten Aufruf den aktualisierten Zustand zurück.
      when(() => mockEventService.getEventDetail('evt1'))
          .thenAnswer((_) async => eventZugesagt);

      final success1 = await detailNotifier.submitRsvp(
        status: RsvpStatus.zugesagt,
      );

      expect(success1, isTrue, reason: 'Zusage muss erfolgreich sein');
      expect(
        container.read(eventDetailProvider('evt1')).value?.myRsvpStatus,
        RsvpStatus.zugesagt,
        reason: 'Zustand nach Zusage muss "zugesagt" sein',
      );

      // ── Schritt 4: Zur Absage wechseln ────────────────────────────────────
      when(() => mockEventService.getEventDetail('evt1'))
          .thenAnswer((_) async => eventAbgesagt);

      final success2 = await detailNotifier.submitRsvp(
        status: RsvpStatus.abgesagt,
        reason: 'Familienfeier',
      );

      expect(success2, isTrue, reason: 'Absage muss erfolgreich sein');
      expect(
        container.read(eventDetailProvider('evt1')).value?.myRsvpStatus,
        RsvpStatus.abgesagt,
        reason: 'Zustand nach Absage muss "abgesagt" sein',
      );

      // ── Verify: Service wurde korrekt aufgerufen ──────────────────────────
      verify(() => mockEventService.submitRsvp(
            'evt1',
            status: RsvpStatus.zugesagt,
            reason: any(named: 'reason'),
          )).called(1);

      verify(() => mockEventService.submitRsvp(
            'evt1',
            status: RsvpStatus.abgesagt,
            reason: 'Familienfeier',
          )).called(1);
    });
  });

  // ─── Journey 2: Post + Kommentar ──────────────────────────────────────────

  group('Integration: Post + Kommentar Journey', () {
    late ProviderContainer container;
    late MockPostService mockPostService;

    setUp(() {
      mockPostService = MockPostService();
      container = ProviderContainer(
        overrides: [
          postServiceProvider.overrideWithValue(mockPostService),
        ],
      );
      addTearDown(container.dispose);
    });

    test('postCommentJourney_CreateAndReply_BuildsThread', () async {
      // ── Arrange ──────────────────────────────────────────────────────────
      final post = _post(id: 'post1', title: 'Probenankündigung');
      final topComment = _comment(
        id: 'c1',
        postId: 'post1',
        content: 'Ich bin dabei!',
        parentId: null,
      );
      final replyComment = _comment(
        id: 'c2',
        postId: 'post1',
        content: 'Ich auch!',
        parentId: 'c1', // Antwort auf topComment
      );

      when(() => mockPostService.getPosts(
            any(),
            pinnedOnly: any(named: 'pinnedOnly'),
          )).thenAnswer((_) async => []);

      when(() => mockPostService.createPost(
            any(),
            title: any(named: 'title'),
            content: any(named: 'content'),
            attachments: any(named: 'attachments'),
            targetSectionIds: any(named: 'targetSectionIds'),
          )).thenAnswer((_) async => post);

      when(() => mockPostService.getComments(any(), any()))
          .thenAnswer((_) async => []);

      when(() => mockPostService.addComment(
            any(),
            any(),
            content: any(named: 'content'),
            parentId: any(named: 'parentId'),
            imageUrl: any(named: 'imageUrl'),
          )).thenAnswer((invocation) async {
        final content =
            invocation.namedArguments[#content] as String? ?? '';
        final parentId =
            invocation.namedArguments[#parentId] as String?;
        return parentId == null
            ? topComment
            : replyComment;
      });

      // ── Schritt 1: Post erstellen ─────────────────────────────────────────
      await container.read(postListProvider('band1').future);

      final listNotifier = container.read(postListProvider('band1').notifier);
      final createdPost = await listNotifier.createPost(
        title: 'Probenankündigung',
        content: 'Nächste Probe ist am Dienstag',
      );

      expect(createdPost, isNotNull, reason: 'Post muss erstellt werden');
      expect(createdPost?.id, 'post1');

      final listState = container.read(postListProvider('band1')).value!;
      expect(listState.any((p) => p.id == 'post1'), isTrue,
          reason: 'Erstellter Post erscheint in der Liste');

      // ── Schritt 2: Top-Level-Kommentar hinzufügen ─────────────────────────
      await container.read(postCommentsProvider('band1', 'post1').future);

      final commentsNotifier =
          container.read(postCommentsProvider('band1', 'post1').notifier);

      final comment1 = await commentsNotifier.addComment(
        content: 'Ich bin dabei!',
      );

      expect(comment1, isNotNull, reason: 'Kommentar muss erstellt werden');
      expect(comment1?.parentId, isNull,
          reason: 'Top-Level-Kommentar hat kein parentId');

      final commentsNachErstem =
          container.read(postCommentsProvider('band1', 'post1')).value!;
      expect(commentsNachErstem.length, 1,
          reason: 'Liste enthält einen Kommentar');

      // ── Schritt 3: Antwort auf Kommentar ──────────────────────────────────
      final reply = await commentsNotifier.addComment(
        content: 'Ich auch!',
        parentId: 'c1',
      );

      expect(reply, isNotNull, reason: 'Antwort muss erstellt werden');
      expect(reply?.parentId, 'c1',
          reason: 'Antwort verweist auf Eltern-Kommentar');

      // ── Verify: Thread-Struktur ───────────────────────────────────────────
      final thread =
          container.read(postCommentsProvider('band1', 'post1')).value!;
      expect(thread.length, 2, reason: 'Thread enthält Kommentar + Antwort');

      final topLevelComments =
          thread.where((c) => c.parentId == null).toList();
      final replies = thread.where((c) => c.parentId != null).toList();

      expect(topLevelComments.length, 1,
          reason: 'Genau ein Top-Level-Kommentar');
      expect(replies.length, 1, reason: 'Genau eine Antwort');
      expect(replies.first.parentId, topLevelComments.first.id,
          reason: 'Antwort verweist auf den richtigen Top-Level-Kommentar');
    });
  });

  // ─── Journey 3: Setlist Broadcast ─────────────────────────────────────────

  group('Integration: Setlist Broadcast Journey', () {
    late ProviderContainer container;
    late MockBroadcastRestService mockRest;
    late MockBroadcastSignalRService mockSignalR;

    setUp(() {
      mockRest = MockBroadcastRestService();
      mockSignalR = MockBroadcastSignalRService();

      when(() => mockSignalR.connect()).thenAnswer((_) async {});
      when(() => mockSignalR.disconnect()).thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          authProvider.overrideWithValue(
            const AuthAuthenticated(
              User(
                id: 'dir1',
                email: 'dirigent@kapelle.de',
                displayName: 'Max Dirigent',
                emailVerified: true,
                onboardingCompleted: true,
              ),
            ),
          ),
          activeBandProvider
              .overrideWith(() => _FixedActiveBandNotifier('band1')),
          broadcastRestServiceProvider.overrideWithValue(mockRest),
          broadcastSignalRServiceProvider.overrideWithValue(mockSignalR),
        ],
      );
      addTearDown(container.dispose);
    });

    test('setlistBroadcastJourney_StartNavigateStop_FullCycle', () async {
      // ── Arrange ──────────────────────────────────────────────────────────
      final session = _session(sessionId: 'sess1', aktiveStueckId: 'stueck1');

      when(() => mockRest.startSession(
            kapelleId: 'band1',
            setlistId: 'setlist1',
          )).thenAnswer((_) async => session);

      when(() => mockRest.updateSong('sess1', any()))
          .thenAnswer((invocation) async {
        final stueckId = invocation.positionalArguments[1] as String;
        return _updateSongResponse(stueckId);
      });

      when(() => mockRest.endSession('sess1')).thenAnswer((_) async {});

      final notifier = container.read(broadcastProvider.notifier);

      // ── Schritt 1: Session starten ────────────────────────────────────────
      expect(container.read(broadcastProvider).mode, BroadcastMode.idle,
          reason: 'Vor dem Start ist der Modus idle');

      await notifier.startSession(setlistId: 'setlist1');

      expect(container.read(broadcastProvider).mode,
          BroadcastMode.broadcasting,
          reason: 'Nach startSession() wechselt Modus zu broadcasting');
      expect(container.read(broadcastProvider).session?.sessionId, 'sess1',
          reason: 'Session-ID wird aus Service-Antwort übernommen');
      expect(container.read(broadcastProvider).session?.aktiveStueckId,
          'stueck1',
          reason: 'Erstes aktives Stück aus Session-Antwort');

      // ── Schritt 2: Stück navigieren ───────────────────────────────────────
      await notifier.broadcastSong('stueck2');

      expect(
        container.read(broadcastProvider).session?.aktiveStueckId,
        'stueck2',
        reason: 'Nach broadcastSong("stueck2") ist stueck2 das aktive Stück',
      );

      await notifier.broadcastSong('stueck3');

      expect(
        container.read(broadcastProvider).session?.aktiveStueckId,
        'stueck3',
        reason: 'Navigation zu stueck3 erfolgreich',
      );

      // ── Schritt 3: Session beenden ────────────────────────────────────────
      await notifier.endSession();

      expect(container.read(broadcastProvider).mode, BroadcastMode.idle,
          reason: 'Nach endSession() ist Modus wieder idle');
      expect(container.read(broadcastProvider).session, isNull,
          reason: 'Session wird nach Ende geleert');
      expect(container.read(broadcastProvider).error, isNull,
          reason: 'Kein Fehler nach ordentlichem Ende');

      // ── Verify: Korrekte Service-Aufrufe ──────────────────────────────────
      verify(() =>
              mockRest.startSession(kapelleId: 'band1', setlistId: 'setlist1'))
          .called(1);
      verify(() => mockRest.updateSong('sess1', 'stueck2')).called(1);
      verify(() => mockRest.updateSong('sess1', 'stueck3')).called(1);
      verify(() => mockRest.endSession('sess1')).called(1);
      verify(() => mockSignalR.connect()).called(1);
      verify(() => mockSignalR.disconnect()).called(1);
    });
  });
}
