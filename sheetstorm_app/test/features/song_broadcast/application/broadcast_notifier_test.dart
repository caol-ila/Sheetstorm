import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/data/models/auth_models.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

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

/// Creates a ProviderContainer with all BroadcastNotifier dependencies mocked.
ProviderContainer _makeContainer({
  AuthState authState = const AuthUnauthenticated(),
  String? activeBandId,
  MockBroadcastRestService? restService,
  MockBroadcastSignalRService? signalRService,
}) {
  final rest = restService ?? MockBroadcastRestService();
  final signalR = signalRService ?? MockBroadcastSignalRService();

  when(() => signalR.disconnect()).thenAnswer((_) async {});

  return ProviderContainer(
    overrides: [
      authProvider.overrideWithValue(authState),
      activeBandProvider.overrideWith(
        () => _FixedActiveBandNotifier(activeBandId),
      ),
      broadcastRestServiceProvider.overrideWithValue(rest),
      broadcastSignalRServiceProvider.overrideWithValue(signalR),
    ],
  );
}

/// A test-only ActiveBandNotifier that returns a fixed value.
class _FixedActiveBandNotifier extends ActiveBandNotifier {
  _FixedActiveBandNotifier(this._fixedId);
  final String? _fixedId;

  @override
  String? build() => _fixedId;
}

// --- Helpers -----------------------------------------------------------------

BroadcastSession _session({
  String sessionId = 'sess1',
  String aktiveStueckId = 'p1',
  int verbundeneMusiker = 5,
}) =>
    BroadcastSession(
      sessionId: sessionId,
      kapelleId: 'band1',
      dirigentId: 'dir1',
      dirigentName: 'Max Dirigent',
      status: BroadcastSessionStatus.active,
      erstelltAm: DateTime(2025, 1, 1),
      verbundeneMusiker: verbundeneMusiker,
      aktiveStueckId: aktiveStueckId,
      aktiveStueckTitel: 'Test Stueck',
    );

ConnectedMusician _musician({
  String id = 'mus1',
  String name = 'Max Musiker',
  MusicianConnectionStatus status = MusicianConnectionStatus.ready,
}) =>
    ConnectedMusician(
      musikerId: id,
      name: name,
      instrument: 'Trompete',
      verbundenAm: DateTime(2025, 1, 1),
      status: status,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // --- BroadcastState - Helpers ---------------------------------------------

  group('BroadcastState - Helpers', () {
    test('isActive ist true bei broadcasting', () {
      const state = BroadcastState(mode: BroadcastMode.broadcasting);
      expect(state.isActive, isTrue);
    });

    test('isActive ist true bei receiving', () {
      const state = BroadcastState(mode: BroadcastMode.receiving);
      expect(state.isActive, isTrue);
    });

    test('isActive ist false bei idle', () {
      const state = BroadcastState(mode: BroadcastMode.idle);
      expect(state.isActive, isFalse);
    });

    test('isConductor ist true bei broadcasting', () {
      const state = BroadcastState(mode: BroadcastMode.broadcasting);
      expect(state.isConductor, isTrue);
    });

    test('isConductor ist false bei receiving', () {
      const state = BroadcastState(mode: BroadcastMode.receiving);
      expect(state.isConductor, isFalse);
    });

    test('isMusician ist true bei receiving', () {
      const state = BroadcastState(mode: BroadcastMode.receiving);
      expect(state.isMusician, isTrue);
    });

    test('isMusician ist false bei broadcasting', () {
      const state = BroadcastState(mode: BroadcastMode.broadcasting);
      expect(state.isMusician, isFalse);
    });

    test('default state is idle', () {
      const state = BroadcastState();
      expect(state.mode, BroadcastMode.idle);
      expect(state.session, isNull);
      expect(state.connectedMusicians, isEmpty);
      expect(state.currentSong, isNull);
      expect(state.connectedCount, 0);
      expect(state.error, isNull);
      expect(state.isActive, isFalse);
    });
  });

  // --- BroadcastState - copyWith --------------------------------------------

  group('BroadcastState - copyWith', () {
    test('copyWith mode changes mode', () {
      const state = BroadcastState(mode: BroadcastMode.idle);
      final updated = state.copyWith(mode: BroadcastMode.broadcasting);
      expect(updated.mode, BroadcastMode.broadcasting);
      expect(updated.isConductor, isTrue);
    });

    test('copyWith error sets error', () {
      const state = BroadcastState();
      final updated = state.copyWith(error: 'Test error');
      expect(updated.error, 'Test error');
    });

    test('copyWith connectedCount', () {
      const state = BroadcastState();
      final updated = state.copyWith(connectedCount: 5);
      expect(updated.connectedCount, 5);
    });

    test('copyWith session', () {
      const state = BroadcastState();
      final session = _session();
      final updated = state.copyWith(session: session);
      expect(updated.session, isNotNull);
      expect(updated.session?.sessionId, 'sess1');
    });
  });

  // --- BroadcastMode - Enum -------------------------------------------------

  group('BroadcastMode - Enum', () {
    test('BroadcastMode values exist', () {
      expect(BroadcastMode.idle, isNotNull);
      expect(BroadcastMode.connecting, isNotNull);
      expect(BroadcastMode.broadcasting, isNotNull);
      expect(BroadcastMode.receiving, isNotNull);
      expect(BroadcastMode.error, isNotNull);
    });
  });

  // --- BroadcastSession - Model ---------------------------------------------

  group('BroadcastSession - Model', () {
    test('BroadcastSession model construction', () {
      final session = _session(sessionId: 's1', verbundeneMusiker: 10);
      expect(session.sessionId, 's1');
      expect(session.kapelleId, 'band1');
      expect(session.dirigentId, 'dir1');
      expect(session.verbundeneMusiker, 10);
      expect(session.status, BroadcastSessionStatus.active);
    });

    test('BroadcastSession copyWith', () {
      final session = _session();
      final updated = session.copyWith(aktiveStueckId: 'p2');
      expect(updated.aktiveStueckId, 'p2');
      expect(updated.sessionId, 'sess1');
    });

    test('BroadcastSession toJson/fromJson roundtrip', () {
      final session = _session();
      final json = session.toJson();
      final restored = BroadcastSession.fromJson(json);
      expect(restored.sessionId, session.sessionId);
      expect(restored.kapelleId, session.kapelleId);
      expect(restored.dirigentId, session.dirigentId);
    });
  });

  // --- ConnectedMusician - Model --------------------------------------------

  group('ConnectedMusician - Model', () {
    test('ConnectedMusician model construction', () {
      final m = _musician(id: 'm1', name: 'Anna');
      expect(m.musikerId, 'm1');
      expect(m.name, 'Anna');
      expect(m.instrument, 'Trompete');
      expect(m.status, MusicianConnectionStatus.ready);
    });

    test('ConnectedMusician toJson/fromJson roundtrip', () {
      final m = _musician();
      final json = m.toJson();
      final restored = ConnectedMusician.fromJson(json);
      expect(restored.musikerId, m.musikerId);
      expect(restored.name, m.name);
    });
  });

  // --- BroadcastSessionStatus - Enum ----------------------------------------

  group('BroadcastSessionStatus - Enum', () {
    test('values exist', () {
      expect(BroadcastSessionStatus.active, isNotNull);
      expect(BroadcastSessionStatus.ended, isNotNull);
      expect(BroadcastSessionStatus.timeout, isNotNull);
    });

    test('fromJson parses correctly', () {
      expect(BroadcastSessionStatus.fromJson('active'),
          BroadcastSessionStatus.active);
      expect(BroadcastSessionStatus.fromJson('ended'),
          BroadcastSessionStatus.ended);
      expect(BroadcastSessionStatus.fromJson('timeout'),
          BroadcastSessionStatus.timeout);
    });

    test('unknown value defaults to ended', () {
      expect(BroadcastSessionStatus.fromJson('unknown'),
          BroadcastSessionStatus.ended);
    });
  });

  // --- MusicianConnectionStatus - Enum --------------------------------------

  group('MusicianConnectionStatus - Enum', () {
    test('values exist', () {
      expect(MusicianConnectionStatus.ready, isNotNull);
      expect(MusicianConnectionStatus.loading, isNotNull);
      expect(MusicianConnectionStatus.error, isNotNull);
      expect(MusicianConnectionStatus.offline, isNotNull);
    });

    test('fromJson parses correctly', () {
      expect(MusicianConnectionStatus.fromJson('ready'),
          MusicianConnectionStatus.ready);
      expect(MusicianConnectionStatus.fromJson('offline'),
          MusicianConnectionStatus.offline);
    });
  });

  // --- BroadcastNotifier - Provider -----------------------------------------

  group('BroadcastNotifier - Provider', () {
    test('provider exists', () {
      expect(broadcastProvider, isNotNull);
    });
  });

  // --- BroadcastNotifier - musikerId aus Auth-State (CR#3) ------------------

  group('BroadcastNotifier - musikerId aus Auth-State (CR#3)', () {
    test('joinSession() ist aufrufbar ohne musikerId-Parameter', () async {
      // RED: Compile-Fehler vor der Korrektur — "Required named parameter 'musikerId'"
      // GREEN: Kompiliert und läuft nach der Korrektur
      final container = _makeContainer(
        authState: const AuthUnauthenticated(),
        activeBandId: null, // kein aktives Band
      );
      addTearDown(container.dispose);

      // joinSession() ohne Argument — musikerId kommt jetzt aus dem Auth-State
      await container.read(broadcastProvider.notifier).joinSession();

      // Ohne aktive Kapelle → Fehlerzustand
      expect(container.read(broadcastProvider).mode, BroadcastMode.error);
      expect(
        container.read(broadcastProvider).error,
        contains('Kapelle'),
      );
    });

    test('joinSession() meldet Fehler wenn nicht eingeloggt, aber Band vorhanden', () async {
      final container = _makeContainer(
        authState: const AuthUnauthenticated(),
        activeBandId: 'band-test-123',
      );
      addTearDown(container.dispose);

      await container.read(broadcastProvider.notifier).joinSession();

      // Unauthenticated → Fehlerzustand "Nicht angemeldet"
      expect(container.read(broadcastProvider).mode, BroadcastMode.error);
      expect(container.read(broadcastProvider).error, contains('angemeldet'));
    });

    test('leaveSession() ist aufrufbar ohne musikerId-Parameter', () async {
      // RED: Compile-Fehler vor der Korrektur — "Required named parameter 'musikerId'"
      // GREEN: Kompiliert nach der Korrektur; kein Absturz bei fehlendem Session-State
      final container = _makeContainer();
      addTearDown(container.dispose);

      // leaveSession() ohne Argument — kein Absturz erwartet (keine aktive Session)
      await container.read(broadcastProvider.notifier).leaveSession();

      expect(container.read(broadcastProvider).mode, BroadcastMode.idle);
    });

    test('AuthAuthenticated liefert valide userId für Broadcast-Join', () {
      // Verifiziert dass Auth-State die richtige Musiker-ID enthält
      const userId = 'musiker-uuid-test-456';
      const authState = AuthAuthenticated(
        User(
          id: userId,
          email: 'musiker@kapelle.de',
          displayName: 'Anna Testmusikerin',
          emailVerified: true,
          onboardingCompleted: true,
        ),
      );

      final container = _makeContainer(authState: authState);
      addTearDown(container.dispose);

      final auth = container.read(authProvider);
      expect(auth, isA<AuthAuthenticated>());
      final resolvedId = (auth as AuthAuthenticated).user.id;
      expect(resolvedId, userId);
      expect(resolvedId.isEmpty, isFalse,
          reason: 'musikerId darf nicht leer sein');
    });
  });
}
