import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/metronome/application/beat_calculator.dart';
import 'package:sheetstorm/features/metronome/application/clock_sync_service.dart';
import 'package:sheetstorm/features/metronome/data/metronome_connection_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

part 'metronome_notifier.g.dart';

/// Main notifier for the metronome feature.
///
/// Manages conductor and musician modes, beat calculation, and connection state.
/// Uses [BeatCalculator] for pure-math beat scheduling and
/// [ClockSyncService] for NTP-like time synchronization.
@Riverpod(keepAlive: true)
class MetronomeNotifier extends _$MetronomeNotifier {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Timer? _beatTimer;
  BeatCalculator? _calculator;
  final ClockSyncService _clockSync = ClockSyncService();

  @override
  MetronomeState build() {
    ref.onDispose(_cleanup);
    return const MetronomeState();
  }

  MetronomeSignalRService get _signalR =>
      ref.read(metronomeSignalRServiceProvider);

  String? get _bandId => ref.read(activeBandProvider);

  // ─── Conductor commands ─────────────────────────────────────────────────

  /// Start metronome as conductor.
  Future<void> startAsConductor({
    required int bpm,
    required TimeSignature timeSignature,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return;

    state = state.copyWith(
      isConductor: true,
      bpm: bpm,
      timeSignature: timeSignature,
      isPlaying: true,
    );

    await _ensureConnected();

    _signalR.startSession(
      bandId: bandId,
      bpm: bpm,
      beatsPerMeasure: timeSignature.beatsPerMeasure,
      beatUnit: timeSignature.beatUnit,
    );
  }

  /// Stop the metronome (conductor only).
  void stop() {
    final bandId = _bandId;
    if (bandId == null) return;

    _stopBeatTimer();
    _calculator = null;

    if (state.isConductor) {
      _signalR.stopSession(bandId);
    }

    state = state.copyWith(
      isPlaying: false,
      session: null,
      currentBeat: null,
    );
  }

  /// Change BPM while playing (conductor only).
  void changeBpm(int newBpm) {
    final bandId = _bandId;
    if (bandId == null || !state.isConductor) return;

    state = state.copyWith(bpm: newBpm.clamp(20, 300));

    if (state.isPlaying) {
      _signalR.updateSession(
        bandId: bandId,
        bpm: state.bpm,
        beatsPerMeasure: state.timeSignature.beatsPerMeasure,
        beatUnit: state.timeSignature.beatUnit,
      );
    }
  }

  /// Change time signature (conductor only).
  void changeTimeSignature(TimeSignature ts) {
    final bandId = _bandId;
    if (bandId == null || !state.isConductor) return;

    state = state.copyWith(timeSignature: ts);

    if (state.isPlaying) {
      _signalR.updateSession(
        bandId: bandId,
        bpm: state.bpm,
        beatsPerMeasure: ts.beatsPerMeasure,
        beatUnit: ts.beatUnit,
      );
    }
  }

  // ─── Musician commands ──────────────────────────────────────────────────

  /// Join a session as musician (passive receiver).
  Future<void> joinAsMusician() async {
    final bandId = _bandId;
    if (bandId == null) return;

    state = state.copyWith(isConductor: false);

    await _ensureConnected();
    _signalR.joinSession(bandId);
  }

  /// Leave the current session.
  void leave() {
    final bandId = _bandId;
    if (bandId == null) return;

    _stopBeatTimer();
    _calculator = null;

    _signalR.leaveSession(bandId);

    state = const MetronomeState();
  }

  // ─── Settings ───────────────────────────────────────────────────────────

  /// Toggle audio click on/off.
  void toggleAudioClick() {
    state = state.copyWith(audioClickEnabled: !state.audioClickEnabled);
  }

  /// Set latency compensation in milliseconds.
  void setLatencyCompensation(int ms) {
    state = state.copyWith(
      latencyCompensationMs: ms.clamp(-100, 100),
    );
  }

  /// Set BPM (for conductor UI before starting).
  void setBpm(int bpm) {
    state = state.copyWith(bpm: bpm.clamp(20, 300));
  }

  /// Set time signature (for conductor UI before starting).
  void setTimeSignature(TimeSignature ts) {
    state = state.copyWith(timeSignature: ts);
  }

  // ─── Connection management ──────────────────────────────────────────────

  Future<void> _ensureConnected() async {
    if (_signalR.connectionState == MetronomeConnectionState.connected) return;

    _subscriptions.addAll([
      _signalR.onSessionStarted.listen(_onSessionStarted),
      _signalR.onSessionStopped.listen(_onSessionStopped),
      _signalR.onSessionUpdated.listen(_onSessionUpdated),
      _signalR.onClockSyncResponse.listen(_onClockSyncResponse),
      _signalR.onParticipantCountChanged.listen(_onParticipantCount),
      _signalR.onConnectionStateChanged.listen(_onConnectionStateChanged),
    ]);

    await _signalR.connect();

    state = state.copyWith(
      transport: MetronomeTransport.websocket,
      connectionState: MetronomeConnectionState.connected,
    );
  }

  // ─── Event handlers ─────────────────────────────────────────────────────

  void _onSessionStarted(MetronomeSession session) {
    _calculator = BeatCalculator(
      bpm: session.bpm,
      beatsPerMeasure: session.timeSignature.beatsPerMeasure,
      startTimeUs: session.startTimeUs,
      clockOffsetUs: _clockSync.state.serverOffsetUs,
    );

    state = state.copyWith(
      isPlaying: true,
      bpm: session.bpm,
      timeSignature: session.timeSignature,
      session: session,
      connectedClients: session.connectedClients,
    );

    _startBeatTimer();
  }

  void _onSessionStopped(String sessionId) {
    _stopBeatTimer();
    _calculator = null;
    state = state.copyWith(
      isPlaying: false,
      session: null,
      currentBeat: null,
    );
  }

  void _onSessionUpdated(SessionUpdatePayload payload) {
    _calculator = BeatCalculator(
      bpm: payload.bpm,
      beatsPerMeasure: payload.beatsPerMeasure,
      startTimeUs: payload.newStartTimeUs,
      clockOffsetUs: _clockSync.state.serverOffsetUs,
    );

    state = state.copyWith(
      bpm: payload.bpm,
      timeSignature: TimeSignature(
        beatsPerMeasure: payload.beatsPerMeasure,
        beatUnit: payload.beatUnit,
      ),
    );
  }

  void _onClockSyncResponse(ClockSyncResponsePayload payload) {
    final clientRecvTimeUs = DateTime.now().microsecondsSinceEpoch;
    final result = _clockSync.calculateOffset(
      clientSendTimeUs: payload.clientSendTimeUs,
      serverRecvTimeUs: payload.serverRecvTimeUs,
      serverSendTimeUs: payload.serverSendTimeUs,
      clientRecvTimeUs: clientRecvTimeUs,
    );
    _clockSync.addMeasurement(
      offsetUs: result.offsetUs,
      roundTripUs: result.roundTripUs,
    );

    // Update calculator with new offset
    if (_calculator != null) {
      _calculator = BeatCalculator(
        bpm: _calculator!.bpm,
        beatsPerMeasure: _calculator!.beatsPerMeasure,
        startTimeUs: _calculator!.startTimeUs,
        clockOffsetUs: _clockSync.state.serverOffsetUs,
      );
    }
  }

  void _onParticipantCount(int count) {
    state = state.copyWith(connectedClients: count);
  }

  void _onConnectionStateChanged(MetronomeConnectionState connState) {
    state = state.copyWith(connectionState: connState);
  }

  // ─── Beat timer ─────────────────────────────────────────────────────────

  void _startBeatTimer() {
    _stopBeatTimer();
    // ~60fps beat calculation for smooth animation
    _beatTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _tickBeat();
    });
  }

  void _tickBeat() {
    if (_calculator == null) return;

    final nowUs = DateTime.now().microsecondsSinceEpoch;
    final compensationUs = state.latencyCompensationMs * 1000;
    final event = _calculator!.getBeatEvent(
      nowUs: nowUs,
      latencyCompensationUs: compensationUs,
    );

    // Only update state if beat changed
    if (state.currentBeat?.beatNumber != event.beatNumber) {
      state = state.copyWith(currentBeat: event);
    }
  }

  void _stopBeatTimer() {
    _beatTimer?.cancel();
    _beatTimer = null;
  }

  void _cleanup() {
    _stopBeatTimer();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
