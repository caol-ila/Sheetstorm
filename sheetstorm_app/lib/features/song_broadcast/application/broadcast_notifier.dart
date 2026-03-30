import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_broadcast_service.dart';
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

  /// The currently active transport (BLE or SignalR).
  final TransportType activeTransport;

  /// BLE session info when connected via BLE.
  final BleSessionInfo? bleSessionInfo;

  const BroadcastState({
    this.mode = BroadcastMode.idle,
    this.session,
    this.connectedMusicians = const [],
    this.currentSong,
    this.connectionState = SignalRConnectionState.disconnected,
    this.connectedCount = 0,
    this.error,
    this.activeTransport = TransportType.none,
    this.bleSessionInfo,
  });

  bool get isActive =>
      mode == BroadcastMode.broadcasting || mode == BroadcastMode.receiving;
  bool get isConductor => mode == BroadcastMode.broadcasting;
  bool get isMusician => mode == BroadcastMode.receiving;
  bool get isBle => activeTransport == TransportType.ble;

  static const _sentinel = Object();

  BroadcastState copyWith({
    BroadcastMode? mode,
    BroadcastSession? session,
    List<ConnectedMusician>? connectedMusicians,
    SongChangedPayload? currentSong,
    SignalRConnectionState? connectionState,
    int? connectedCount,
    Object? error = _sentinel,
    TransportType? activeTransport,
    Object? bleSessionInfo = _sentinel,
  }) =>
      BroadcastState(
        mode: mode ?? this.mode,
        session: session ?? this.session,
        connectedMusicians: connectedMusicians ?? this.connectedMusicians,
        currentSong: currentSong ?? this.currentSong,
        connectionState: connectionState ?? this.connectionState,
        connectedCount: connectedCount ?? this.connectedCount,
        error: error == _sentinel ? this.error : error as String?,
        activeTransport: activeTransport ?? this.activeTransport,
        bleSessionInfo: bleSessionInfo == _sentinel
            ? this.bleSessionInfo
            : bleSessionInfo as BleSessionInfo?,
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
  BleBroadcastService get _ble => ref.read(bleBroadcastServiceProvider);
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
      _signalR.onSignalRConnectionStateChanged.listen((connectionState) {
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

  // ─── BLE Actions ───────────────────────────────────────────────────────

  /// Connect to an existing BLE session as a musician.
  Future<void> connectViaBle(BleSessionInfo sessionInfo) async {
    state = state.copyWith(mode: BroadcastMode.connecting);

    try {
      await _ble.connect(sessionInfo);
      _listenToBleEvents();

      state = state.copyWith(
        mode: BroadcastMode.receiving,
        activeTransport: TransportType.ble,
        bleSessionInfo: sessionInfo,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        mode: BroadcastMode.error,
        error: 'BLE-Verbindung fehlgeschlagen: $e',
      );
    }
  }

  /// Start advertising as a BLE conductor (Peripheral mode).
  Future<void> startBleSession(BleSessionInfo sessionInfo) async {
    state = state.copyWith(mode: BroadcastMode.connecting);

    try {
      await _ble.startAsPeripheral(sessionInfo);
      _listenToBleEvents();

      state = state.copyWith(
        mode: BroadcastMode.broadcasting,
        activeTransport: TransportType.ble,
        bleSessionInfo: sessionInfo,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        mode: BroadcastMode.error,
        error: 'BLE-Session konnte nicht gestartet werden: $e',
      );
    }
  }

  /// Disconnect from the active BLE session.
  Future<void> disconnectBle() async {
    await _ble.disconnect();
    state = state.copyWith(
      mode: BroadcastMode.idle,
      activeTransport: TransportType.none,
      bleSessionInfo: null,
      error: null,
    );
  }

  void _listenToBleEvents() {
    _subscriptions.addAll([
      _ble.onSongChanged.listen((payload) {
        state = state.copyWith(currentSong: payload);
      }),
      _ble.onSessionControl.listen((payload) {
        if (payload.type == SessionControlType.stop) {
          _ble.disconnect();
          state = const BroadcastState();
        }
      }),
      _ble.onConnectionStateChanged.listen((bleState) {
        if (bleState == TransportConnectionState.disconnected &&
            state.mode != BroadcastMode.idle) {
          state = state.copyWith(
            mode: BroadcastMode.error,
            error: 'BLE-Verbindung verloren',
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
