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
  final int currentBeat; // 0-based within measure
  final bool isPlaying;
  final bool isConductor; // true = sends beats; false = receives
  final DateTime? sessionStartTime;

  const MetronomeState({
    this.bpm = 120,
    this.beatsPerMeasure = 4,
    this.beatUnit = 4,
    this.currentBeat = 0,
    this.isPlaying = false,
    this.isConductor = false,
    this.sessionStartTime,
  });

  int get beatDuration => (60000 / bpm).round();
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

  // Tap tempo tracking (stores millisecond timestamps)
  final List<int> _tapTimestampsMs = [];

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

  /// Alias for [startMetronome] — sets conductor mode.
  void startAsConductor() => startMetronome();

  void stopMetronome() {
    _cancelTimer();
    state = state.copyWith(
      isPlaying: false,
      currentBeat: 0,
    );
  }

  void setBpm(int bpm) {
    final clamped = bpm.clamp(20, 300);
    state = state.copyWith(bpm: clamped);
    // Reschedule if running — next beat picks up new BPM automatically
  }

  void setTimeSignature(int beats, int unit) {
    state = state.copyWith(
      beatsPerMeasure: beats,
      beatUnit: unit,
      currentBeat: 0,
    );
  }

  /// Advance the beat counter by one step (wraps at beatsPerMeasure).
  /// Used by the timer callback and available publicly for testing.
  void tick() {
    final nextBeat = (state.currentBeat + 1) % state.beatsPerMeasure;
    state = state.copyWith(currentBeat: nextBeat);
  }

  /// Calculate BPM from consecutive taps using an explicit timestamp.
  void tap({required int timestampMs}) {
    // Reset if last tap was more than 2 seconds ago
    if (_tapTimestampsMs.isNotEmpty &&
        timestampMs - _tapTimestampsMs.last > 2000) {
      _tapTimestampsMs.clear();
    }

    _tapTimestampsMs.add(timestampMs);

    // Keep last 8 taps
    if (_tapTimestampsMs.length > 8) {
      _tapTimestampsMs.removeAt(0);
    }

    if (_tapTimestampsMs.length < 2) return;

    final intervals = <int>[];
    for (var i = 1; i < _tapTimestampsMs.length; i++) {
      intervals.add(_tapTimestampsMs[i] - _tapTimestampsMs[i - 1]);
    }

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    final newBpm = (60000 / avgInterval).round().clamp(20, 300);
    setBpm(newBpm);
  }

  /// Tap tempo using wall-clock time — for use from the UI.
  void tapTempo() =>
      tap(timestampMs: DateTime.now().millisecondsSinceEpoch);

  /// Build a [MetronomeBeatPayload] from the current state.
  MetronomeBeatPayload generateBeatPayload({required int sessionTimeMs}) {
    return MetronomeBeatPayload(
      bpm: state.bpm,
      beatsPerMeasure: state.beatsPerMeasure,
      beatUnit: state.beatUnit,
      beatTimestampMs: sessionTimeMs,
      beatNumberInMeasure: state.currentBeat,
      nextBeatMs: sessionTimeMs + state.beatDuration,
    );
  }

  // ─── Musician Methods ──────────────────────────────────────────────────

  /// Enter musician (receiver) mode and subscribe to BLE beats.
  void startReceiving() {
    _beatSubscription?.cancel();
    state = state.copyWith(isConductor: false, isPlaying: true);
    _beatSubscription = _ble.onMetronomeBeat.listen(_onBeatReceived);
  }

  /// Enter musician mode without subscribing to BLE — useful in tests.
  void startAsMusician() {
    state = state.copyWith(isConductor: false, isPlaying: true);
  }

  void stopReceiving() {
    _beatSubscription?.cancel();
    _beatSubscription = null;
    state = state.copyWith(isPlaying: false, currentBeat: 0);
  }

  /// Apply an incoming beat payload to the local state.
  /// Public so it can be called from tests and external callers.
  void receiveBeat(MetronomeBeatPayload payload) => _onBeatReceived(payload);

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

    tick();
    _beatCount++;

    // Broadcast via BLE transport — wrapped so test environments without BLE
    // don't crash (BLE provider will throw if not overridden in tests).
    try {
      final payload = MetronomeBeatPayload(
        bpm: state.bpm,
        beatsPerMeasure: state.beatsPerMeasure,
        beatUnit: state.beatUnit,
        beatTimestampMs: elapsedMs,
        beatNumberInMeasure: state.currentBeat,
        nextBeatMs: elapsedMs + state.beatDuration,
      );
      _ble.sendMetronomeBeat(payload);
    } catch (_) {
      // BLE not available (e.g., test environment)
    }

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
