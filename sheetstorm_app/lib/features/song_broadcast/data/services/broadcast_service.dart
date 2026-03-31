import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/core/config/app_config.dart';
import 'package:sheetstorm/features/auth/data/services/token_storage.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'broadcast_service.g.dart';

@Riverpod(keepAlive: true)
BroadcastRestService broadcastRestService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return BroadcastRestService(dio);
}

@Riverpod(keepAlive: true)
BroadcastSignalRService broadcastSignalRService(Ref ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final service = BroadcastSignalRService(tokenStorage: tokenStorage);
  ref.onDispose(service.dispose);
  return service;
}

// ─── REST Service ──────────────────────────────────────────────────────────────

/// REST API for broadcast session management.
class BroadcastRestService {
  final Dio _dio;
  static const _base = '/api/v1/broadcast';

  BroadcastRestService(this._dio);

  Future<BroadcastSession> startSession({
    required String kapelleId,
    String? setlistId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_base/sessions',
      data: {
        'kapelleId': kapelleId,
        if (setlistId != null) 'setlistId': setlistId,
      },
    );
    return BroadcastSession.fromJson(res.data!);
  }

  Future<BroadcastSession?> getActiveSession(String kapelleId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_base/sessions/active',
        queryParameters: {'kapelleId': kapelleId},
      );
      return BroadcastSession.fromJson(res.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<UpdateSongResponse> updateSong(
    String sessionId,
    String stueckId,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/song',
      data: {'stueckId': stueckId},
    );
    return UpdateSongResponse.fromJson(res.data!);
  }

  Future<void> endSession(String sessionId) async {
    await _dio.delete<void>('$_base/sessions/$sessionId');
  }

  Future<BroadcastConnectionsResponse> getConnections(
      String sessionId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/sessions/$sessionId/connections',
    );
    return BroadcastConnectionsResponse.fromJson(res.data!);
  }
}

// ─── SignalR Service (WebSocket + JSON Protocol) ──────────────────────────────

/// Manages the SignalR WebSocket connection for real-time broadcast events.
///
/// Implements the SignalR JSON protocol manually since no dedicated SignalR
/// Dart package is available. The protocol uses JSON messages terminated
/// by the record separator character (0x1E).
class BroadcastSignalRService {
  final TokenStorage _tokenStorage;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;

  /// Current connection state.
  SignalRConnectionState _connectionState = SignalRConnectionState.disconnected;
  SignalRConnectionState get connectionState => _connectionState;

  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;
  static const _reconnectDelays = [2, 4, 8, 16, 32];
  static const _heartbeatInterval = Duration(seconds: 10);
  static const _recordSeparator = '\u001e';

  // Event streams for consumers
  final _sessionStartedController =
      StreamController<SessionStartedPayload>.broadcast();
  final _songChangedController =
      StreamController<SongChangedPayload>.broadcast();
  final _sessionEndedController =
      StreamController<SessionEndedPayload>.broadcast();
  final _connectionCountController =
      StreamController<ConnectionCountPayload>.broadcast();
  final _connectionStateController =
      StreamController<SignalRConnectionState>.broadcast();

  Stream<SessionStartedPayload> get onSessionStarted =>
      _sessionStartedController.stream;
  Stream<SongChangedPayload> get onSongChanged =>
      _songChangedController.stream;
  Stream<SessionEndedPayload> get onSessionEnded =>
      _sessionEndedController.stream;
  Stream<ConnectionCountPayload> get onConnectionCountUpdated =>
      _connectionCountController.stream;
  Stream<SignalRConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  BroadcastSignalRService({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage;

  /// Connect to the SignalR broadcast hub.
  Future<void> connect() async {
    if (_connectionState == SignalRConnectionState.connected ||
        _connectionState == SignalRConnectionState.connecting) {
      return;
    }

    _setConnectionState(SignalRConnectionState.connecting);

    try {
      final token = await _tokenStorage.getAccessToken();
      final baseUrl = AppConfig.apiBaseUrl
          .replaceFirst('http', 'ws')
          .replaceFirst('https', 'wss');
      final uri =
          Uri.parse('$baseUrl/hubs/broadcast?access_token=$token');

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Send SignalR handshake (JSON protocol)
      _send({'protocol': 'json', 'version': 1});

      _reconnectAttempts = 0;
      _setConnectionState(SignalRConnectionState.connected);
      _startHeartbeat();
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Broadcast] Connection failed: $e');
      }
      _setConnectionState(SignalRConnectionState.disconnected);
      _attemptReconnect();
    }
  }

  /// Disconnect from the broadcast hub.
  Future<void> disconnect() async {
    _reconnectAttempts = _maxReconnectAttempts; // Prevent reconnect
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _setConnectionState(SignalRConnectionState.disconnected);
  }

  /// Join a broadcast session as a musician.
  void joinSession(String kapelleId, String musikerId) {
    _invoke('JoinSession', [
      {'kapelleId': kapelleId, 'musikerId': musikerId},
    ]);
  }

  /// Leave the current session.
  void leaveSession(String sessionId, String musikerId) {
    _invoke('LeaveSession', [
      {'sessionId': sessionId, 'musikerId': musikerId},
    ]);
  }

  /// Acknowledge a song change.
  void acknowledgeSongChange({
    required String sessionId,
    required String stueckId,
    required String musikerId,
    required SongAcknowledgementStatus status,
    int latenzMs = 0,
  }) {
    _invoke('SongChangeAcknowledged', [
      {
        'sessionId': sessionId,
        'stueckId': stueckId,
        'musikerId': musikerId,
        'status': status.toJson(),
        'latenzMs': latenzMs,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
  }

  /// Send a heartbeat.
  void sendHeartbeat(String sessionId, String musikerId) {
    _invoke('Heartbeat', [
      {
        'sessionId': sessionId,
        'musikerId': musikerId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
  }

  /// Dispose all resources. Safe to call multiple times.
  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    if (!_sessionStartedController.isClosed) {
      _sessionStartedController.close();
    }
    if (!_songChangedController.isClosed) {
      _songChangedController.close();
    }
    if (!_sessionEndedController.isClosed) {
      _sessionEndedController.close();
    }
    if (!_connectionCountController.isClosed) {
      _connectionCountController.close();
    }
    if (!_connectionStateController.isClosed) {
      _connectionStateController.close();
    }
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
          print('[Broadcast] Parse error: $e');
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
      case 'SessionStarted':
        _sessionStartedController.add(SessionStartedPayload.fromJson(payload));
      case 'SongChanged':
        _songChangedController.add(SongChangedPayload.fromJson(payload));
      case 'SessionEnded':
        _sessionEndedController.add(SessionEndedPayload.fromJson(payload));
      case 'ConnectionCountUpdated':
        _connectionCountController
            .add(ConnectionCountPayload.fromJson(payload));
    }
  }

  void _onError(dynamic error) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Broadcast] WebSocket error: $error');
    }
    _setConnectionState(SignalRConnectionState.reconnecting);
    _attemptReconnect();
  }

  void _onDone() {
    if (_connectionState != SignalRConnectionState.disconnected) {
      _setConnectionState(SignalRConnectionState.reconnecting);
      _attemptReconnect();
    }
  }

  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setConnectionState(SignalRConnectionState.disconnected);
      return;
    }

    final delay = _reconnectDelays[_reconnectAttempts];
    _reconnectAttempts++;

    Future.delayed(Duration(seconds: delay), () {
      if (_connectionState == SignalRConnectionState.reconnecting) {
        connect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_connectionState == SignalRConnectionState.connected) {
        _send({'type': 6}); // Ping
      }
    });
  }

  void _setConnectionState(SignalRConnectionState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    _connectionStateController.add(newState);
  }
}

// ─── Connection State ──────────────────────────────────────────────────────────

enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
