import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/metronome/application/beat_calculator.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

void main() {
  group('BeatCalculator', () {
    group('beatIntervalUs', () {
      test('120 BPM = 500000 microseconds per beat', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        expect(calc.beatIntervalUs, 500000);
      });

      test('60 BPM = 1000000 microseconds per beat', () {
        final calc = const BeatCalculator(
          bpm: 60,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        expect(calc.beatIntervalUs, 1000000);
      });

      test('240 BPM = 250000 microseconds per beat', () {
        final calc = const BeatCalculator(
          bpm: 240,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        expect(calc.beatIntervalUs, 250000);
      });
    });

    group('getCurrentBeat', () {
      test('returns beat 0 before start time', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 1000000,
          clockOffsetUs: 0,
        );
        // nowUs = 500000, which is before startTimeUs = 1000000
        final result = calc.getCurrentBeat(nowUs: 500000);
        expect(result.beatNumber, 0);
        expect(result.isDownbeat, true);
        expect(result.microsecondsToNextBeat, 500000); // 1000000 - 500000
      });

      test('returns beat 0 at exactly start time', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 1000000,
          clockOffsetUs: 0,
        );
        final result = calc.getCurrentBeat(nowUs: 1000000);
        expect(result.beatNumber, 0);
        expect(result.isDownbeat, true);
      });

      test('returns correct beat number after start', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // At 120 BPM, beat interval = 500000us
        // At 1250000us we're in beat 2 (0-indexed)
        final result = calc.getCurrentBeat(nowUs: 1250000);
        expect(result.beatNumber, 2);
        expect(result.beatInMeasure, 2);
        expect(result.measure, 0);
        expect(result.isDownbeat, false);
      });

      test('identifies downbeat correctly in 4/4', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );

        // Beat 0 = downbeat (beat 0 of measure 0)
        expect(
            calc.getCurrentBeat(nowUs: 0).isDownbeat, true);
        // Beat 1 = not downbeat
        expect(
            calc.getCurrentBeat(nowUs: 500001).isDownbeat, false);
        // Beat 4 = downbeat (beat 0 of measure 1)
        expect(
            calc.getCurrentBeat(nowUs: 2000001).isDownbeat, true);
      });

      test('identifies downbeat correctly in 3/4', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 3,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // Beat 0: downbeat
        expect(calc.getCurrentBeat(nowUs: 0).isDownbeat, true);
        // Beat 1: not downbeat
        expect(calc.getCurrentBeat(nowUs: 500001).isDownbeat, false);
        // Beat 2: not downbeat
        expect(calc.getCurrentBeat(nowUs: 1000001).isDownbeat, false);
        // Beat 3: downbeat (measure 1)
        expect(calc.getCurrentBeat(nowUs: 1500001).isDownbeat, true);
      });

      test('calculates measure number correctly', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // Beat 7 = measure 1, beat in measure 3
        // At beat 7: elapsed = 7 * 500000 = 3500000
        final result = calc.getCurrentBeat(nowUs: 3500001);
        expect(result.beatNumber, 7);
        expect(result.measure, 1);
        expect(result.beatInMeasure, 3);
      });

      test('calculates microseconds to next beat', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // Half way through beat 0 (at 250000us)
        final result = calc.getCurrentBeat(nowUs: 250000);
        expect(result.beatNumber, 0);
        expect(result.microsecondsToNextBeat, 250000);
      });

      test('applies clock offset', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 100000, // Server is 100ms ahead
        );
        // Local time 400000, server time = 400000 + 100000 = 500000
        // At server time 500000, beat = 500000 / 500000 = 1
        final result = calc.getCurrentBeat(nowUs: 400000);
        expect(result.beatNumber, 1);
      });

      test('applies latency compensation', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // With +10ms compensation, effective time = nowUs + 10000
        // At 490000 + 10000 = 500000 → beat 1
        final result =
            calc.getCurrentBeat(nowUs: 490000, latencyCompensationUs: 10000);
        expect(result.beatNumber, 1);
      });
    });

    group('getBeatEvent', () {
      test('returns BeatEvent with all fields', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        final event = calc.getBeatEvent(nowUs: 1250000);
        expect(event, isA<BeatEvent>());
        expect(event.beatNumber, 2);
        expect(event.measure, 0);
        expect(event.beatInMeasure, 2);
        expect(event.isDownbeat, false);
        expect(event.timestampUs, 1000000); // Beat 2 starts at 2*500000
      });

      test('BeatEvent timestamp is the beat start time', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 1000000,
          clockOffsetUs: 0,
        );
        // At 2250000, elapsed = 1250000, beat = 2
        // Beat 2 timestamp = startTimeUs + 2 * 500000 = 2000000
        final event = calc.getBeatEvent(nowUs: 2250000);
        expect(event.beatNumber, 2);
        expect(event.timestampUs, 2000000);
      });
    });

    group('progressInBeat', () {
      test('returns 0.0 at beat start', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        final progress = calc.progressInBeat(nowUs: 0);
        expect(progress, closeTo(0.0, 0.01));
      });

      test('returns 0.5 at midpoint', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        final progress = calc.progressInBeat(nowUs: 250000);
        expect(progress, closeTo(0.5, 0.01));
      });

      test('returns close to 1.0 near end of beat', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        final progress = calc.progressInBeat(nowUs: 499000);
        expect(progress, greaterThan(0.9));
        expect(progress, lessThan(1.0));
      });

      test('returns 0.0 before start time', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 1000000,
          clockOffsetUs: 0,
        );
        final progress = calc.progressInBeat(nowUs: 500000);
        expect(progress, 0.0);
      });
    });

    group('edge cases', () {
      test('very high BPM (300)', () {
        final calc = const BeatCalculator(
          bpm: 300,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // 300 BPM = 200000us per beat
        expect(calc.beatIntervalUs, 200000);
        final result = calc.getCurrentBeat(nowUs: 600001);
        expect(result.beatNumber, 3);
      });

      test('very low BPM (20)', () {
        final calc = const BeatCalculator(
          bpm: 20,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: 0,
        );
        // 20 BPM = 3000000us per beat
        expect(calc.beatIntervalUs, 3000000);
        final result = calc.getCurrentBeat(nowUs: 3000001);
        expect(result.beatNumber, 1);
      });

      test('negative clock offset', () {
        final calc = const BeatCalculator(
          bpm: 120,
          beatsPerMeasure: 4,
          startTimeUs: 0,
          clockOffsetUs: -200000, // Server is 200ms behind local
        );
        // Local time 700000, server time = 700000 - 200000 = 500000 → beat 1
        final result = calc.getCurrentBeat(nowUs: 700000);
        expect(result.beatNumber, 1);
      });
    });
  });
}
