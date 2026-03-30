// HMAC-SHA256 signing, verification, replay protection, and trust model
// for the Sheetstorm BLE broadcast security layer.

import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';

// ─── Replay Protection ─────────────────────────────────────────────────────────

class ReplayProtection {
  static const int maxTimeDriftSeconds = 5;
  final Map<String, int> _lastSeqBySender = {};

  bool isValid(String senderId, int sequenceNumber, int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Reject messages with timestamps outside the acceptable window
    if ((now - timestamp).abs() > maxTimeDriftSeconds) return false;

    final lastSeq = _lastSeqBySender[senderId] ?? -1;

    // Allow sequence number wrap-around (uint16 overflow: 65535 → 0)
    final isWrapAround = lastSeq > 60000 && sequenceNumber < 1000;
    if (!isWrapAround && sequenceNumber <= lastSeq) return false;

    _lastSeqBySender[senderId] = sequenceNumber;
    return true;
  }

  void reset() => _lastSeqBySender.clear();
}

// ─── Security Service ──────────────────────────────────────────────────────────

class BleSecurityService {
  Uint8List _sessionKey;
  final String _leaderDeviceId;
  final ReplayProtection _replayProtection = ReplayProtection();
  final Set<String> _authenticatedDevices = {};

  static const Set<int> _conductorOnlyTypes = {
    BleMessageCodec.songChanged,
    BleMessageCodec.metronomeBeat,
    BleMessageCodec.sessionStart,
    BleMessageCodec.sessionStop,
    BleMessageCodec.sessionStatus,
  };

  BleSecurityService({
    required Uint8List sessionKey,
    required String leaderDeviceId,
  })  : _sessionKey = sessionKey,
        _leaderDeviceId = leaderDeviceId;

  void updateSessionKey(Uint8List newKey) => _sessionKey = newKey;

  void markDeviceAuthenticated(String deviceId) =>
      _authenticatedDevices.add(deviceId);

  // ─── Signing ────────────────────────────────────────────────────────────────

  /// Computes HMAC-SHA256 over [headerAndPayload] using the current session key.
  Uint8List signMessage(Uint8List headerAndPayload) {
    final hmac = Hmac(sha256, _sessionKey);
    final digest = hmac.convert(headerAndPayload);
    return Uint8List.fromList(digest.bytes);
  }

  /// Appends a valid HMAC-SHA256 signature to a pre-built message buffer.
  Uint8List signAndAppend(Uint8List headerAndPayload) {
    final sig = signMessage(headerAndPayload);
    final result = Uint8List(headerAndPayload.length + sig.length);
    result.setRange(0, headerAndPayload.length, headerAndPayload);
    result.setRange(headerAndPayload.length, result.length, sig);
    return result;
  }

  // ─── Verification ────────────────────────────────────────────────────────────

  /// Verifies the HMAC-SHA256 signature appended to [message] (last 32 bytes).
  bool verifySignature(Uint8List message) {
    if (message.length < 32) return false;
    final payloadEnd = message.length - 32;
    final headerAndPayload = message.sublist(0, payloadEnd);
    final receivedHmac = message.sublist(payloadEnd);
    final expectedHmac = signMessage(headerAndPayload);
    return _constantTimeEquals(receivedHmac, expectedHmac);
  }

  /// Returns true when [senderDeviceId] is authorised to send [messageType].
  bool isAuthorizedSender(int messageType, String senderDeviceId) {
    if (_conductorOnlyTypes.contains(messageType)) {
      return senderDeviceId == _leaderDeviceId;
    }
    // ANNOTATION_INVALIDATED (0x03): any authenticated member
    if (messageType == BleMessageCodec.annotationInvalidated) {
      return _authenticatedDevices.contains(senderDeviceId) ||
          senderDeviceId == _leaderDeviceId;
    }
    return false;
  }

  /// Full validation: signature integrity + replay + trust model.
  bool validateMessage(
    Uint8List rawMessage,
    String senderDeviceId, {
    int? expectedMessageType,
  }) {
    if (rawMessage.length < 40) return false; // header(4) + ts(4) + hmac(32)

    // 1. Signature
    if (!verifySignature(rawMessage)) return false;

    // 2. Extract header fields
    final messageType = rawMessage[0];
    final seqHi = rawMessage[1];
    final seqLo = rawMessage[2];
    final sequenceNumber = (seqHi << 8) | seqLo;

    final tsBytes = ByteData.sublistView(rawMessage, 4, 8);
    final timestamp = tsBytes.getUint32(0, Endian.big);

    // 3. Replay protection
    if (!_replayProtection.isValid(senderDeviceId, sequenceNumber, timestamp)) {
      return false;
    }

    // 4. Trust model
    return isAuthorizedSender(messageType, senderDeviceId);
  }

  // ─── Challenge-Response ──────────────────────────────────────────────────────

  /// Creates a 16-byte cryptographic nonce for a challenge.
  Uint8List createChallenge() {
    final random = Random.secure();
    final challenge = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      challenge[i] = random.nextInt(256);
    }
    return challenge;
  }

  /// Computes HMAC-SHA256(sessionKey, nonce) as the challenge response.
  Uint8List respondToChallenge(Uint8List nonce) => signMessage(nonce);

  /// Verifies a challenge response: checks HMAC-SHA256(sessionKey, nonce) == response.
  bool verifyChallenge(Uint8List nonce, Uint8List response) {
    final expected = signMessage(nonce);
    return _constantTimeEquals(response, expected);
  }

  // ─── Private helpers ─────────────────────────────────────────────────────────

  /// Constant-time byte comparison to prevent timing-based side-channel attacks.
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
