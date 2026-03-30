// Tests for BleSecurityService and ReplayProtection.
//
// Spec: docs/specs/2026-03-30-ble-broadcast-dirigent.md §2.2–§2.5
//
// BleSecurityService API:
//   - Constructor: BleSecurityService(sessionKey: Uint8List, leaderDeviceId: String)
//   - signMessage(headerAndPayload)    → 32-byte HMAC-SHA256
//   - signAndAppend(headerAndPayload)  → headerAndPayload + 32-byte HMAC
//   - verifySignature(signedMessage)   → bool (uses internal session key)
//   - isAuthorizedSender(msgType, deviceId) → bool (uses internal leader ID + auth set)
//   - markDeviceAuthenticated(deviceId) → void
//   - validateMessage(rawMsg, deviceId) → bool (full pipeline)
//   - createChallenge()    → 16 random bytes
//   - respondToChallenge(nonce) → 32-byte HMAC
//   - verifyChallenge(nonce, response) → bool
//
// ReplayProtection API (standalone class):
//   - isValid(senderId, sequenceNumber, timestamp) → bool (stateful per sender)

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_security_service.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

/// Deterministic 32-byte session key for tests.
final _testKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

/// A different key used to verify key-sensitivity tests.
final _otherKey = Uint8List.fromList(List.generate(32, (i) => i + 50));

const _leaderDeviceId = 'leader-device-id';
const _musicianDeviceId = 'musician-device-id';

BleSecurityService _makeService({
  Uint8List? key,
  String leaderDeviceId = _leaderDeviceId,
}) =>
    BleSecurityService(
      sessionKey: key ?? _testKey,
      leaderDeviceId: leaderDeviceId,
    );

/// Builds a minimal valid BLE message payload (header 4 + timestamp 4).
Uint8List _buildUnsigned({
  int messageType = BleMessageCodec.songChanged,
  int seqNum = 1,
  int? timestamp,
}) {
  final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final buf = ByteData(8);
  buf.setUint8(0, messageType);
  buf.setUint8(1, (seqNum >> 8) & 0xFF);
  buf.setUint8(2, seqNum & 0xFF);
  buf.setUint8(3, 0x00);
  buf.setUint32(4, ts, Endian.big);
  return buf.buffer.asUint8List();
}

void main() {
  // ─── signMessage ────────────────────────────────────────────────────────────

  group('BleSecurityService.signMessage', () {
    test('produces 32-byte HMAC-SHA256', () {
      final sut = _makeService();
      final sig = sut.signMessage(_buildUnsigned());
      expect(sig.length, equals(32));
    });

    test('same message + same key = same signature', () {
      final sut1 = _makeService();
      final sut2 = _makeService();
      final msg = _buildUnsigned();

      expect(sut1.signMessage(msg), equals(sut2.signMessage(msg)));
    });

    test('different message = different signature', () {
      final sut = _makeService();
      final msg1 = _buildUnsigned(seqNum: 1);
      final msg2 = _buildUnsigned(seqNum: 2);

      expect(sut.signMessage(msg1), isNot(equals(sut.signMessage(msg2))));
    });

    test('different key = different signature', () {
      final sut1 = _makeService(key: _testKey);
      final sut2 = _makeService(key: _otherKey);
      final msg = _buildUnsigned();

      expect(sut1.signMessage(msg), isNot(equals(sut2.signMessage(msg))));
    });
  });

  // ─── verifySignature ────────────────────────────────────────────────────────

  group('BleSecurityService.verifySignature', () {
    test('accepts correctly signed message', () {
      final sut = _makeService();
      final signed = sut.signAndAppend(_buildUnsigned());
      expect(sut.verifySignature(signed), isTrue);
    });

    test('rejects message with tampered payload', () {
      final sut = _makeService();
      final signed = sut.signAndAppend(_buildUnsigned());
      final tampered = Uint8List.fromList(signed);
      tampered[5] ^= 0xFF; // flip a byte in the timestamp area
      expect(sut.verifySignature(tampered), isFalse);
    });

    test('rejects message signed with different key', () {
      final signer = _makeService(key: _testKey);
      final verifier = _makeService(key: _otherKey);
      final signed = signer.signAndAppend(_buildUnsigned());
      expect(verifier.verifySignature(signed), isFalse);
    });

    test('returns false for message shorter than 32 bytes', () {
      final sut = _makeService();
      final tooShort = Uint8List(31);
      expect(sut.verifySignature(tooShort), isFalse);
    });
  });

  // ─── isAuthorizedSender ─────────────────────────────────────────────────────

  group('BleSecurityService.isAuthorizedSender', () {
    // Spec §2.4 Trust Model:
    //   Conductor-only: 0x01 (SONG_CHANGED), 0x02 (METRONOME_BEAT),
    //                   0x10 (SESSION_START), 0x11 (SESSION_STOP), 0x12 (SESSION_STATUS)
    //   Any authenticated: 0x03 (ANNOTATION_INVALIDATED)

    const conductorOnlyTypes = [
      BleMessageCodec.songChanged,
      BleMessageCodec.metronomeBeat,
      BleMessageCodec.sessionStart,
      BleMessageCodec.sessionStop,
      BleMessageCodec.sessionStatus,
    ];

    test('conductor-only types (0x01, 0x02, 0x10–0x12) require leader device ID',
        () {
      final sut = _makeService();
      for (final type in conductorOnlyTypes) {
        expect(
          sut.isAuthorizedSender(type, _leaderDeviceId),
          isTrue,
          reason: 'type=0x${type.toRadixString(16)}: leader should be authorized',
        );
      }
    });

    test('annotation type (0x03) accepts any authenticated device', () {
      final sut = _makeService();
      sut.markDeviceAuthenticated(_musicianDeviceId);

      expect(
        sut.isAuthorizedSender(BleMessageCodec.annotationInvalidated, _musicianDeviceId),
        isTrue,
      );
    });

    test('annotation type also accepts leader device', () {
      final sut = _makeService();
      expect(
        sut.isAuthorizedSender(BleMessageCodec.annotationInvalidated, _leaderDeviceId),
        isTrue,
      );
    });

    test('rejects unknown device for conductor-only types', () {
      final sut = _makeService();
      for (final type in conductorOnlyTypes) {
        expect(
          sut.isAuthorizedSender(type, _musicianDeviceId),
          isFalse,
          reason: 'type=0x${type.toRadixString(16)}: musician should NOT be authorized',
        );
      }
    });

    test('rejects unauthenticated device for annotation type', () {
      final sut = _makeService();
      // 'stranger' is NOT in authenticatedDevices
      expect(
        sut.isAuthorizedSender(BleMessageCodec.annotationInvalidated, 'stranger'),
        isFalse,
      );
    });
  });

  // ─── validateMessage (full pipeline) ───────────────────────────────────────

  group('BleSecurityService.validateMessage', () {
    test('accepts valid signed message from authorized sender', () {
      final sut = _makeService();
      final signed = sut.signAndAppend(_buildUnsigned(seqNum: 1));
      expect(sut.validateMessage(signed, _leaderDeviceId), isTrue);
    });

    test('rejects invalid signature', () {
      final sut = _makeService(key: _testKey);
      // Sign with one service, validate with another (different key)
      final otherSut = _makeService(key: _otherKey);
      final signed = otherSut.signAndAppend(_buildUnsigned(seqNum: 1));
      expect(sut.validateMessage(signed, _leaderDeviceId), isFalse);
    });

    test('rejects unauthorized sender', () {
      final sut = _makeService();
      final signed = sut.signAndAppend(
        _buildUnsigned(messageType: BleMessageCodec.songChanged, seqNum: 1),
      );
      // 'rogue-musician' is not the leader
      expect(sut.validateMessage(signed, 'rogue-musician'), isFalse);
    });

    test('rejects replayed message (same sequence number)', () {
      final sut = _makeService();
      final signed = sut.signAndAppend(_buildUnsigned(seqNum: 10));

      // First delivery — accepted
      expect(sut.validateMessage(signed, _leaderDeviceId), isTrue);
      // Replayed delivery — rejected
      expect(sut.validateMessage(signed, _leaderDeviceId), isFalse);
    });

    test('rejects message with old timestamp (> 5 sec drift)', () {
      final sut = _makeService();
      final oldTs =
          DateTime.now().subtract(const Duration(seconds: 10)).millisecondsSinceEpoch ~/
              1000;
      final signed =
          sut.signAndAppend(_buildUnsigned(seqNum: 1, timestamp: oldTs));
      expect(sut.validateMessage(signed, _leaderDeviceId), isFalse);
    });

    test('accepts message within 5 second time window', () {
      final sut = _makeService();
      final recentTs =
          DateTime.now().subtract(const Duration(seconds: 3)).millisecondsSinceEpoch ~/
              1000;
      final signed =
          sut.signAndAppend(_buildUnsigned(seqNum: 1, timestamp: recentTs));
      expect(sut.validateMessage(signed, _leaderDeviceId), isTrue);
    });
  });

  // ─── Challenge-Response ─────────────────────────────────────────────────────

  group('BleSecurityService Challenge-Response', () {
    test('createChallenge returns 16 random bytes', () {
      final sut = _makeService();
      final challenge = sut.createChallenge();
      expect(challenge.length, equals(16));
    });

    test('respondToChallenge produces 32-byte HMAC of nonce with session key', () {
      final sut = _makeService();
      final nonce = sut.createChallenge();
      final response = sut.respondToChallenge(nonce);
      expect(response.length, equals(32));
    });

    test('verifyChallenge accepts correct response', () {
      final sut = _makeService();
      final nonce = sut.createChallenge();
      final response = sut.respondToChallenge(nonce);
      expect(sut.verifyChallenge(nonce, response), isTrue);
    });

    test('verifyChallenge rejects incorrect response', () {
      final sut = _makeService();
      final nonce = sut.createChallenge();
      final wrongResponse = Uint8List(32); // all zeroes
      expect(sut.verifyChallenge(nonce, wrongResponse), isFalse);
    });

    test('verifyChallenge rejects response generated with different key', () {
      final sut1 = _makeService(key: _testKey);
      final sut2 = _makeService(key: _otherKey);
      final nonce = sut1.createChallenge();
      final response = sut2.respondToChallenge(nonce); // signed with otherKey
      expect(sut1.verifyChallenge(nonce, response), isFalse);
    });

    test('two challenges produce different nonces', () {
      final sut = _makeService();
      final c1 = sut.createChallenge();
      final c2 = sut.createChallenge();
      // 16 random bytes — collision probability is 1 in 2^128
      expect(c1, isNot(equals(c2)));
    });
  });

  // ─── ReplayProtection (standalone class) ───────────────────────────────────

  group('ReplayProtection', () {
    int nowTs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

    test('accepts first message from sender', () {
      final rp = ReplayProtection();
      expect(rp.isValid('sender-1', 1, nowTs()), isTrue);
    });

    test('accepts increasing sequence numbers', () {
      final rp = ReplayProtection();
      final ts = nowTs();
      expect(rp.isValid('sender-1', 1, ts), isTrue);
      expect(rp.isValid('sender-1', 2, ts), isTrue);
      expect(rp.isValid('sender-1', 10, ts), isTrue);
    });

    test('rejects same sequence number (replay attack)', () {
      final rp = ReplayProtection();
      final ts = nowTs();
      expect(rp.isValid('sender-1', 5, ts), isTrue);
      expect(rp.isValid('sender-1', 5, ts), isFalse,
          reason: 'duplicate seq=5 should be rejected');
    });

    test('rejects lower sequence number', () {
      final rp = ReplayProtection();
      final ts = nowTs();
      expect(rp.isValid('sender-1', 10, ts), isTrue);
      expect(rp.isValid('sender-1', 9, ts), isFalse);
      expect(rp.isValid('sender-1', 1, ts), isFalse);
    });

    test('tracks sequence numbers per sender independently', () {
      final rp = ReplayProtection();
      final ts = nowTs();

      expect(rp.isValid('sender-A', 5, ts), isTrue);
      // Same seq number for a DIFFERENT sender is OK
      expect(rp.isValid('sender-B', 5, ts), isTrue,
          reason: 'sender-B has its own independent counter');
      // But replaying for sender-A is not OK
      expect(rp.isValid('sender-A', 5, ts), isFalse);
    });

    test('rejects timestamp older than 5 seconds', () {
      final rp = ReplayProtection();
      final oldTs = nowTs() - 10; // 10 seconds ago
      expect(rp.isValid('sender-1', 1, oldTs), isFalse);
    });

    test('accepts timestamp within 5 second window', () {
      final rp = ReplayProtection();
      final recentTs = nowTs() - 3; // 3 seconds ago
      expect(rp.isValid('sender-1', 1, recentTs), isTrue);
    });

    test('handles sequence number near uint16 max (65535)', () {
      final rp = ReplayProtection();
      final ts = nowTs();

      expect(rp.isValid('sender-1', 65534, ts), isTrue);
      expect(rp.isValid('sender-1', 65535, ts), isTrue);
      // Replay at 65535 is rejected
      expect(rp.isValid('sender-1', 65535, ts), isFalse);
    });
  });
}
