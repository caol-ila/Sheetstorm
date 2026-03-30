// Binary codec for BLE messages per the Sheetstorm GATT broadcast spec.
//
// Message format:
//   Header    4 bytes  [type(1), seq_hi(1), seq_lo(1), flags(1)]
//   Timestamp 4 bytes  [uint32 Unix epoch seconds, big-endian]
//   Payload   0-182 B  [message-type specific]
//   HMAC      32 bytes [HMAC-SHA256 over header+timestamp+payload]
//   Total max 222 bytes (fits in BLE ATT MTU of 247 - 3 ATT header bytes)

import 'dart:convert';
import 'dart:typed_data';

import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

// ─── Decoded BLE Message ───────────────────────────────────────────────────────

class BleMessage {
  final int messageType;
  final int sequenceNumber;
  final int flags;
  final int timestamp;
  final Uint8List payload;
  final Uint8List signature; // 32 bytes HMAC-SHA256

  const BleMessage({
    required this.messageType,
    required this.sequenceNumber,
    required this.flags,
    required this.timestamp,
    required this.payload,
    required this.signature,
  });
}

// ─── Codec ────────────────────────────────────────────────────────────────────

class BleMessageCodec {
  static const int songChanged = 0x01;
  static const int metronomeBeat = 0x02;
  static const int annotationInvalidated = 0x03;
  static const int sessionStart = 0x10;
  static const int sessionStop = 0x11;
  static const int sessionStatus = 0x12;
  static const int authChallenge = 0xF0;
  static const int authResponse = 0xF1;

  static const int _headerSize = 4;
  static const int _timestampSize = 4;
  static const int _hmacSize = 32;
  static const int _maxPayloadSize = 182;
  static const int _minMessageSize = _headerSize + _timestampSize + _hmacSize;

  /// Encodes a raw payload with standard header + current timestamp.
  /// Returns the full message bytes WITHOUT the HMAC (caller appends it after signing).
  Uint8List encodeWithoutHmac(
    int messageType,
    Uint8List payload,
    int sequenceNumber,
  ) {
    final size = _headerSize + _timestampSize + payload.length;
    final buffer = ByteData(size);
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    buffer.setUint8(0, messageType);
    buffer.setUint8(1, (sequenceNumber >> 8) & 0xFF); // seq_hi
    buffer.setUint8(2, sequenceNumber & 0xFF); // seq_lo
    buffer.setUint8(3, 0); // flags
    buffer.setUint32(4, now, Endian.big);

    final result = buffer.buffer.asUint8List();
    result.setRange(_headerSize + _timestampSize, size, payload);
    return result;
  }

  /// Encodes a complete message (header + payload + signature).
  Uint8List encode(int messageType, Uint8List payload, int sequenceNumber) {
    final withoutHmac = encodeWithoutHmac(messageType, payload, sequenceNumber);
    // Caller is expected to append HMAC via BleSecurityService.
    // This overload returns header+payload only; use encodeAndSign when available.
    return withoutHmac;
  }

  /// Decodes raw BLE bytes into a structured [BleMessage].
  /// Throws [FormatException] if the message is too short or malformed.
  BleMessage decode(Uint8List raw) {
    if (raw.length < _minMessageSize) {
      throw FormatException(
        'BLE message too short: ${raw.length} < $_minMessageSize',
      );
    }

    final data = ByteData.sublistView(raw);
    final messageType = data.getUint8(0);
    final seqHi = data.getUint8(1);
    final seqLo = data.getUint8(2);
    final flags = data.getUint8(3);
    final timestamp = data.getUint32(4, Endian.big);

    final payloadEnd = raw.length - _hmacSize;
    final payload = raw.sublist(_headerSize + _timestampSize, payloadEnd);
    final signature = raw.sublist(payloadEnd);

    return BleMessage(
      messageType: messageType,
      sequenceNumber: (seqHi << 8) | seqLo,
      flags: flags,
      timestamp: timestamp,
      payload: payload,
      signature: Uint8List.fromList(signature),
    );
  }

  // ─── Specific encoders (return header+payload only, no HMAC) ───────────────

  Uint8List encodeSongChanged(
    String stueckId,
    String stueckTitel,
    int seqNum,
  ) {
    var idBytes = utf8.encode(stueckId);
    var titleBytes = utf8.encode(stueckTitel);

    // Format: [id_len(1), id(...), title_len(1), title(...)]
    // Enforce max payload of 182 bytes: 2 overhead + id + title
    const overhead = 2; // 1 byte id_len + 1 byte title_len
    final maxContentSize = _maxPayloadSize - overhead;

    // ID gets priority — truncate title first
    if (idBytes.length + titleBytes.length > maxContentSize) {
      final remainingForTitle = maxContentSize - idBytes.length;
      if (remainingForTitle <= 0) {
        idBytes = idBytes.sublist(0, maxContentSize);
        titleBytes = Uint8List(0);
      } else {
        titleBytes = titleBytes.sublist(0, remainingForTitle);
      }
    }

    final payload = Uint8List(overhead + idBytes.length + titleBytes.length);
    var offset = 0;
    payload[offset++] = idBytes.length & 0xFF;
    payload.setRange(offset, offset + idBytes.length, idBytes);
    offset += idBytes.length;
    payload[offset++] = titleBytes.length & 0xFF;
    payload.setRange(offset, offset + titleBytes.length, titleBytes);

    return encodeWithoutHmac(songChanged, payload, seqNum);
  }

  Uint8List encodeMetronomeBeat(MetronomeBeatPayload beat, int seqNum) {
    return encodeWithoutHmac(metronomeBeat, beat.toBytes(), seqNum);
  }

  Uint8List encodeAnnotationInvalidation(
    AnnotationInvalidationPayload payload,
    int seqNum,
  ) {
    final guidBytes = utf8.encode(payload.stueckGuid);
    final stimmeBytes = utf8.encode(payload.stimmeId);

    // Format: [guid(36), stimme_len(1), stimme(...), update_type(1)]
    final bytes = Uint8List(36 + 1 + stimmeBytes.length + 1);
    var offset = 0;

    // Pad or truncate GUID to exactly 36 bytes
    final paddedGuid = Uint8List(36);
    paddedGuid.setRange(0, guidBytes.length.clamp(0, 36), guidBytes);
    bytes.setRange(offset, offset + 36, paddedGuid);
    offset += 36;

    bytes[offset++] = stimmeBytes.length & 0xFF;
    bytes.setRange(offset, offset + stimmeBytes.length, stimmeBytes);
    offset += stimmeBytes.length;
    bytes[offset] = payload.updateType.value;

    return encodeWithoutHmac(annotationInvalidated, bytes, seqNum);
  }

  Uint8List encodeSessionControl(SessionControlType type, int seqNum) {
    final msgType = switch (type) {
      SessionControlType.start => sessionStart,
      SessionControlType.stop => sessionStop,
      SessionControlType.status => sessionStatus,
    };
    return encodeWithoutHmac(msgType, Uint8List(0), seqNum);
  }

  // ─── Decoders ──────────────────────────────────────────────────────────────

  /// Decodes a SONG_CHANGED payload into (stueckId, stueckTitel).
  (String, String) decodeSongChanged(Uint8List payload) {
    var offset = 0;
    final idLen = payload[offset++];
    final stueckId = utf8.decode(payload.sublist(offset, offset + idLen));
    offset += idLen;
    final titleLen = payload[offset++];
    final stueckTitel = utf8.decode(payload.sublist(offset, offset + titleLen));
    return (stueckId, stueckTitel);
  }

  AnnotationInvalidationPayload decodeAnnotationInvalidation(
    Uint8List payload,
  ) {
    final stueckGuid = utf8.decode(payload.sublist(0, 36)).trim();
    final stimmeLen = payload[36];
    final stimmeId = utf8.decode(payload.sublist(37, 37 + stimmeLen));
    final updateType = AnnotationUpdateType.fromValue(payload[37 + stimmeLen]);
    return AnnotationInvalidationPayload(
      stueckGuid: stueckGuid,
      stimmeId: stimmeId,
      updateType: updateType,
    );
  }

  SessionControlType decodeSessionControl(int messageType) => switch (messageType) {
        sessionStart => SessionControlType.start,
        sessionStop => SessionControlType.stop,
        _ => SessionControlType.status,
      };
}
