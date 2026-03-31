import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_broadcast_service.dart';

part 'metronome_notifier.g.dart';

// ─── Metronome State ──────────────────────────────────────────────────────────

class MetronomeState {
  final int bpm;
  final int beatsPerMeasure;
  final int beatUnit;
  final int currentBeat; // 0-based within measure; -1 = none active
  final bool isPlaying;
  final bool isConductor; // true = sends beats; false = receives
  final DateTime? sessionStartTime;

  const MetronomeState({
    this.bpm = 120,
    this.beatsPerMeasure = 4,
    this.beatUnit = 4,
    this.currentBeat = -1,
    this.isPlaying = false,
    this.isConductor = false,
    this.sessionStartTime,
  });

  Duration get beatDuration => Duration(milliseconds: (60000 / bpm).round());
  bool get isOnDownbeat => currentBeat == 0;
  String get timeSignatureDisplay => '$beatsPerMeasure/$beatUnit';

  MetronomeState copyWith({
    int? bpm,
    int? beatsPerMeasure,
    int? beatUnit,
    int? currentBeat,
    bool? isPlaying,
    bool? isConductor,
    DateTime? sessionStartTime,
  }) =>
      MetronomeState(
        bpm: bpm ?? this.bpm,
        beatsPerMeasure: beatsPerMeasure ?? this.beatsPerMeasure,
        beatUnit: beatUnit ?? this.beatUnit,
        currentBeat: currentBeat ?? this.currentBeat,
        isPlaying: isPlaying ?? this.isPlaying,
        isConductor: isConductor ?? this.isConductor,
        sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      );
}

// ─── Metronome Notifier ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class MetronomeNotifier extends _$MetronomeNotifier {
  Timer? _beatTimer;
  Stopwatch? _stopwatch;
  int _beatCount = 0; // total beats since session start

  // Tap tempo tracking
  final List<DateTime> _tapTimestamps = [];

  StreamSubscription<MetronomeBeatPayload>? _beatSubscription;

  @override
  MetronomeState build() {
    ref.onDispose(_dispose);
    return const MetronomeState();
  }

  BleBroadcastService get _ble => ref.read(bleBroadcastServiceProvider);

  // ─── Conductor Methods ─────────────────────────────────────────────────

  void startMetronome() {
    if (state.isPlaying) return;

    final sessionStart = DateTime.now();
    _beatCount = 0;
    _stopwatch = Stopwatch()..start();

    state = state.copyWith(
      isPlaying: true,
      isConductor: true,
      currentBeat: 0,
      sessionStartTime: sessionStart,
    );

    _scheduleBeat();
  }

  void stopMetronome() {
    _cancelTimer();
    state = state.copyWith(
      isPlaying: false,
      currentBeat: -1,
    );
  }

  void setBpm(int bpm) {
    final clamped = bpm.clamp(20, 300);
    state = state.copyWith(bpm: clamped);
    // Reschedule if running — next beat picks up new BPM automatically
  }

  void setTimeSignature(int beats, int unit) {
    state = state.copyWith(beatsPerMeasure: beats, beatUnit: unit);
  }

  /// Calculate BPM from consecutive taps (tap tempo).
  void tapTempo() {
    final now = DateTime.now();

    // Reset if last tap was more than 2 seconds ago
    if (_tapTimestamps.isNotEmpty &&
        now.difference(_tapTimestamps.last).inMilliseconds > 2000) {
      _tapTimestamps.clear();
    }

    _tapTimestamps.add(now);

    // Keep last 8 taps
    if (_tapTimestamps.length > 8) {
      _tapTimestamps.removeAt(0);
    }

    if (_tapTimestamps.length < 2) return;

    final intervals = <int>[];
    for (var i = 1; i < _tapTimestamps.length; i++) {
      intervals.add(
        _tapTimestamps[i].difference(_tapTimestamps[i - 1]).inMilliseconds,
      );
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final newBpm = (60000 / avgInterval).round().clamp(20, 300);
    setBpm(newBpm);
  }

  // ─── Musician Methods ──────────────────────────────────────────────────

  void startReceiving() {
    _beatSubscription?.cancel();
    state = state.copyWith(isConductor: false, isPlaying: true);
    _beatSubscription = _ble.onMetronomeBeat.listen(_onBeatReceived);
  }

  void stopReceiving() {
    _beatSubscription?.cancel();
    _beatSubscription = null;
    state = state.copyWith(isPlaying: false, currentBeat: -1);
  }

  // ─── Internal Beat Logic ───────────────────────────────────────────────

  void _scheduleBeat() {
    _cancelTimer();
    if (!state.isPlaying) return;

    final beatDurationMs = (60000 / state.bpm).round();

    // Drift-compensated scheduling: calculate ideal next beat offset from
    // session start, then compute delay relative to current elapsed time.
    final elapsedMs = _stopwatch?.elapsedMilliseconds ?? 0;
    final nextBeatNumber = _beatCount + 1;
    final idealNextMs = nextBeatNumber * beatDurationMs;
    final delayMs = (idealNextMs - elapsedMs).clamp(0, beatDurationMs);

    _beatTimer = Timer(Duration(milliseconds: delayMs), _onBeatTick);
  }

  void _onBeatTick() {
    if (!state.isPlaying) return;

    final elapsedMs = _stopwatch?.elapsedMilliseconds ?? 0;
    final beatInMeasure = _beatCount % state.beatsPerMeasure;
    final beatDurationMs = (60000 / state.bpm).round();
    final nextBeatMs = elapsedMs + beatDurationMs;

    state = state.copyWith(currentBeat: beatInMeasure);
    _beatCount++;

    // Broadcast via BLE transport
    final payload = MetronomeBeatPayload(
      bpm: state.bpm,
      beatsPerMeasure: state.beatsPerMeasure,
      beatUnit: state.beatUnit,
      beatTimestampMs: elapsedMs,
      beatNumberInMeasure: beatInMeasure,
      nextBeatMs: nextBeatMs,
    );
    _ble.sendMetronomeBeat(payload);

    _scheduleBeat();
  }

  void _onBeatReceived(MetronomeBeatPayload payload) {
    state = state.copyWith(
      bpm: payload.bpm,
      beatsPerMeasure: payload.beatsPerMeasure,
      beatUnit: payload.beatUnit,
      currentBeat: payload.beatNumberInMeasure,
    );
  }

  void _cancelTimer() {
    _beatTimer?.cancel();
    _beatTimer = null;
  }

  void _dispose() {
    _cancelTimer();
    _stopwatch?.stop();
    _beatSubscription?.cancel();
  }
}
