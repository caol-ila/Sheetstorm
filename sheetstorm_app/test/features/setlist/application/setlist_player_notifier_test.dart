import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('togglePause() kann aufgerufen werden', () {
      final (c, n) = _setup('sl1');

      n.togglePause();
      expect(true, isTrue);
    });

    test('next() kann aufgerufen werden', () {
      final (c, n) = _setup('sl1');

      n.next();
      expect(true, isTrue);
    });

    test('previous() kann aufgerufen werden', () {
      final (c, n) = _setup('sl1');

      n.previous();
      expect(true, isTrue);
    });

    test('jumpTo() kann aufgerufen werden', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(0);
      expect(true, isTrue);
    });

    test('jumpTo() mit negativem Index', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(-1);
      expect(true, isTrue);
    });

    test('jumpTo() mit großem Index', () {
      final (c, n) = _setup('sl1');

      n.jumpTo(999);
      expect(true, isTrue);
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
}
