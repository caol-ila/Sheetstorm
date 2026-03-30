// BLE-specific models for the Sheetstorm broadcast transport layer.

import 'dart:typed_data';

// ─── Session Info ──────────────────────────────────────────────────────────────

class BleSessionInfo {
  final String sessionKey; // Base64-encoded 256-bit HMAC key
  final String leaderDeviceId;
  final DateTime expiresAt;

  const BleSessionInfo({
    required this.sessionKey,
    required this.leaderDeviceId,
    required this.expiresAt,
  });

  factory BleSessionInfo.fromJson(Map<String, dynamic> json) => BleSessionInfo(
        sessionKey: json['sessionKey'] as String,
        leaderDeviceId: json['leaderDeviceId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'sessionKey': sessionKey,
        'leaderDeviceId': leaderDeviceId,
        'expiresAt': expiresAt.toIso8601String(),
      };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

// ─── Metronome Beat ────────────────────────────────────────────────────────────

class MetronomeBeatPayload {
  final int bpm;
  final int beatsPerMeasure;
  final int beatUnit;
  final int beatTimestampMs; // ms since session start
  final int beatNumberInMeasure;
  final int nextBeatMs; // pre-calculated next beat offset

  const MetronomeBeatPayload({
    required this.bpm,
    required this.beatsPerMeasure,
    required this.beatUnit,
    required this.beatTimestampMs,
    required this.beatNumberInMeasure,
    required this.nextBeatMs,
  });

  factory MetronomeBeatPayload.fromBytes(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    return MetronomeBeatPayload(
      bpm: data.getUint16(0, Endian.big),
      beatsPerMeasure: data.getUint8(2),
      beatUnit: data.getUint8(3),
      beatTimestampMs: data.getUint32(4, Endian.big),
      beatNumberInMeasure: data.getUint8(8),
      nextBeatMs: data.getUint32(9, Endian.big),
    );
  }

  Uint8List toBytes() {
    final data = ByteData(13);
    data.setUint16(0, bpm, Endian.big);
    data.setUint8(2, beatsPerMeasure);
    data.setUint8(3, beatUnit);
    data.setUint32(4, beatTimestampMs, Endian.big);
    data.setUint8(8, beatNumberInMeasure);
    data.setUint32(9, nextBeatMs, Endian.big);
    return data.buffer.asUint8List();
  }

  factory MetronomeBeatPayload.fromJson(Map<String, dynamic> json) =>
      MetronomeBeatPayload(
        bpm: json['bpm'] as int,
        beatsPerMeasure: json['beatsPerMeasure'] as int,
        beatUnit: json['beatUnit'] as int,
        beatTimestampMs: json['beatTimestampMs'] as int,
        beatNumberInMeasure: json['beatNumberInMeasure'] as int,
        nextBeatMs: json['nextBeatMs'] as int,
      );
}

// ─── Annotation Invalidation ───────────────────────────────────────────────────

enum AnnotationUpdateType {
  created(0),
  modified(1),
  deleted(2);

  const AnnotationUpdateType(this.value);
  final int value;

  static AnnotationUpdateType fromValue(int v) => switch (v) {
        0 => AnnotationUpdateType.created,
        1 => AnnotationUpdateType.modified,
        2 => AnnotationUpdateType.deleted,
        _ => AnnotationUpdateType.modified,
      };
}

class AnnotationInvalidationPayload {
  final String stueckGuid;
  final String stimmeId;
  final AnnotationUpdateType updateType;

  const AnnotationInvalidationPayload({
    required this.stueckGuid,
    required this.stimmeId,
    required this.updateType,
  });
}

// ─── Session Control ───────────────────────────────────────────────────────────

enum SessionControlType { start, stop, status }

class SessionControlPayload {
  final SessionControlType type;
  final String? sessionId;
  final DateTime timestamp;

  const SessionControlPayload({
    required this.type,
    this.sessionId,
    required this.timestamp,
  });
}

// ─── Transport ─────────────────────────────────────────────────────────────────

enum TransportType { ble, signalR, none }

enum TransportConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}
