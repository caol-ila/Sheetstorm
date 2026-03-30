import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/core/config/app_config.dart';
import 'package:sheetstorm/features/auth/data/services/token_storage.dart';
import 'package:sheetstorm/features/metronome/application/clock_sync_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'metronome_connection_service.g.dart';

@Riverpod(keepAlive: true)
MetronomeSignalRService metronomeSignalRService(Ref ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  return MetronomeSignalRService(tokenStorage: tokenStorage);
}

// ─── SignalR Service for Metronome ──────────────────────────────────────────

/// Manages the SignalR WebSocket connection for metronome sync.
///
/// Follows the manual SignalR JSON protocol pattern established in
/// BroadcastSignalRService. Messages are terminated by record separator (0x1E).
class MetronomeSignalRService {
  final TokenStorage _tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;

  MetronomeConnectionState _connectionState =
      MetronomeConnectionState.disconnected;
  MetronomeConnectionState get connectionState => _connectionState;

  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  static const _reconnectDelays = [2, 4, 8, 16, 32];
  static const _heartbeatInterval = Duration(seconds: 10);
  static const _recordSeparator = '\u001e';

  // Event streams
  final _sessionStartedController =
      StreamController<MetronomeSession>.broadcast();
  final _sessionStoppedController = StreamController<String>.broadcast();
  final _sessionUpdatedController =
      StreamController<SessionUpdatePayload>.broadcast();
  final _clockSyncResponseController =
      StreamController<ClockSyncResponsePayload>.broadcast();
  final _participantCountController =
      StreamController<int>.broadcast();
  final _connectionStateController =
      StreamController<MetronomeConnectionState>.broadcast();

  Stream<MetronomeSession> get onSessionStarted =>
      _sessionStartedController.stream;
  Stream<String> get onSessionStopped => _sessionStoppedController.stream;
  Stream<SessionUpdatePayload> get onSessionUpdated =>
      _sessionUpdatedController.stream;
  Stream<ClockSyncResponsePayload> get onClockSyncResponse =>
      _clockSyncResponseController.stream;
  Stream<int> get onParticipantCountChanged =>
      _participantCountController.stream;
  Stream<MetronomeConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  MetronomeSignalRService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  /// Connect to the metronome SignalR hub.
  Future<void> connect() async {
    if (_connectionState == MetronomeConnectionState.connected ||
        _connectionState == MetronomeConnectionState.connecting) {
      return;
    }

    _setConnectionState(MetronomeConnectionState.connecting);

    try {
      final token = await _tokenStorage.getAccessToken();
      final baseUrl = AppConfig.apiBaseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('https', 'wss');
      final uri =
          Uri.parse('$baseUrl/hubs/metronome?access_token=$token');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // SignalR JSON protocol handshake
      _send({'protocol': 'json', 'version': 1});

      _reconnectAttempts = 0;
      _setConnectionState(MetronomeConnectionState.connected);
      _startHeartbeat();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Metronome] Connection failed: $e');
      }
      _setConnectionState(MetronomeConnectionState.disconnected);
      _attemptReconnect();
    }
  }

  /// Disconnect from the metronome hub.
  Future<void> disconnect() async {
    _reconnectAttempts = _maxReconnectAttempts;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setConnectionState(MetronomeConnectionState.disconnected);
  }

  // ─── Client → Server commands ──────────────────────────────────────────

  /// Start a metronome session (conductor only).
  void startSession({
    required String bandId,
    required int bpm,
    required int beatsPerMeasure,
    required int beatUnit,
  }) {
    _invoke('StartSession', [
      {
        'bandId': bandId,
        'bpm': bpm,
        'beatsPerMeasure': beatsPerMeasure,
        'beatUnit': beatUnit,
      },
    ]);
  }

  /// Stop the active session (conductor only).
  void stopSession(String bandId) {
    _invoke('StopSession', [
      {'bandId': bandId},
    ]);
  }

  /// Update BPM/time signature (conductor only).
  void updateSession({
    required String bandId,
    required int bpm,
    required int beatsPerMeasure,
    required int beatUnit,
  }) {
    _invoke('UpdateSession', [
      {
        'bandId': bandId,
        'bpm': bpm,
        'beatsPerMeasure': beatsPerMeasure,
        'beatUnit': beatUnit,
      },
    ]);
  }

  /// Request clock sync measurement.
  void requestClockSync(int clientSendTimeUs) {
    _invoke('RequestClockSync', [
      {'clientSendTimeUs': clientSendTimeUs},
    ]);
  }

  /// Join a session as musician.
  void joinSession(String bandId) {
    _invoke('JoinSession', [
      {'bandId': bandId},
    ]);
  }

  /// Leave the current session.
  void leaveSession(String bandId) {
    _invoke('LeaveSession', [
      {'bandId': bandId},
    ]);
  }

  /// Dispose all resources.
  void dispose() {
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _sessionStartedController.close();
    _sessionStoppedController.close();
    _sessionUpdatedController.close();
    _clockSyncResponseController.close();
    _participantCountController.close();
    _connectionStateController.close();
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  void _send(Map<String, dynamic> message) {
    final json = jsonEncode(message) + _recordSeparator;
    _channel?.sink.add(json);
  }

  void _invoke(String method, List<dynamic> args) {
    _send({
      'type': 1, // Invocation
      'target': method,
      'arguments': args,
    });
  }

  void _onMessage(dynamic raw) {
    final messages = (raw as String).split(_recordSeparator);
    for (final msg in messages) {
      if (msg.trim().isEmpty) continue;
      try {
        final json = jsonDecode(msg) as Map<String, dynamic>;
        _handleMessage(json);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('[Metronome] Parse error: $e');
        }
      }
    }
  }

  void _handleMessage(Map<String, dynamic> json) {
    final type = json['type'] as int?;

    switch (type) {
      case 1: // Invocation
        final target = json['target'] as String?;
        final args = json['arguments'] as List<dynamic>? ?? [];
        _handleInvocation(target, args);
      case 6: // Ping
        _send({'type': 6}); // Pong
      case 7: // Close
        disconnect();
    }
  }

  void _handleInvocation(String? target, List<dynamic> args) {
    if (target == null || args.isEmpty) return;
    final payload = args.first as Map<String, dynamic>;

    switch (target) {
      case 'OnSessionStarted':
        _sessionStartedController.add(MetronomeSession.fromJson(payload));
      case 'OnSessionStopped':
        _sessionStoppedController.add(payload['sessionId'] as String);
      case 'OnSessionUpdated':
        _sessionUpdatedController
            .add(SessionUpdatePayload.fromJson(payload));
      case 'OnClockSyncResponse':
        _clockSyncResponseController
            .add(ClockSyncResponsePayload.fromJson(payload));
      case 'OnParticipantCountChanged':
        _participantCountController.add(payload['count'] as int);
    }
  }

  void _onError(dynamic error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Metronome] WebSocket error: $error');
    }
    _setConnectionState(MetronomeConnectionState.reconnecting);
    _attemptReconnect();
  }

  void _onDone() {
    if (_connectionState != MetronomeConnectionState.disconnected) {
      _setConnectionState(MetronomeConnectionState.reconnecting);
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setConnectionState(MetronomeConnectionState.disconnected);
      return;
    }

    final delay = _reconnectDelays[_reconnectAttempts];
    _reconnectAttempts++;

    Future.delayed(Duration(seconds: delay), () {
      if (_connectionState == MetronomeConnectionState.reconnecting) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_connectionState == MetronomeConnectionState.connected) {
        _send({'type': 6}); // Ping
      }
    });
  }

  void _setConnectionState(MetronomeConnectionState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    _connectionStateController.add(newState);
  }
}

// ─── Payload models ──────────────────────────────────────────────────────────

/// Payload for session update events.
class SessionUpdatePayload {
  final String sessionId;
  final String bandId;
  final int bpm;
  final int beatsPerMeasure;
  final int beatUnit;
  final int changeAtBeatNumber;
  final int newStartTimeUs;

  const SessionUpdatePayload({
    required this.sessionId,
    required this.bandId,
    required this.bpm,
    required this.beatsPerMeasure,
    required this.beatUnit,
    required this.changeAtBeatNumber,
    required this.newStartTimeUs,
  });

  factory SessionUpdatePayload.fromJson(Map<String, dynamic> json) =>
      SessionUpdatePayload(
        sessionId: json['sessionId'] as String,
        bandId: json['bandId'] as String,
        bpm: json['bpm'] as int,
        beatsPerMeasure: json['beatsPerMeasure'] as int,
        beatUnit: json['beatUnit'] as int,
        changeAtBeatNumber: json['changeAtBeatNumber'] as int,
        newStartTimeUs: json['newStartTimeUs'] as int,
      );
}

/// Payload for clock sync response.
class ClockSyncResponsePayload {
  final int clientSendTimeUs;
  final int serverRecvTimeUs;
  final int serverSendTimeUs;

  const ClockSyncResponsePayload({
    required this.clientSendTimeUs,
    required this.serverRecvTimeUs,
    required this.serverSendTimeUs,
  });

  factory ClockSyncResponsePayload.fromJson(Map<String, dynamic> json) =>
      ClockSyncResponsePayload(
        clientSendTimeUs: json['clientSendTimeUs'] as int,
        serverRecvTimeUs: json['serverRecvTimeUs'] as int,
        serverSendTimeUs: json['serverSendTimeUs'] as int,
      );
}
