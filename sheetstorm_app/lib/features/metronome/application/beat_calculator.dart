import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

/// Pure-math beat calculator. Given session start time, BPM, and current time,
/// calculates which beat should be playing NOW.
///
/// This is the core of the metronome sync — no network, no state, just math.
/// Designed for high testability and performance (called at ~60fps).
class BeatCalculator {
  final int bpm;
  final int beatsPerMeasure;
  final int startTimeUs;
  final int clockOffsetUs;

  const BeatCalculator({
    required this.bpm,
    required this.beatsPerMeasure,
    required this.startTimeUs,
    required this.clockOffsetUs,
  });

  /// Microseconds per beat.
  int get beatIntervalUs => (60000000 / bpm).round();

  /// Get the current beat state at the given time.
  ///
  /// [nowUs] is the local device time in microseconds since epoch.
  /// [latencyCompensationUs] is an optional per-device offset.
  BeatResult getCurrentBeat({
    required int nowUs,
    int latencyCompensationUs = 0,
  }) {
    final serverNowUs = nowUs + clockOffsetUs + latencyCompensationUs;
    final elapsedUs = serverNowUs - startTimeUs;

    if (elapsedUs < 0) {
      return BeatResult(
        beatNumber: 0,
        measure: 0,
        beatInMeasure: 0,
        isDownbeat: true,
        microsecondsToNextBeat: -elapsedUs,
      );
    }

    final interval = beatIntervalUs;
    final beatNumber = elapsedUs ~/ interval;
    final nextBeatUs = startTimeUs + (beatNumber + 1) * interval;
    final toNextUs = nextBeatUs - serverNowUs;
    final beatInMeasure = beatNumber % beatsPerMeasure;
    final measure = beatNumber ~/ beatsPerMeasure;
    final isDownbeat = beatInMeasure == 0;

    return BeatResult(
      beatNumber: beatNumber,
      measure: measure,
      beatInMeasure: beatInMeasure,
      isDownbeat: isDownbeat,
      microsecondsToNextBeat: toNextUs,
    );
  }

  /// Get a [BeatEvent] model for the current beat.
  BeatEvent getBeatEvent({
    required int nowUs,
    int latencyCompensationUs = 0,
  }) {
    final result =
        getCurrentBeat(nowUs: nowUs, latencyCompensationUs: latencyCompensationUs);
    final beatTimestampUs = startTimeUs + result.beatNumber * beatIntervalUs;

    return BeatEvent(
      beatNumber: result.beatNumber,
      timestampUs: beatTimestampUs,
      measure: result.measure,
      beatInMeasure: result.beatInMeasure,
      isDownbeat: result.isDownbeat,
    );
  }

  /// Returns a value between 0.0 and 1.0 representing progress within
  /// the current beat. Used for smooth animation interpolation.
  double progressInBeat({
    required int nowUs,
    int latencyCompensationUs = 0,
  }) {
    final serverNowUs = nowUs + clockOffsetUs + latencyCompensationUs;
    final elapsedUs = serverNowUs - startTimeUs;

    if (elapsedUs < 0) return 0.0;

    final interval = beatIntervalUs;
    final positionInBeat = elapsedUs % interval;
    return positionInBeat / interval;
  }
}

/// Result of a beat calculation (lightweight, no JSON needed).
class BeatResult {
  final int beatNumber;
  final int measure;
  final int beatInMeasure;
  final bool isDownbeat;
  final int microsecondsToNextBeat;

  const BeatResult({
    required this.beatNumber,
    required this.measure,
    required this.beatInMeasure,
    required this.isDownbeat,
    required this.microsecondsToNextBeat,
  });
}
