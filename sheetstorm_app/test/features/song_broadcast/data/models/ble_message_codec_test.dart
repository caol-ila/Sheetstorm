// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';

// Spec reference: docs/specs/2026-03-30-ble-broadcast-dirigent.md §2.2 §3
//
// BLE Message Format:
//   [0]     Message Type  (uint8)
//   [1..2]  Sequence Num  (uint16, Big Endian)
//   [3]     Flags         (uint8)
//   [4..7]  Timestamp     (uint32, Unix epoch seconds, Big Endian)
//   [8..N]  Payload       (variable, max 182 bytes)
//   [N+1..] HMAC-SHA256   (32 bytes, appended by security service)
//
// IMPORTANT: BleMessageCodec.encode / encode* return the UNSIGNED bytes
// (header + timestamp + payload). The 32-byte HMAC is appended separately
// by BleSecurityService.signMessage().
// BleMessageCodec.decode() expects the FULLY SIGNED message (with HMAC at end).

// Helper: appends a dummy 32-byte HMAC so decode() can process encode() output.
Uint8List _withDummySignature(Uint8List unsigned) =>
    Uint8List.fromList([...unsigned, ...Uint8List(32)]);

void main() {
  // ─── encode ─────────────────────────────────────────────────────────────────

  group('BleMessageCodec.encode', () {
    test('produces correct header format (type, seq, flags)', () {
      final msg = BleMessageCodec.encode(
        messageType: 0x01,
        sequenceNumber: 42,
        flags: 0x80,
        timestamp: 1234567890,
        payload: Uint8List(5),
      );

      expect(msg[0], equals(0x01), reason: 'byte 0: message type');
      expect(msg[1], equals(0x00), reason: 'byte 1: seq high (42 = 0x002A)');
      expect(msg[2], equals(0x2A), reason: 'byte 2: seq low');
      expect(msg[3], equals(0x80), reason: 'byte 3: flags');
    });

    test('includes 4-byte timestamp at bytes 4–7', () {
      final msg = BleMessageCodec.encode(
        messageType: 0x01,
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 0xDEADBEEF,
        payload: Uint8List(0),
      );

      final bd = ByteData.sublistView(msg);
      expect(bd.getUint32(4, Endian.big), equals(0xDEADBEEF));
    });

    test('appends payload after header+timestamp (at byte 8)', () {
      final payload = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
      final msg = BleMessageCodec.encode(
        messageType: 0x01,
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        payload: payload,
      );

      expect(msg[8], equals(0xAA));
      expect(msg[9], equals(0xBB));
      expect(msg[10], equals(0xCC));
    });

    test('total length = 4 + 4 + payload.length (no HMAC yet)', () {
      final payload = Uint8List(20);
      final msg = BleMessageCodec.encode(
        messageType: 0x01,
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        payload: payload,
      );

      expect(msg.length, equals(4 + 4 + 20));
    });

    test('sequence number uses big-endian encoding', () {
      // 300 decimal = 0x012C
      final msg = BleMessageCodec.encode(
        messageType: 0x01,
        sequenceNumber: 300,
        flags: 0x00,
        timestamp: 12345,
        payload: Uint8List(0),
      );

      expect(msg[1], equals(0x01), reason: 'high byte of 300');
      expect(msg[2], equals(0x2C), reason: 'low byte of 300');
    });
  });

  // ─── decode ─────────────────────────────────────────────────────────────────

  group('BleMessageCodec.decode', () {
    /// Builds a valid signed message for decode testing.
    Uint8List buildSignedMessage({
      int type = 0x01,
      int seqNum = 1,
      int flags = 0x00,
      int timestamp = 1234567890,
      Uint8List? payload,
      Uint8List? signature,
    }) {
      payload ??= Uint8List(0);
      signature ??= Uint8List(32);

      final total = 4 + 4 + payload.length + 32;
      final buf = Uint8List(total);
      final bd = ByteData.sublistView(buf);

      bd.setUint8(0, type);
      bd.setUint16(1, seqNum, Endian.big);
      bd.setUint8(3, flags);
      bd.setUint32(4, timestamp, Endian.big);
      buf.setRange(8, 8 + payload.length, payload);
      buf.setRange(8 + payload.length, total, signature);

      return buf;
    }

    test('extracts message type from first byte', () {
      final msg = buildSignedMessage(type: 0x02);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.messageType, equals(0x02));
    });

    test('extracts sequence number from bytes 1-2', () {
      final msg = buildSignedMessage(seqNum: 12345);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.sequenceNumber, equals(12345));
    });

    test('extracts flags from byte 3', () {
      final msg = buildSignedMessage(flags: 0x42);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.flags, equals(0x42));
    });

    test('extracts timestamp from bytes 4-7', () {
      final msg = buildSignedMessage(timestamp: 9876543);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.timestamp, equals(9876543));
    });

    test('extracts payload from bytes 8 to end-32', () {
      final payload = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final msg = buildSignedMessage(payload: payload);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.payload, equals(payload));
    });

    test('extracts 32-byte HMAC signature from end', () {
      final sig = Uint8List.fromList(List.generate(32, (i) => i));
      final msg = buildSignedMessage(signature: sig);
      final decoded = BleMessageCodec.decode(msg);
      expect(decoded.signature.length, equals(32));
      expect(decoded.signature, equals(sig));
    });

    test('throws on message shorter than minimum (4+4+32 = 40 bytes)', () {
      final tooShort = Uint8List(39);
      expect(() => BleMessageCodec.decode(tooShort), throwsArgumentError);
    });
  });

  // ─── encodeSongChanged ──────────────────────────────────────────────────────

  group('BleMessageCodec.encodeSongChanged', () {
    test('uses message type 0x01', () {
      final msg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: 'abc',
        stueckTitel: 'Test',
      );

      expect(msg[0], equals(0x01));
    });

    test('encodes stueckId as UTF-8 with uint16 length prefix', () {
      const stueckId = 'piece-id-ü';
      final msg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: stueckId,
        stueckTitel: 'T',
      );

      // Payload starts at byte 8: [2 bytes stueckId length][stueckId UTF-8][...]
      final bd = ByteData.sublistView(msg, 8);
      final idLen = bd.getUint16(0, Endian.big);
      expect(idLen, equals(utf8.encode(stueckId).length));
    });

    test('encodes stueckTitel as UTF-8 with uint16 length prefix', () {
      const stueckId = 'id';
      const stueckTitel = 'Böhmische Polka';
      final msg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: stueckId,
        stueckTitel: stueckTitel,
      );

      final idBytes = utf8.encode(stueckId);
      // Title length field is at: 2 (id_len) + idBytes.length into payload
      final titleLenOffset = 2 + idBytes.length;
      final bd = ByteData.sublistView(msg, 8);
      final titleLen = bd.getUint16(titleLenOffset, Endian.big);
      expect(titleLen, equals(utf8.encode(stueckTitel).length));
    });

    test('total payload (without HMAC) fits in 4+4+182 = 190 bytes max', () {
      final longTitle = 'A' * 300;
      final msg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: 'id',
        stueckTitel: longTitle,
      );

      expect(msg.length, lessThanOrEqualTo(4 + 4 + 182));
    });

    test('truncates long titles to fit MTU — short title produces smaller message', () {
      final longMsg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: 'id',
        stueckTitel: 'A' * 500,
      );
      final shortMsg = BleMessageCodec.encodeSongChanged(
        sequenceNumber: 1,
        flags: 0x00,
        timestamp: 12345,
        stueckId: 'id',
        stueckTitel: 'Short',
      );

      expect(longMsg.length, lessThanOrEqualTo(4 + 4 + 182));
      expect(shortMsg.length, lessThan(longMsg.length));
    });
  });

  // ─── encodeMetronomeBeat ────────────────────────────────────────────────────

  group('BleMessageCodec.encodeMetronomeBeat', () {
    // Spec §3.2: payload is exactly 14 bytes
    // [0..1] BPM uint16, [2] beatsPerMeasure uint8, [3] beatUnit uint8,
    // [4..7] beatTimestampMs uint32, [8..9] beatNumberInMeasure uint16,
    // [10..13] nextBeatMs uint32

    Uint8List _encode({
      int bpm = 120,
      int beatsPerMeasure = 4,
      int beatUnit = 4,
      int beatTimestampMs = 1000,
      int beatNumberInMeasure = 1,
      int nextBeatMs = 1500,
    }) =>
        BleMessageCodec.encodeMetronomeBeat(
          sequenceNumber: 1,
          flags: 0x00,
          timestamp: 12345,
          bpm: bpm,
          beatsPerMeasure: beatsPerMeasure,
          beatUnit: beatUnit,
          beatTimestampMs: beatTimestampMs,
          beatNumberInMeasure: beatNumberInMeasure,
          nextBeatMs: nextBeatMs,
        );

    test('uses message type 0x02', () {
      expect(_encode()[0], equals(0x02));
    });

    test('encodes BPM as uint16 at payload offset 0', () {
      final msg = _encode(bpm: 180);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint16(0, Endian.big), equals(180));
    });

    test('encodes time signature (beatsPerMeasure, beatUnit)', () {
      final msg = _encode(beatsPerMeasure: 3, beatUnit: 8);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint8(2), equals(3), reason: 'beatsPerMeasure at offset 2');
      expect(bd.getUint8(3), equals(8), reason: 'beatUnit at offset 3');
    });

    test('encodes beat timestamp as uint32 at payload offset 4', () {
      final msg = _encode(beatTimestampMs: 0xDEAD);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint32(4, Endian.big), equals(0xDEAD));
    });

    test('encodes next beat prediction as uint32 at payload offset 10', () {
      final msg = _encode(nextBeatMs: 1500);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint32(10, Endian.big), equals(1500));
    });
  });

  // ─── encodeAnnotationInvalidation ──────────────────────────────────────────

  group('BleMessageCodec.encodeAnnotationInvalidation', () {
    // Spec §3.3: [0..15] stueckGuid (16 bytes binary), [16..17] stimmeId len,
    //            [18..N] stimmeId (UTF-8), [N+1] updateType uint8

    const kTestGuid = '550e8400-e29b-41d4-a716-446655440000';

    Uint8List _encode({
      String stueckGuid = kTestGuid,
      String stimmeId = 'stimme-1',
      int updateType = 0x01,
    }) =>
        BleMessageCodec.encodeAnnotationInvalidation(
          sequenceNumber: 1,
          flags: 0x00,
          timestamp: 12345,
          stueckGuid: stueckGuid,
          stimmeId: stimmeId,
          updateType: updateType,
        );

    test('uses message type 0x03', () {
      expect(_encode()[0], equals(0x03));
    });

    test('encodes stueckGuid as 16 bytes in payload', () {
      final msg = _encode();
      // At minimum: 8 (header+ts) + 16 (guid) + 2 (stimmeId len) + 1 (updateType)
      expect(msg.length, greaterThanOrEqualTo(8 + 16 + 2 + 1));
    });

    test('encodes stimmeId as UTF-8 with uint16 length prefix', () {
      const stimmeId = 'trompete-1';
      final msg = _encode(stimmeId: stimmeId);
      // After 8 (header+ts) + 16 (guid): [2 bytes stimmeId length]
      final bd = ByteData.sublistView(msg, 8 + 16);
      final len = bd.getUint16(0, Endian.big);
      expect(len, equals(utf8.encode(stimmeId).length));
    });

    test('encodes update type as uint8 after stimmeId', () {
      for (final updateType in [0x01, 0x02, 0x03]) {
        const stimmeId = 'stimme-1';
        final msg = _encode(stimmeId: stimmeId, updateType: updateType);
        final stimmeIdBytes = utf8.encode(stimmeId);
        // updateType offset: 8 (header+ts) + 16 (guid) + 2 (len) + stimmeIdBytes.length
        final offset = 8 + 16 + 2 + stimmeIdBytes.length;
        expect(msg[offset], equals(updateType),
            reason: 'updateType=$updateType');
      }
    });
  });

  // ─── round-trip ─────────────────────────────────────────────────────────────

  group('BleMessageCodec round-trip', () {
    test('encode then decode produces original values for song changed', () {
      const seqNum = 7;
      const ts = 1700000000;
      final unsigned = BleMessageCodec.encodeSongChanged(
        sequenceNumber: seqNum,
        flags: 0x00,
        timestamp: ts,
        stueckId: 'piece-abc-123',
        stueckTitel: 'Böhmische Polka',
      );
      final signed = _withDummySignature(unsigned);
      final decoded = BleMessageCodec.decode(signed);

      expect(decoded.messageType, equals(0x01));
      expect(decoded.sequenceNumber, equals(seqNum));
      expect(decoded.timestamp, equals(ts));
      expect(decoded.signature.length, equals(32));
    });

    test('encode then decode produces original values for metronome beat', () {
      const seqNum = 100;
      const ts = 1700000001;
      final unsigned = BleMessageCodec.encodeMetronomeBeat(
        sequenceNumber: seqNum,
        flags: 0x00,
        timestamp: ts,
        bpm: 120,
        beatsPerMeasure: 4,
        beatUnit: 4,
        beatTimestampMs: 5000,
        beatNumberInMeasure: 2,
        nextBeatMs: 5500,
      );
      final signed = _withDummySignature(unsigned);
      final decoded = BleMessageCodec.decode(signed);

      expect(decoded.messageType, equals(0x02));
      expect(decoded.sequenceNumber, equals(seqNum));
      expect(decoded.timestamp, equals(ts));

      // Verify BPM survives round-trip
      final bd = ByteData.sublistView(decoded.payload);
      expect(bd.getUint16(0, Endian.big), equals(120));
    });

    test('encode then decode produces original values for annotation', () {
      const seqNum = 5;
      const ts = 1700000002;
      final unsigned = BleMessageCodec.encodeAnnotationInvalidation(
        sequenceNumber: seqNum,
        flags: 0x00,
        timestamp: ts,
        stueckGuid: '550e8400-e29b-41d4-a716-446655440000',
        stimmeId: 'trumpet',
        updateType: 0x02,
      );
      final signed = _withDummySignature(unsigned);
      final decoded = BleMessageCodec.decode(signed);

      expect(decoded.messageType, equals(0x03));
      expect(decoded.sequenceNumber, equals(seqNum));
      expect(decoded.timestamp, equals(ts));
    });
  });
}
