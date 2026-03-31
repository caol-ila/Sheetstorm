import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/application/metronome_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ─── MetronomeState - Computed Properties ────────────────────────────────────

  group('MetronomeState', () {
    test('default state has standard values (120 BPM, 4/4)', () {
      const state = MetronomeState();
      expect(state.bpm, 120);
      expect(state.beatsPerMeasure, 4);
      expect(state.beatUnit, 4);
      expect(state.currentBeat, 0);
      expect(state.isPlaying, isFalse);
      expect(state.isConductor, isFalse);
    });

    test('beatDuration calculates correctly for various BPMs', () {
      // 60 BPM → 1000ms
      const state60 = MetronomeState(bpm: 60);
      expect(state60.beatDuration, 1000);

      // 120 BPM → 500ms
      const state120 = MetronomeState(bpm: 120);
      expect(state120.beatDuration, 500);

      // 180 BPM → 333ms (rounded down from 333.33...)
      const state180 = MetronomeState(bpm: 180);
      expect(state180.beatDuration, 333);
    });

    test('isOnDownbeat is true only for beat 0', () {
      const beat0 = MetronomeState(currentBeat: 0);
      expect(beat0.isOnDownbeat, isTrue);

      const beat1 = MetronomeState(currentBeat: 1);
      expect(beat1.isOnDownbeat, isFalse);

      const beat3 = MetronomeState(currentBeat: 3);
      expect(beat3.isOnDownbeat, isFalse);
    });

    test('timeSignatureDisplay formats correctly', () {
      const state44 = MetronomeState(beatsPerMeasure: 4, beatUnit: 4);
      expect(state44.timeSignatureDisplay, '4/4');

      const state34 = MetronomeState(beatsPerMeasure: 3, beatUnit: 4);
      expect(state34.timeSignatureDisplay, '3/4');

      const state68 = MetronomeState(beatsPerMeasure: 6, beatUnit: 8);
      expect(state68.timeSignatureDisplay, '6/8');

      const state54 = MetronomeState(beatsPerMeasure: 5, beatUnit: 4);
      expect(state54.timeSignatureDisplay, '5/4');
    });
  });

  // ─── MetronomeNotifier - BPM Control ─────────────────────────────────────────

  group('MetronomeNotifier', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    group('BPM control', () {
      test('setBpm updates BPM within valid range (20-300)', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(140);
        expect(container.read(metronomeProvider).bpm, 140);
      });

      test('setBpm clamps to minimum 20', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(5);
        expect(container.read(metronomeProvider).bpm, 20);
      });

      test('setBpm clamps to maximum 300', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(999);
        expect(container.read(metronomeProvider).bpm, 300);
      });

      test('setBpm updates beatDuration accordingly', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(60);
        expect(container.read(metronomeProvider).beatDuration, 1000);

        notifier.setBpm(120);
        expect(container.read(metronomeProvider).beatDuration, 500);
      });
    });

    // ─── Time Signature ─────────────────────────────────────────────────────

    group('Time signature', () {
      test('setTimeSignature updates beatsPerMeasure and beatUnit', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setTimeSignature(3, 4);
        final state = container.read(metronomeProvider);
        expect(state.beatsPerMeasure, 3);
        expect(state.beatUnit, 4);
      });

      test('setTimeSignature resets currentBeat to 0', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        // Advance to beat 2
        notifier.tick();
        notifier.tick();
        expect(container.read(metronomeProvider).currentBeat, 2);

        // Changing time signature should reset beat
        notifier.setTimeSignature(3, 4);
        expect(container.read(metronomeProvider).currentBeat, 0);
      });

      test('common time signatures work (4/4, 3/4, 6/8, 2/4, 5/4)', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        for (final sig in [
          (4, 4),
          (3, 4),
          (6, 8),
          (2, 4),
          (5, 4),
        ]) {
          notifier.setTimeSignature(sig.$1, sig.$2);
          final state = container.read(metronomeProvider);
          expect(state.beatsPerMeasure, sig.$1,
              reason: '${sig.$1}/${sig.$2} beatsPerMeasure');
          expect(state.beatUnit, sig.$2,
              reason: '${sig.$1}/${sig.$2} beatUnit');
        }
      });
    });

    // ─── Beat Counting ──────────────────────────────────────────────────────

    group('Beat counting', () {
      test('currentBeat increments on each beat tick', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        expect(container.read(metronomeProvider).currentBeat, 0);

        notifier.tick();
        expect(container.read(metronomeProvider).currentBeat, 1);

        notifier.tick();
        expect(container.read(metronomeProvider).currentBeat, 2);
      });

      test('currentBeat wraps around at beatsPerMeasure (4/4: 0,1,2,3,0,...)',
          () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        // Default is 4/4
        notifier.tick(); // → 1
        notifier.tick(); // → 2
        notifier.tick(); // → 3
        notifier.tick(); // → wraps to 0
        expect(container.read(metronomeProvider).currentBeat, 0);

        notifier.tick(); // → 1 again
        expect(container.read(metronomeProvider).currentBeat, 1);
      });

      test('beat 0 is always the downbeat', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        expect(container.read(metronomeProvider).isOnDownbeat, isTrue);

        notifier.tick();
        expect(container.read(metronomeProvider).isOnDownbeat, isFalse);

        // Complete measure in 3/4
        notifier.setTimeSignature(3, 4);
        expect(container.read(metronomeProvider).isOnDownbeat, isTrue);
        notifier.tick();
        notifier.tick();
        notifier.tick(); // wraps → 0
        expect(container.read(metronomeProvider).isOnDownbeat, isTrue);
      });

      test('changing beatsPerMeasure resets currentBeat', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.tick();
        notifier.tick();
        notifier.tick();
        expect(container.read(metronomeProvider).currentBeat, 3);

        notifier.setTimeSignature(3, 4);
        expect(container.read(metronomeProvider).currentBeat, 0);
      });
    });

    // ─── Start / Stop ───────────────────────────────────────────────────────

    group('Start/Stop', () {
      test('startMetronome sets isPlaying to true', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startMetronome();
        expect(container.read(metronomeProvider).isPlaying, isTrue);
      });

      test('stopMetronome sets isPlaying to false', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startMetronome();
        notifier.stopMetronome();
        expect(container.read(metronomeProvider).isPlaying, isFalse);
      });

      test('stopMetronome resets currentBeat to 0', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startMetronome();
        notifier.tick();
        notifier.tick();
        expect(container.read(metronomeProvider).currentBeat, 2);

        notifier.stopMetronome();
        expect(container.read(metronomeProvider).currentBeat, 0);
      });

      test('starting while already playing has no effect', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startMetronome();
        notifier.tick();
        notifier.tick(); // currentBeat = 2

        notifier.startMetronome(); // should NOT reset beat
        expect(container.read(metronomeProvider).currentBeat, 2);
        expect(container.read(metronomeProvider).isPlaying, isTrue);
      });

      test('stopping while already stopped has no effect', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        expect(container.read(metronomeProvider).isPlaying, isFalse);
        notifier.stopMetronome(); // should not throw or change state
        expect(container.read(metronomeProvider).isPlaying, isFalse);
        expect(container.read(metronomeProvider).currentBeat, 0);
      });
    });

    // ─── Tap Tempo ──────────────────────────────────────────────────────────

    group('Tap tempo', () {
      test('single tap does nothing (need at least 2)', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.tap(timestampMs: 0);
        // BPM remains at default
        expect(container.read(metronomeProvider).bpm, 120);
      });

      test('two taps calculate BPM from interval (500ms apart → 120 BPM)', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.tap(timestampMs: 0);
        notifier.tap(timestampMs: 500);
        expect(container.read(metronomeProvider).bpm, 120);
      });

      test('multiple taps average the intervals (4 taps at 500ms → 120 BPM)',
          () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.tap(timestampMs: 0);
        notifier.tap(timestampMs: 500);
        notifier.tap(timestampMs: 1000);
        notifier.tap(timestampMs: 1500);
        expect(container.read(metronomeProvider).bpm, 120);
      });

      test('taps more than 2 seconds apart reset the sequence', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        // First pair gives 60 BPM
        notifier.tap(timestampMs: 0);
        notifier.tap(timestampMs: 1000);
        expect(container.read(metronomeProvider).bpm, 60);

        // 2s gap resets — next single tap after the gap starts fresh
        notifier.tap(timestampMs: 4000); // > 2s from last → resets
        expect(container.read(metronomeProvider).bpm, 60); // unchanged

        // Now one more tap at 500ms → 120 BPM from the fresh sequence
        notifier.tap(timestampMs: 4500);
        expect(container.read(metronomeProvider).bpm, 120);
      });

      test('calculated BPM is clamped to valid range', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        // Very fast taps (< 20ms per beat would exceed 300 BPM)
        notifier.tap(timestampMs: 0);
        notifier.tap(timestampMs: 10); // 6000 BPM unclamped → 300
        expect(container.read(metronomeProvider).bpm, 300);
      });

      test('tap tempo updates BPM in state', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(80); // start at non-default
        notifier.tap(timestampMs: 0);
        notifier.tap(timestampMs: 600); // ~100 BPM
        expect(container.read(metronomeProvider).bpm, 100);
      });
    });

    // ─── MetronomeBeatPayload Generation ────────────────────────────────────

    group('MetronomeBeatPayload generation', () {
      test('generated payload has correct BPM', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(90);
        final payload = notifier.generateBeatPayload(sessionTimeMs: 1000);
        expect(payload.bpm, 90);
      });

      test('generated payload has correct time signature', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setTimeSignature(3, 4);
        final payload = notifier.generateBeatPayload(sessionTimeMs: 0);
        expect(payload.beatsPerMeasure, 3);
        expect(payload.beatUnit, 4);
      });

      test('generated payload has the provided beatTimestampMs', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        final payload = notifier.generateBeatPayload(sessionTimeMs: 5000);
        expect(payload.beatTimestampMs, 5000);
      });

      test('nextBeatMs equals beatTimestampMs + beatDuration', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(120); // beatDuration = 500ms
        final payload = notifier.generateBeatPayload(sessionTimeMs: 2000);
        expect(payload.nextBeatMs, 2000 + 500);
      });

      test('beatNumberInMeasure matches currentBeat', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.tick();
        notifier.tick(); // currentBeat = 2
        final payload = notifier.generateBeatPayload(sessionTimeMs: 0);
        expect(payload.beatNumberInMeasure, 2);
      });
    });

    // ─── Conductor vs Musician Mode ─────────────────────────────────────────

    group('Conductor vs Musician mode', () {
      test('conductor mode: isPlaying + isConductor both true', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startAsConductor();
        final state = container.read(metronomeProvider);
        expect(state.isPlaying, isTrue);
        expect(state.isConductor, isTrue);
      });

      test('musician mode: receives beats, isConductor is false', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startAsMusician();
        final state = container.read(metronomeProvider);
        expect(state.isConductor, isFalse);
      });

      test('received beat updates state (bpm, currentBeat)', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startAsMusician();

        final incomingBeat = MetronomeBeatPayload(
          bpm: 96,
          beatsPerMeasure: 3,
          beatUnit: 4,
          beatTimestampMs: 5000,
          beatNumberInMeasure: 1,
          nextBeatMs: 5625,
        );

        notifier.receiveBeat(incomingBeat);

        final state = container.read(metronomeProvider);
        expect(state.bpm, 96);
        expect(state.currentBeat, 1);
        expect(state.beatsPerMeasure, 3);
        expect(state.beatUnit, 4);
      });

      test('received beat with different BPM updates local BPM', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.startAsMusician();

        final incomingBeat = MetronomeBeatPayload(
          bpm: 72,
          beatsPerMeasure: 4,
          beatUnit: 4,
          beatTimestampMs: 0,
          beatNumberInMeasure: 0,
          nextBeatMs: 833,
        );

        notifier.receiveBeat(incomingBeat);
        expect(container.read(metronomeProvider).bpm, 72);
      });
    });
  });
}
