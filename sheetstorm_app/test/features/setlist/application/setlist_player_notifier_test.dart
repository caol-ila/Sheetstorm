import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/setlist/application/setlist_player_notifier.dart';

(ProviderContainer, SetlistPlayerNotifier) _setup(String setlistId) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(setlistPlayerProvider(setlistId).notifier);
  return (container, notifier);
}

SetlistPlayerState _state(ProviderContainer c, String setlistId) =>
    c.read(setlistPlayerProvider(setlistId));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SetlistPlayerNotifier — Grundfunktionen', () {
    test('Player startet im idle-Status', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.status, PlayerStatus.idle);
      expect(state.data, isNull);
      expect(state.currentIndex, 0);
    });

    test('Initial State hat autoAdvance false', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.autoAdvance, isFalse);
    });

    test('Initial State hat keinen Fehler', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.error, isNull);
    });

    test('togglePause() hat keinen Effekt im idle-Zustand', () {
      final (c, n) = _setup('sl1');

      n.togglePause();

      final state = _state(c, 'sl1');
      expect(state.status, PlayerStatus.idle);
    });

    test('next() erhöht currentIndex bei leerer Liste', () {
      final (c, n) = _setup('sl1');

      n.next();

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 1); // isLast=false wenn leer → Index erhöht sich
    });

    test('previous() ändert Index nicht bei Position 0', () {
      final (c, n) = _setup('sl1');

      n.previous();

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 0); // isFirst=true bei Index 0 → kein Rücksprung
    });

    test('jumpTo() ändert Index nicht bei leerer Liste', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(0);

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 0); // totalPlayable=0 → alle Indizes außerhalb Bereich
    });

    test('jumpTo() mit negativem Index hat keinen Effekt', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(-1);

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 0); // negativer Index → returns early
    });

    test('jumpTo() mit Index außerhalb Bereich hat keinen Effekt', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(999);

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 0); // Index > totalPlayable → returns early
    });

    test('toggleAutoAdvance() schaltet autoAdvance ein', () {
      final (c, n) = _setup('sl1');

      n.toggleAutoAdvance();

      final state = _state(c, 'sl1');
      expect(state.autoAdvance, isTrue);
    });

    test('toggleAutoAdvance() zweimal schaltet wieder aus', () {
      final (c, n) = _setup('sl1');

      n.toggleAutoAdvance();
      n.toggleAutoAdvance();

      final state = _state(c, 'sl1');
      expect(state.autoAdvance, isFalse);
    });

    test('restart() setzt Player zurück', () {
      final (c, n) = _setup('sl1');

      n.restart();

      final state = _state(c, 'sl1');
      expect(state.status, PlayerStatus.playing);
      expect(state.currentIndex, 0);
    });

    test('stop() setzt Player auf idle zurück', () {
      final (c, n) = _setup('sl1');

      n.stop();

      final state = _state(c, 'sl1');
      expect(state.status, PlayerStatus.idle);
      expect(state.data, isNull);
    });

    test('startPlaying() kann aufgerufen werden', () async {
      final (c, n) = _setup('sl1');

      await n.startPlaying();

      // Without real service, will go to idle with error
      final state = _state(c, 'sl1');
      expect(state.status, anyOf(PlayerStatus.idle, PlayerStatus.loading));
    });

    test('startPlaying() mit stimmeId Parameter', () async {
      final (c, n) = _setup('sl1');

      await n.startPlaying(stimmeId: 'voice1');

      final state = _state(c, 'sl1');
      expect(state.status, anyOf(PlayerStatus.idle, PlayerStatus.loading));
    });
  });

  group('SetlistPlayerState — Eigenschaften', () {
    test('isFirst ist true bei Index 0', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.isFirst, isTrue);
    });

    test('isLast ist false bei leerem Player', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.isLast, isFalse);
    });

    test('totalPlayable ist 0 ohne Daten', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.totalPlayable, 0);
    });

    test('currentStueck ist null ohne Daten', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.currentStueck, isNull);
    });

    test('progressLabel ist leer ohne Daten', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');
      expect(state.progressLabel, '');
    });
  });

  // ─── Leere Liste — Edge Cases (#117) ─────────────────────────────────────────

  group('SetlistPlayerNotifier — Leere Liste (Edge Cases)', () {
    test('SetlistWithZeroItems_IsLast_ReturnsFalse', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');

      expect(state.totalPlayable, 0);
      expect(state.isLast, isFalse); // isLast nur true wenn totalPlayable > 0
    });

    test('SetlistNavigation_EmptyList_DoesNotCrash', () {
      final (c, n) = _setup('sl1');

      n.next();    // isLast=false → currentIndex wird 1
      n.previous(); // isFirst=false (index 1 > 0) → currentIndex wird 0
      n.jumpTo(0);  // totalPlayable=0 → returns early
      n.jumpTo(-1); // negativ → returns early
      n.jumpTo(999); // außerhalb → returns early

      final state = _state(c, 'sl1');
      expect(state.currentIndex, 0);
      expect(state.status, PlayerStatus.idle);
    });

    test('SetlistWithZeroItems_ProgressLabel_IsEmpty', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');

      expect(state.progressLabel, isEmpty); // keine Division durch null
    });

    test('SetlistWithZeroItems_CurrentStueck_IsNull', () {
      final (c, _) = _setup('sl1');

      final state = _state(c, 'sl1');

      expect(state.currentStueck, isNull); // kein Zugriff auf leere Liste
    });
  });
}
