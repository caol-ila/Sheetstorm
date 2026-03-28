import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';

part 'broadcast_notifier.g.dart';

// ─── Broadcast State ──────────────────────────────────────────────────────────

enum BroadcastMode { idle, connecting, broadcasting, receiving, error }

class BroadcastState {
  final BroadcastMode mode;
  final BroadcastSession? session;
  final List<ConnectedMusician> connectedMusicians;
  final SongChangedPayload? currentSong;
  final SignalRConnectionState connectionState;
  final int connectedCount;
  final String? error;

  const BroadcastState({
    this.mode = BroadcastMode.idle,
    this.session,
    this.connectedMusicians = const [],
    this.currentSong,
    this.connectionState = SignalRConnectionState.disconnected,
    this.connectedCount = 0,
    this.error,
  });

  bool get isActive =>
      mode == BroadcastMode.broadcasting || mode == BroadcastMode.receiving;
  bool get isConductor => mode == BroadcastMode.broadcasting;
  bool get isMusician => mode == BroadcastMode.receiving;

  BroadcastState copyWith({
    BroadcastMode? mode,
    BroadcastSession? session,
    List<ConnectedMusician>? connectedMusicians,
    SongChangedPayload? currentSong,
    SignalRConnectionState? connectionState,
    int? connectedCount,
    String? error,
  }) =>
      BroadcastState(
        mode: mode ?? this.mode,
        session: session ?? this.session,
        connectedMusicians: connectedMusicians ?? this.connectedMusicians,
        currentSong: currentSong ?? this.currentSong,
        connectionState: connectionState ?? this.connectionState,
        connectedCount: connectedCount ?? this.connectedCount,
        error: error ?? this.error,
      );
}

// ─── Broadcast Notifier ───────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class BroadcastNotifier extends _$BroadcastNotifier {
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  @override
  BroadcastState build() {
    ref.onDispose(_cleanup);
    return const BroadcastState();
  }

  BroadcastRestService get _rest => ref.read(broadcastRestServiceProvider);
  BroadcastSignalRService get _signalR =>
      ref.read(broadcastSignalRServiceProvider);
  String? get _bandId => ref.read(activeBandProvider);

  // ─── Conductor Actions ─────────────────────────────────────────────────

  /// Start a new broadcast session as conductor.
  Future<void> startSession({String? setlistId}) async {
    final bandId = _bandId;
    if (bandId == null) {
      state = state.copyWith(
          mode: BroadcastMode.error, error: 'Keine aktive Kapelle');
      return;
    }

    state = state.copyWith(mode: BroadcastMode.connecting);

    try {
      final session =
          await _rest.startSession(kapelleId: bandId, setlistId: setlistId);

      await _signalR.connect();
      _listenToEvents();

      state = state.copyWith(
        mode: BroadcastMode.broadcasting,
        session: session,
        connectionState: SignalRConnectionState.connected,
        connectedCount: session.verbundeneMusiker,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        mode: BroadcastMode.error,
        error: 'Session konnte nicht gestartet werden: $e',
      );
    }
  }

  /// Change the currently broadcast song (conductor only).
  Future<void> broadcastSong(String stueckId) async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return;

    try {
      final response = await _rest.updateSong(sessionId, stueckId);
      state = state.copyWith(
        session: state.session?.copyWith(
          aktiveStueckId: response.aktiveStueckId,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Stück konnte nicht gesendet werden',
      );
    }
  }

  /// End the current broadcast session (conductor only).
  Future<void> endSession() async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return;

    try {
      await _rest.endSession(sessionId);
      await _signalR.disconnect();
      state = const BroadcastState();
    } catch (e) {
      state = state.copyWith(
        error: 'Session konnte nicht beendet werden',
      );
    }
  }

  /// Refresh the connected musicians list (conductor only).
  Future<void> refreshConnections() async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return;

    try {
      final response = await _rest.getConnections(sessionId);
      state = state.copyWith(
        connectedMusicians: response.verbundeneMusiker,
        connectedCount: response.totalCount,
      );
    } catch (_) {
      // Silently fail — connection count updates come via SignalR
    }
  }

  // ─── Musician Actions ──────────────────────────────────────────────────

  /// Join an active broadcast session as a musician.
  Future<void> joinSession({required String musikerId}) async {
    final bandId = _bandId;
    if (bandId == null) {
      state = state.copyWith(
          mode: BroadcastMode.error, error: 'Keine aktive Kapelle');
      return;
    }

    state = state.copyWith(mode: BroadcastMode.connecting);

    try {
      // Check for active session
      final session = await _rest.getActiveSession(bandId);
      if (session == null) {
        state = state.copyWith(
          mode: BroadcastMode.idle,
          error: 'Keine aktive Session',
        );
        return;
      }

      await _signalR.connect();
      _signalR.joinSession(bandId, musikerId);
      _listenToEvents();

      state = state.copyWith(
        mode: BroadcastMode.receiving,
        session: session,
        connectionState: SignalRConnectionState.connected,
        connectedCount: session.verbundeneMusiker,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        mode: BroadcastMode.error,
        error: 'Beitritt fehlgeschlagen: $e',
      );
    }
  }

  /// Leave the current session as a musician.
  Future<void> leaveSession({required String musikerId}) async {
    final sessionId = state.session?.sessionId;
    if (sessionId == null) return;

    _signalR.leaveSession(sessionId, musikerId);
    await _signalR.disconnect();
    state = const BroadcastState();
  }

  /// Check if there's an active session for the current band.
  Future<BroadcastSession?> checkForActiveSession() async {
    final bandId = _bandId;
    if (bandId == null) return null;
    return _rest.getActiveSession(bandId);
  }

  // ─── Event Listeners ───────────────────────────────────────────────────

  void _listenToEvents() {
    _cancelSubscriptions();

    _subscriptions.addAll([
      _signalR.onSongChanged.listen((payload) {
        state = state.copyWith(currentSong: payload);
      }),
      _signalR.onSessionEnded.listen((_) {
        _signalR.disconnect();
        state = const BroadcastState();
      }),
      _signalR.onConnectionCountUpdated.listen((payload) {
        state = state.copyWith(connectedCount: payload.count);
      }),
      _signalR.onConnectionStateChanged.listen((connectionState) {
        state = state.copyWith(connectionState: connectionState);
        if (connectionState == SignalRConnectionState.disconnected &&
            state.mode != BroadcastMode.idle) {
          state = state.copyWith(
            mode: BroadcastMode.error,
            error: 'Verbindung verloren',
          );
        }
      }),
    ]);
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void _cleanup() {
    _cancelSubscriptions();
    _signalR.disconnect();
  }
}
