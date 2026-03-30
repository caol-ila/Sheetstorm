import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';

/// Helper: builds a ProviderContainer with an AutoScroll notifier.
(ProviderContainer, AutoScroll) _makeNotifier() {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final sub = container.listen(autoScrollProvider, (_, __) {});
  addTearDown(sub.close);

  final notifier = container.read(autoScrollProvider.notifier);
  return (container, notifier);
}

AutoScrollState _state(ProviderContainer c) => c.read(autoScrollProvider);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ─── AutoScrollState model tests ──────────────────────────────────────────

  group('AutoScrollState — defaults', () {
    test('initial state has correct defaults', () {
      const state = AutoScrollState();

      expect(state.status, AutoScrollStatus.idle);
      expect(state.mode, AutoScrollMode.manual);
      expect(state.speedFactor, 1.0);
      expect(state.bpm, 120);
      expect(state.barsPerLine, 4);
      expect(state.leadInBars, 2);
      expect(state.pauseOnTouch, true);
      expect(state.startDelaySeconds, 3.0);
    });

    test('copyWith creates new instance with changed fields', () {
      const original = AutoScrollState();
      final modified = original.copyWith(
        status: AutoScrollStatus.playing,
        speedFactor: 1.5,
        bpm: 140,
      );

      expect(modified.status, AutoScrollStatus.playing);
      expect(modified.speedFactor, 1.5);
      expect(modified.bpm, 140);
      // unchanged fields
      expect(modified.mode, AutoScrollMode.manual);
      expect(modified.barsPerLine, 4);
    });

    test('copyWith with no args returns equal state', () {
      const original = AutoScrollState(
        status: AutoScrollStatus.playing,
        speedFactor: 2.0,
      );
      final copy = original.copyWith();

      expect(copy.status, original.status);
      expect(copy.speedFactor, original.speedFactor);
      expect(copy.mode, original.mode);
    });
  });

  // ─── Speed calculation tests ──────────────────────────────────────────────

  group('AutoScrollState — speed calculations', () {
    test('manual speed: factor 1.0 at screenHeight 1000 → 100 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 1.0,
      );
      // baseSpeed = screenHeight / 10 = 100
      // manualSpeed = speedFactor * baseSpeed = 1.0 * 100 = 100
      expect(state.calculateManualSpeed(screenHeight: 1000), 100.0);
    });

    test('manual speed: factor 2.0 at screenHeight 1000 → 200 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 2.0,
      );
      expect(state.calculateManualSpeed(screenHeight: 1000), 200.0);
    });

    test('manual speed: factor 0.5 at screenHeight 800 → 40 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 0.5,
      );
      expect(state.calculateManualSpeed(screenHeight: 800), 40.0);
    });

    test('BPM speed: 120 BPM, 4 bars/line, 10 lines, 1123px page → 56.15 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 120,
        barsPerLine: 4,
      );
      // beatDuration = 60 / 120 = 0.5s
      // lineDuration = 0.5 * 4 = 2.0s
      // lineHeight = 1123 / 10 = 112.3px
      // speed = 112.3 / 2.0 = 56.15 px/s
      final speed = state.calculateBpmSpeed(
        pageHeightPx: 1123,
        estimatedLinesPerPage: 10,
      );
      expect(speed, closeTo(56.15, 0.01));
    });

    test('BPM speed: 60 BPM, 4 bars/line, 10 lines, 1000px → 25 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 60,
        barsPerLine: 4,
      );
      // beatDuration = 60 / 60 = 1.0s
      // lineDuration = 1.0 * 4 = 4.0s
      // lineHeight = 1000 / 10 = 100px
      // speed = 100 / 4 = 25 px/s
      final speed = state.calculateBpmSpeed(
        pageHeightPx: 1000,
        estimatedLinesPerPage: 10,
      );
      expect(speed, closeTo(25.0, 0.01));
    });

    test('BPM speed: 200 BPM, 2 bars/line, 8 lines, 1000px → 208.33 px/s', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 200,
        barsPerLine: 2,
      );
      // beatDuration = 60 / 200 = 0.3s
      // lineDuration = 0.3 * 2 = 0.6s
      // lineHeight = 1000 / 8 = 125px
      // speed = 125 / 0.6 = 208.33 px/s
      final speed = state.calculateBpmSpeed(
        pageHeightPx: 1000,
        estimatedLinesPerPage: 8,
      );
      expect(speed, closeTo(208.33, 0.01));
    });

    test('effectiveSpeed returns manual speed when mode is manual', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 1.5,
      );
      final speed = state.effectiveSpeed(
        screenHeight: 1000,
        pageHeightPx: 1123,
        estimatedLinesPerPage: 10,
      );
      // manual: 1.5 * (1000/10) = 150
      expect(speed, 150.0);
    });

    test('effectiveSpeed returns BPM speed when mode is bpm', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 120,
        barsPerLine: 4,
      );
      final speed = state.effectiveSpeed(
        screenHeight: 1000,
        pageHeightPx: 1123,
        estimatedLinesPerPage: 10,
      );
      expect(speed, closeTo(56.15, 0.01));
    });
  });

  // ─── AutoScrollNotifier state transition tests ────────────────────────────

  group('AutoScrollNotifier — state transitions', () {
    test('initial state is idle', () {
      final (container, _) = _makeNotifier();
      expect(_state(container).status, AutoScrollStatus.idle);
    });

    test('play() transitions from idle to playing', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      expect(_state(container).status, AutoScrollStatus.playing);
    });

    test('pause() transitions from playing to paused', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.pause();
      expect(_state(container).status, AutoScrollStatus.paused);
    });

    test('play() transitions from paused to playing', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.pause();
      notifier.play();
      expect(_state(container).status, AutoScrollStatus.playing);
    });

    test('stop() transitions from playing to idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.stop();
      expect(_state(container).status, AutoScrollStatus.idle);
    });

    test('stop() transitions from paused to idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.pause();
      notifier.stop();
      expect(_state(container).status, AutoScrollStatus.idle);
    });

    test('toggle() plays when idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.toggle();
      expect(_state(container).status, AutoScrollStatus.playing);
    });

    test('toggle() pauses when playing', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.toggle();
      expect(_state(container).status, AutoScrollStatus.paused);
    });

    test('toggle() plays when paused', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.pause();
      notifier.toggle();
      expect(_state(container).status, AutoScrollStatus.playing);
    });

    test('reset() returns to idle and resets to defaults', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.setSpeedFactor(2.5);
      notifier.reset();
      final s = _state(container);
      expect(s.status, AutoScrollStatus.idle);
    });

    test('pause() does nothing when idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.pause();
      expect(_state(container).status, AutoScrollStatus.idle);
    });

    test('stop() does nothing when idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.stop();
      expect(_state(container).status, AutoScrollStatus.idle);
    });
  });

  // ─── AutoScrollNotifier — speed/mode control ─────────────────────────────

  group('AutoScrollNotifier — speed & mode control', () {
    test('setSpeedFactor updates speed', () {
      final (container, notifier) = _makeNotifier();
      notifier.setSpeedFactor(2.0);
      expect(_state(container).speedFactor, 2.0);
    });

    test('setSpeedFactor clamps to min 0.5', () {
      final (container, notifier) = _makeNotifier();
      notifier.setSpeedFactor(0.1);
      expect(_state(container).speedFactor, 0.5);
    });

    test('setSpeedFactor clamps to max 3.0', () {
      final (container, notifier) = _makeNotifier();
      notifier.setSpeedFactor(5.0);
      expect(_state(container).speedFactor, 3.0);
    });

    test('incrementSpeed increases by 0.1', () {
      final (container, notifier) = _makeNotifier();
      notifier.incrementSpeed();
      expect(_state(container).speedFactor, closeTo(1.1, 0.001));
    });

    test('decrementSpeed decreases by 0.1', () {
      final (container, notifier) = _makeNotifier();
      notifier.decrementSpeed();
      expect(_state(container).speedFactor, closeTo(0.9, 0.001));
    });

    test('decrementSpeed does not go below 0.5', () {
      final (container, notifier) = _makeNotifier();
      notifier.setSpeedFactor(0.5);
      notifier.decrementSpeed();
      expect(_state(container).speedFactor, 0.5);
    });

    test('incrementSpeed does not go above 3.0', () {
      final (container, notifier) = _makeNotifier();
      notifier.setSpeedFactor(3.0);
      notifier.incrementSpeed();
      expect(_state(container).speedFactor, 3.0);
    });

    test('setMode switches to bpm', () {
      final (container, notifier) = _makeNotifier();
      notifier.setMode(AutoScrollMode.bpm);
      expect(_state(container).mode, AutoScrollMode.bpm);
    });

    test('setMode switches to manual', () {
      final (container, notifier) = _makeNotifier();
      notifier.setMode(AutoScrollMode.bpm);
      notifier.setMode(AutoScrollMode.manual);
      expect(_state(container).mode, AutoScrollMode.manual);
    });

    test('setBpm updates BPM value', () {
      final (container, notifier) = _makeNotifier();
      notifier.setBpm(140);
      expect(_state(container).bpm, 140);
    });

    test('setBpm clamps to min 20', () {
      final (container, notifier) = _makeNotifier();
      notifier.setBpm(5);
      expect(_state(container).bpm, 20);
    });

    test('setBpm clamps to max 300', () {
      final (container, notifier) = _makeNotifier();
      notifier.setBpm(500);
      expect(_state(container).bpm, 300);
    });

    test('setBarsPerLine updates value', () {
      final (container, notifier) = _makeNotifier();
      notifier.setBarsPerLine(6);
      expect(_state(container).barsPerLine, 6);
    });

    test('setBarsPerLine clamps 1-8', () {
      final (container, notifier) = _makeNotifier();
      notifier.setBarsPerLine(0);
      expect(_state(container).barsPerLine, 1);
      notifier.setBarsPerLine(10);
      expect(_state(container).barsPerLine, 8);
    });

    test('setLeadInBars updates value', () {
      final (container, notifier) = _makeNotifier();
      notifier.setLeadInBars(4);
      expect(_state(container).leadInBars, 4);
    });

    test('setLeadInBars clamps 0-4', () {
      final (container, notifier) = _makeNotifier();
      notifier.setLeadInBars(-1);
      expect(_state(container).leadInBars, 0);
      notifier.setLeadInBars(10);
      expect(_state(container).leadInBars, 4);
    });

    test('togglePauseOnTouch toggles the flag', () {
      final (container, notifier) = _makeNotifier();
      expect(_state(container).pauseOnTouch, true);
      notifier.togglePauseOnTouch();
      expect(_state(container).pauseOnTouch, false);
      notifier.togglePauseOnTouch();
      expect(_state(container).pauseOnTouch, true);
    });
  });

  // ─── AutoScrollNotifier — user interaction handling ───────────────────────

  group('AutoScrollNotifier — user interaction', () {
    test('onUserInteraction pauses when playing and pauseOnTouch is true', () {
      final (container, notifier) = _makeNotifier();
      notifier.play();
      notifier.onUserInteraction();
      expect(_state(container).status, AutoScrollStatus.paused);
    });

    test('onUserInteraction does nothing when pauseOnTouch is false', () {
      final (container, notifier) = _makeNotifier();
      notifier.togglePauseOnTouch(); // disable pause on touch
      notifier.play();
      notifier.onUserInteraction();
      expect(_state(container).status, AutoScrollStatus.playing);
    });

    test('onUserInteraction does nothing when idle', () {
      final (container, notifier) = _makeNotifier();
      notifier.onUserInteraction();
      expect(_state(container).status, AutoScrollStatus.idle);
    });
  });

  // ─── Convenience getters ──────────────────────────────────────────────────

  group('AutoScrollState — convenience getters', () {
    test('isPlaying returns true only when playing', () {
      expect(
        const AutoScrollState(status: AutoScrollStatus.playing).isPlaying,
        true,
      );
      expect(
        const AutoScrollState(status: AutoScrollStatus.paused).isPlaying,
        false,
      );
      expect(
        const AutoScrollState(status: AutoScrollStatus.idle).isPlaying,
        false,
      );
    });

    test('isPaused returns true only when paused', () {
      expect(
        const AutoScrollState(status: AutoScrollStatus.paused).isPaused,
        true,
      );
      expect(
        const AutoScrollState(status: AutoScrollStatus.playing).isPaused,
        false,
      );
    });

    test('isIdle returns true only when idle', () {
      expect(
        const AutoScrollState(status: AutoScrollStatus.idle).isIdle,
        true,
      );
      expect(
        const AutoScrollState(status: AutoScrollStatus.playing).isIdle,
        false,
      );
    });

    test('speedLabel shows factor for manual mode', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 1.5,
      );
      expect(state.speedLabel, '1.5×');
    });

    test('speedLabel shows BPM for bpm mode', () {
      const state = AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 120,
      );
      expect(state.speedLabel, '120 BPM');
    });
  });
}
