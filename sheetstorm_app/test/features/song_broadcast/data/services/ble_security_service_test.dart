import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_security_service.dart';

// Spec reference: docs/specs/2026-03-30-ble-broadcast-dirigent.md §2.2–§2.5
//
// Security model:
//  - HMAC-SHA256 signatures over (header + timestamp + payload)
//  - signMessage  → appends 32-byte HMAC to unsigned bytes
//  - verifySignature → checks HMAC of (message minus last 32 bytes)
//  - isAuthorizedSender → enforces conductor-only / any-authenticated trust model
//  - validateMessage → full pipeline: sig + auth + replay + timestamp
//  - Challenge-Response → proves shared key without transmitting it

// ─── Fixtures ────────────────────────────────────────────────────────────────

/// 32-byte session key used in most tests.
final _testKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

/// A different key used to verify key-sensitivity tests.
final _otherKey = Uint8List.fromList(List.generate(32, (i) => i + 50));

BleSessionInfo _makeSession({
  Uint8List? key,
  String leaderDeviceId = 'leader-device-id',
  Set<String>? authenticatedDevices,
  Duration validity = const Duration(hours: 4),
}) {
  final k = key ?? _testKey;
  return BleSessionInfo(
    sessionKey: base64Encode(k),
    leaderDeviceId: leaderDeviceId,
    expiresAt: DateTime.now().add(validity),
    authenticatedDevices:
        authenticatedDevices ?? {leaderDeviceId, 'musician-device-id'},
  );
}

/// Creates an unsigned BLE message via the codec (ready for signing).
Uint8List _buildUnsigned({
  int messageType = 0x01,
  int seqNum = 1,
  int? timestamp,
  Uint8List? payload,
}) {
  final ts = timestamp ??
      (DateTime.now().millisecondsSinceEpoch ~/ 1000);
  return BleMessageCodec.encode(
    messageType: messageType,
    sequenceNumber: seqNum,
    flags: 0x00,
    timestamp: ts,
    payload: payload ?? Uint8List(4),
  );
}

void main() {
  late BleSecurityService sut;

  setUp(() {
    sut = BleSecurityService();
  });

  // ─── signMessage ────────────────────────────────────────────────────────────

  group('BleSecurityService.signMessage', () {
    test('produces 32-byte HMAC-SHA256 appended to message', () {
      final unsigned = _buildUnsigned();
      final signed = sut.signMessage(unsigned, _testKey);

      expect(signed.length, equals(unsigned.length + 32));
    });

    test('same message + same key = same signature', () {
      final unsigned = _buildUnsigned();
      final sig1 = sut.signMessage(unsigned, _testKey);
      final sig2 = sut.signMessage(unsigned, _testKey);

      expect(sig1, equals(sig2));
    });

    test('different message = different signature', () {
      final msg1 = _buildUnsigned(payload: Uint8List.fromList([0x01]));
      final msg2 = _buildUnsigned(payload: Uint8List.fromList([0x02]));

      final sig1 = sut.signMessage(msg1, _testKey);
      final sig2 = sut.signMessage(msg2, _testKey);

      expect(
        sig1.sublist(sig1.length - 32),
        isNot(equals(sig2.sublist(sig2.length - 32))),
      );
    });

    test('different key = different signature', () {
      final unsigned = _buildUnsigned();
      final sig1 = sut.signMessage(unsigned, _testKey);
      final sig2 = sut.signMessage(unsigned, _otherKey);

      expect(
        sig1.sublist(sig1.length - 32),
        isNot(equals(sig2.sublist(sig2.length - 32))),
      );
    });
  });

  // ─── verifySignature ────────────────────────────────────────────────────────

  group('BleSecurityService.verifySignature', () {
    test('accepts correctly signed message', () {
      final signed = sut.signMessage(_buildUnsigned(), _testKey);
      expect(sut.verifySignature(signed, _testKey), isTrue);
    });

    test('rejects message with tampered payload', () {
      final signed = sut.signMessage(_buildUnsigned(), _testKey);
      // Flip a byte in the payload area (byte 10, inside payload)
      final tampered = Uint8List.fromList(signed);
      tampered[10] ^= 0xFF;
      expect(sut.verifySignature(tampered, _testKey), isFalse);
    });

    test('rejects message with wrong key', () {
      final signed = sut.signMessage(_buildUnsigned(), _testKey);
      expect(sut.verifySignature(signed, _otherKey), isFalse);
    });

    test('rejects message with truncated signature', () {
      final signed = sut.signMessage(_buildUnsigned(), _testKey);
      // Remove the last 16 bytes (half the signature)
      final truncated = signed.sublist(0, signed.length - 16);
      expect(
        () => sut.verifySignature(truncated, _testKey),
        throwsArgumentError,
      );
    });
  });

  // ─── isAuthorizedSender ─────────────────────────────────────────────────────

  group('BleSecurityService.isAuthorizedSender', () {
    // Spec §2.4 Trust Model:
    //   0x01 SONG_CHANGED      → conductor only
    //   0x02 METRONOME_BEAT    → conductor only
    //   0x10 SESSION_START     → conductor only
    //   0x11 SESSION_STOP      → conductor only
    //   0x12 SESSION_STATUS    → conductor only
    //   0x03 ANNOTATION_INVALIDATED → any authenticated device

    const conductorOnlyTypes = [0x01, 0x02, 0x10, 0x11, 0x12];
    const leaderDeviceId = 'leader-device-id';
    const musicianDeviceId = 'musician-device-id';
    const unknownDeviceId = 'unknown-device-id';

    test('conductor-only types (0x01, 0x02, 0x10-0x12) require leader device ID',
        () {
      final session = _makeSession(
        authenticatedDevices: {leaderDeviceId, musicianDeviceId},
      );

      for (final type in conductorOnlyTypes) {
        expect(
          sut.isAuthorizedSender(type, leaderDeviceId, session),
          isTrue,
          reason: 'type=0x${type.toRadixString(16)}: leader should be authorized',
        );
      }
    });

    test('annotation type (0x03) accepts any authenticated device', () {
      final session = _makeSession(
        authenticatedDevices: {leaderDeviceId, musicianDeviceId},
      );

      expect(sut.isAuthorizedSender(0x03, leaderDeviceId, session), isTrue);
      expect(sut.isAuthorizedSender(0x03, musicianDeviceId, session), isTrue);
    });

    test('rejects unknown device for conductor-only types', () {
      final session = _makeSession(
        authenticatedDevices: {leaderDeviceId, musicianDeviceId},
      );

      for (final type in conductorOnlyTypes) {
        expect(
          sut.isAuthorizedSender(type, musicianDeviceId, session),
          isFalse,
          reason:
              'type=0x${type.toRadixString(16)}: musician should NOT be authorized',
        );
        expect(
          sut.isAuthorizedSender(type, unknownDeviceId, session),
          isFalse,
          reason:
              'type=0x${type.toRadixString(16)}: unknown device should NOT be authorized',
        );
      }
    });

    test('rejects unauthenticated device for annotation type', () {
      final session = _makeSession(
        authenticatedDevices: {leaderDeviceId},
      );

      // musicianDeviceId is NOT in authenticatedDevices here
      expect(sut.isAuthorizedSender(0x03, 'stranger-device', session), isFalse);
    });
  });

  // ─── validateMessage (full pipeline) ───────────────────────────────────────

  group('BleSecurityService.validateMessage', () {
    test('accepts valid signed message from authorized sender', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final unsigned = _buildUnsigned(messageType: 0x01, seqNum: 1);
      final signed = sut.signMessage(unsigned, _testKey);

      final result = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );

      expect(result, equals(BleValidationResult.valid));
    });

    test('rejects invalid signature', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final unsigned = _buildUnsigned(messageType: 0x01, seqNum: 1);
      final signed = sut.signMessage(unsigned, _otherKey); // wrong key

      final result = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );

      expect(result, equals(BleValidationResult.invalidSignature));
    });

    test('rejects unauthorized sender', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final unsigned = _buildUnsigned(messageType: 0x01, seqNum: 1);
      final signed = sut.signMessage(unsigned, _testKey);

      final result = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: 'rogue-musician', // not the leader
        session: session,
        replayProtection: replay,
      );

      expect(result, equals(BleValidationResult.unauthorizedSender));
    });

    test('rejects replayed message (same sequence number)', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final unsigned = _buildUnsigned(messageType: 0x01, seqNum: 10);
      final signed = sut.signMessage(unsigned, _testKey);

      // First delivery — accepted
      final first = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );
      expect(first, equals(BleValidationResult.valid));

      // Replayed delivery — rejected
      final replayed = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );
      expect(replayed, equals(BleValidationResult.replayDetected));
    });

    test('rejects message with old timestamp (> 5 sec drift)', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final oldTs = DateTime.now()
              .subtract(const Duration(seconds: 10))
              .millisecondsSinceEpoch ~/
          1000;
      final unsigned = _buildUnsigned(
        messageType: 0x01,
        seqNum: 1,
        timestamp: oldTs,
      );
      final signed = sut.signMessage(unsigned, _testKey);

      final result = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );

      expect(result, equals(BleValidationResult.timestampExpired));
    });

    test('accepts message within 5 second time window', () {
      final session = _makeSession();
      final replay = ReplayProtection();

      final recentTs = DateTime.now()
              .subtract(const Duration(seconds: 3))
              .millisecondsSinceEpoch ~/
          1000;
      final unsigned = _buildUnsigned(
        messageType: 0x01,
        seqNum: 1,
        timestamp: recentTs,
      );
      final signed = sut.signMessage(unsigned, _testKey);

      final result = sut.validateMessage(
        signedMessage: signed,
        senderDeviceId: session.leaderDeviceId,
        session: session,
        replayProtection: replay,
      );

      expect(result, equals(BleValidationResult.valid));
    });
  });

  // ─── Challenge-Response ─────────────────────────────────────────────────────

  group('BleSecurityService Challenge-Response', () {
    test('createChallenge returns 16 random bytes', () {
      final challenge = sut.createChallenge();
      expect(challenge.length, equals(16));
    });

    test('respondToChallenge produces HMAC (32 bytes) of nonce with session key',
        () {
      final nonce = sut.createChallenge();
      final response = sut.respondToChallenge(nonce, _testKey);
      expect(response.length, equals(32));
    });

    test('verifyChallenge accepts correct response', () {
      final nonce = sut.createChallenge();
      final response = sut.respondToChallenge(nonce, _testKey);
      expect(sut.verifyChallenge(nonce, response, _testKey), isTrue);
    });

    test('verifyChallenge rejects incorrect response', () {
      final nonce = sut.createChallenge();
      final wrongResponse = Uint8List(32); // all zeroes
      expect(sut.verifyChallenge(nonce, wrongResponse, _testKey), isFalse);
    });

    test('verifyChallenge rejects response generated with wrong key', () {
      final nonce = sut.createChallenge();
      final response = sut.respondToChallenge(nonce, _otherKey);
      expect(sut.verifyChallenge(nonce, response, _testKey), isFalse);
    });

    test('two challenges produce different nonces', () {
      final c1 = sut.createChallenge();
      final c2 = sut.createChallenge();
      // 16 random bytes: collision probability is negligible (1 in 2^128)
      expect(c1, isNot(equals(c2)));
    });
  });

  // ─── ReplayProtection ───────────────────────────────────────────────────────

  group('ReplayProtection', () {
    int _nowTs() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

    test('accepts first message from sender', () {
      final rp = ReplayProtection();
      expect(rp.isValid('sender-1', 1, _nowTs()), isTrue);
    });

    test('accepts increasing sequence numbers', () {
      final rp = ReplayProtection();
      final ts = _nowTs();
      expect(rp.isValid('sender-1', 1, ts), isTrue);
      expect(rp.isValid('sender-1', 2, ts), isTrue);
      expect(rp.isValid('sender-1', 10, ts), isTrue);
    });

    test('rejects same sequence number (replay)', () {
      final rp = ReplayProtection();
      final ts = _nowTs();
      expect(rp.isValid('sender-1', 5, ts), isTrue);
      expect(rp.isValid('sender-1', 5, ts), isFalse);
    });

    test('rejects lower sequence number', () {
      final rp = ReplayProtection();
      final ts = _nowTs();
      expect(rp.isValid('sender-1', 10, ts), isTrue);
      expect(rp.isValid('sender-1', 9, ts), isFalse);
      expect(rp.isValid('sender-1', 1, ts), isFalse);
    });

    test('tracks sequence numbers per sender independently', () {
      final rp = ReplayProtection();
      final ts = _nowTs();

      expect(rp.isValid('sender-A', 5, ts), isTrue);
      expect(rp.isValid('sender-B', 5, ts), isTrue, // same seq, different sender
          reason: 'sender-B sequence is independent from sender-A');
      expect(rp.isValid('sender-A', 5, ts), isFalse,
          reason: 'replay for sender-A');
    });

    test('rejects timestamp older than 5 seconds', () {
      final rp = ReplayProtection();
      final oldTs = _nowTs() - 10; // 10 seconds ago
      expect(rp.isValid('sender-1', 1, oldTs), isFalse);
    });

    test('accepts timestamp within 5 second window', () {
      final rp = ReplayProtection();
      final recentTs = _nowTs() - 3; // 3 seconds ago
      expect(rp.isValid('sender-1', 1, recentTs), isTrue);
    });

    test('handles sequence number near uint16 max (65535)', () {
      final rp = ReplayProtection();
      final ts = _nowTs();

      expect(rp.isValid('sender-1', 65534, ts), isTrue);
      expect(rp.isValid('sender-1', 65535, ts), isTrue);
      // After max, 65535 is the last seen — next expected would be higher
      // Spec note: overflow handling is implementation-defined (session restart)
      expect(rp.isValid('sender-1', 65535, ts), isFalse,
          reason: 'same seq as last seen should be rejected');
    });
  });
}
