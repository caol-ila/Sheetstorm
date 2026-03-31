import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';

// ─── Server Event Types ─────────────────────────────────────────────────────

enum ServerEventType { elementAdded, elementUpdated, elementDeleted }

class ServerEvent {
  const ServerEvent({
    required this.type,
    this.element,
    this.elementId,
    this.annotationId,
  });

  final ServerEventType type;
  final AnnotationElementDto? element;
  final String? elementId;
  final String? annotationId;
}

// ─── REST Service ───────────────────────────────────────────────────────────

/// REST endpoint URL builders for annotation sync.
/// Uses /api/ prefix without version segment, camelCase JSON keys.
class AnnotationRestService {
  static String buildAnnotationsUrl(String bandId, String piecePageId) =>
      '/api/bands/$bandId/annotations/$piecePageId';

  static String buildElementsUrl(String bandId, String annotationId) =>
      '/api/bands/$bandId/annotations/$annotationId/elements';

  static String buildElementUrl(
          String bandId, String annotationId, String elementId) =>
      '/api/bands/$bandId/annotations/$annotationId/elements/$elementId';

  static String buildSyncUrl(String bandId, String piecePageId) =>
      '/api/bands/$bandId/annotations/$piecePageId/sync';
}

// ─── SignalR Service ────────────────────────────────────────────────────────

/// Manual SignalR JSON protocol client for annotation real-time sync.
/// Follows the same pattern as BroadcastSignalRService.
class AnnotationSignalRService {
  static const _recordSeparator = '\u001e';

  /// Reconnect policy: exponential backoff per spec §7.5
  static const reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 10),
    Duration(seconds: 30),
  ];

  static int get maxReconnectAttempts => reconnectDelays.length;

  // ── Message Framing ────────────────────────────────────────────────────

  /// Format a SignalR JSON handshake message
  static String formatHandshake() =>
      '${json.encode({'protocol': 'json', 'version': 1})}$_recordSeparator';

  /// Format a SignalR invocation message (type 1)
  static String formatInvocation(String target, List<dynamic> arguments) =>
      '${json.encode({'type': 1, 'target': target, 'arguments': arguments})}$_recordSeparator';

  /// Split raw SignalR data into individual JSON messages
  static List<Map<String, dynamic>> parseMessages(String raw) {
    return raw
        .split(_recordSeparator)
        .where((s) => s.trim().isNotEmpty)
        .map((s) => json.decode(s) as Map<String, dynamic>)
        .toList();
  }

  // ── URL Building ───────────────────────────────────────────────────────

  /// Build WebSocket URL for annotation sync hub
  static String buildWsUrl(String apiBaseUrl, String accessToken) {
    final wsUrl = apiBaseUrl
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');
    return '$wsUrl/hubs/annotation-sync?access_token=$accessToken';
  }

  // ── Group Names ────────────────────────────────────────────────────────

  /// SignalR group name for voice-level annotation sync
  static String voiceGroupName(
          String bandId, String voiceId, String piecePageId) =>
      'annotation-voice-$bandId-$voiceId-$piecePageId';

  /// SignalR group name for orchestra-level annotation sync
  static String orchestraGroupName(String bandId, String piecePageId) =>
      'annotation-orchestra-$bandId-$piecePageId';

  // ── Server Event Parsing ───────────────────────────────────────────────

  /// Parse a SignalR server message into a typed ServerEvent.
  /// Returns null for pings, handshake responses, or unknown targets.
  static ServerEvent? parseServerEvent(Map<String, dynamic> msg) {
    final type = msg['type'] as int?;

    // Ping/pong (type 6) and close (type 7)
    if (type != 1) return null;

    final target = msg['target'] as String?;
    final args = msg['arguments'] as List<dynamic>?;
    if (target == null || args == null) return null;

    return switch (target) {
      'OnElementAdded' => ServerEvent(
          type: ServerEventType.elementAdded,
          element: AnnotationElementDto.fromJson(
              args[0] as Map<String, dynamic>),
        ),
      'OnElementUpdated' => ServerEvent(
          type: ServerEventType.elementUpdated,
          element: AnnotationElementDto.fromJson(
              args[0] as Map<String, dynamic>),
        ),
      'OnElementDeleted' => ServerEvent(
          type: ServerEventType.elementDeleted,
          elementId: args[0] as String,
          annotationId: args[1] as String,
        ),
      _ => null,
    };
  }

  // ── Instance (stateful connection management) ──────────────────────────

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeatTimer;

  /// Current reconnect attempt (0 = no reconnect in progress)
  int reconnectAttempt = 0;

  final _onElementAdded = StreamController<AnnotationElementDto>.broadcast();
  final _onElementUpdated = StreamController<AnnotationElementDto>.broadcast();
  final _onElementDeleted =
      StreamController<(String elementId, String annotationId)>.broadcast();
  final _onConnectionStateChanged = StreamController<bool>.broadcast();

  Stream<AnnotationElementDto> get onElementAdded => _onElementAdded.stream;
  Stream<AnnotationElementDto> get onElementUpdated =>
      _onElementUpdated.stream;
  Stream<(String, String)> get onElementDeleted => _onElementDeleted.stream;
  Stream<bool> get onConnectionStateChanged =>
      _onConnectionStateChanged.stream;

  bool get isConnected => _channel != null;

  /// Connect to the annotation sync hub
  Future<void> connect(String apiBaseUrl, String accessToken) async {
    if (_channel != null) return;

    final wsUrl = buildWsUrl(apiBaseUrl, accessToken);
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    // Send handshake
    _channel!.sink.add(formatHandshake());

    _subscription = _channel!.stream.listen(
      _handleMessage,
      onDone: _handleDisconnect,
      onError: (_) => _handleDisconnect(),
    );

    _startHeartbeat();
    reconnectAttempt = 0;
    _onConnectionStateChanged.add(true);
  }

  /// Disconnect from the hub
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _onConnectionStateChanged.add(false);
  }

  /// Join an annotation group (voice or orchestra)
  void joinGroup(
      String bandId, String piecePageId, String level, String? voiceId) {
    _send('JoinAnnotationGroup', [bandId, piecePageId, level, voiceId]);
  }

  /// Leave an annotation group
  void leaveGroup(
      String bandId, String piecePageId, String level, String? voiceId) {
    _send('LeaveAnnotationGroup', [bandId, piecePageId, level, voiceId]);
  }

  /// Notify server of an element change (requires groupName as first positional arg)
  void notifyElementChange(
      String groupName, ElementChangeNotification notification) {
    _send('NotifyElementChange', [groupName, notification.toJson()]);
  }

  void _send(String target, List<dynamic> arguments) {
    if (_channel == null) return;
    _channel!.sink.add(formatInvocation(target, arguments));
  }

  void _handleMessage(dynamic data) {
    if (data is! String) return;

    for (final msg in parseMessages(data)) {
      final event = parseServerEvent(msg);
      if (event == null) continue;

      switch (event.type) {
        case ServerEventType.elementAdded:
          _onElementAdded.add(event.element!);
        case ServerEventType.elementUpdated:
          _onElementUpdated.add(event.element!);
        case ServerEventType.elementDeleted:
          _onElementDeleted.add((event.elementId!, event.annotationId!));
      }
    }
  }

  void _handleDisconnect() {
    _channel = null;
    _heartbeatTimer?.cancel();
    _onConnectionStateChanged.add(false);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_channel == null) return;
      _channel!.sink.add('${json.encode({'type': 6})}$_recordSeparator');
    });
  }

  /// Cleanup all resources
  Future<void> dispose() async {
    await disconnect();
    await _onElementAdded.close();
    await _onElementUpdated.close();
    await _onElementDeleted.close();
    await _onConnectionStateChanged.close();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────────

final annotationSignalRServiceProvider =
    Provider<AnnotationSignalRService>((ref) {
  final service = AnnotationSignalRService();
  ref.onDispose(service.dispose);
  return service;
});
