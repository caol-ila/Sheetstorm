// Tests for BleMessageCodec — binary encode/decode of BLE messages.
//
// Spec: docs/specs/2026-03-30-ble-broadcast-dirigent.md §2.2, §3
//
// Message format (encode output = unsigned, no HMAC):
//   [0]    message type   uint8
//   [1]    seq high byte  uint8
//   [2]    seq low byte   uint8
//   [3]    flags          uint8 (always 0 in this implementation)
//   [4..7] timestamp      uint32 big-endian (Unix seconds, set to DateTime.now())
//   [8..N] payload        (type-specific)
//
// decode() expects the FULLY SIGNED message (encode output + 32-byte HMAC at end).
// The decoded result is BleMessage with messageType, sequenceNumber, flags,
// timestamp, payload (without HMAC), and signature (the 32 HMAC bytes).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

// Appends a dummy 32-byte HMAC so decode() can process the unsigned output.
Uint8List _withDummyHmac(Uint8List unsigned) =>
    Uint8List.fromList([...unsigned, ...Uint8List(32)]);

void main() {
  late BleMessageCodec codec;

  setUp(() {
    codec = BleMessageCodec();
  });

  // ─── encode ─────────────────────────────────────────────────────────────────

  group('BleMessageCodec.encode', () {
    test('produces correct header format (type, seq, flags)', () {
      final msg = codec.encode(0x01, Uint8List(5), 42);

      expect(msg[0], equals(0x01), reason: 'byte 0: message type');
      expect(msg[1], equals(0x00), reason: 'byte 1: seq high (42 = 0x002A)');
      expect(msg[2], equals(0x2A), reason: 'byte 2: seq low');
      expect(msg[3], equals(0x00), reason: 'byte 3: flags (always 0)');
    });

    test('includes 4-byte timestamp at bytes 4–7', () {
      final before = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final msg = codec.encode(0x01, Uint8List(0), 1);
      final after = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final ts = ByteData.sublistView(msg).getUint32(4, Endian.big);
      expect(ts, greaterThanOrEqualTo(before));
      expect(ts, lessThanOrEqualTo(after));
    });

    test('appends payload after header+timestamp (starting at byte 8)', () {
      final payload = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
      final msg = codec.encode(0x01, payload, 1);

      expect(msg[8], equals(0xAA));
      expect(msg[9], equals(0xBB));
      expect(msg[10], equals(0xCC));
    });

    test('total length = 4 + 4 + payload.length (no HMAC appended)', () {
      final payload = Uint8List(20);
      final msg = codec.encode(0x01, payload, 1);

      expect(msg.length, equals(4 + 4 + 20));
    });

    test('sequence number uses big-endian encoding across bytes 1–2', () {
      // 300 = 0x012C
      final msg = codec.encode(0x01, Uint8List(0), 300);

      expect(msg[1], equals(0x01), reason: 'high byte of 300');
      expect(msg[2], equals(0x2C), reason: 'low byte of 300');
    });
  });

  // ─── decode ─────────────────────────────────────────────────────────────────

  group('BleMessageCodec.decode', () {
    /// Builds a signed message (unsigned header+payload + dummy HMAC).
    Uint8List buildSigned({
      int type = 0x01,
      int seqNum = 1,
      int flags = 0x00,
      int? timestamp,
      Uint8List? payload,
    }) {
      payload ??= Uint8List(0);
      final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final total = 4 + 4 + payload.length + 32;
      final buf = Uint8List(total);
      final bd = ByteData.sublistView(buf);
      bd.setUint8(0, type);
      bd.setUint8(1, (seqNum >> 8) & 0xFF);
      bd.setUint8(2, seqNum & 0xFF);
      bd.setUint8(3, flags);
      bd.setUint32(4, ts, Endian.big);
      buf.setRange(8, 8 + payload.length, payload);
      // last 32 bytes = dummy HMAC (zeroes)
      return buf;
    }

    test('extracts message type from first byte', () {
      final decoded = codec.decode(buildSigned(type: 0x02));
      expect(decoded.messageType, equals(0x02));
    });

    test('extracts sequence number from bytes 1-2', () {
      final decoded = codec.decode(buildSigned(seqNum: 12345));
      expect(decoded.sequenceNumber, equals(12345));
    });

    test('extracts flags from byte 3', () {
      final decoded = codec.decode(buildSigned(flags: 0x42));
      expect(decoded.flags, equals(0x42));
    });

    test('extracts timestamp from bytes 4-7', () {
      const ts = 9876543;
      final decoded = codec.decode(buildSigned(timestamp: ts));
      expect(decoded.timestamp, equals(ts));
    });

    test('extracts payload from bytes 8 to end-32', () {
      final payload = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
      final decoded = codec.decode(buildSigned(payload: payload));
      expect(decoded.payload, equals(payload));
    });

    test('extracts 32-byte HMAC signature from last 32 bytes', () {
      final sig = Uint8List.fromList(List.generate(32, (i) => i));
      const total = 4 + 4 + 0 + 32;
      final buf = Uint8List(total);
      final bd = ByteData.sublistView(buf);
      bd.setUint8(0, 0x01);
      buf.setRange(total - 32, total, sig);

      final decoded = codec.decode(buf);
      expect(decoded.signature.length, equals(32));
      expect(decoded.signature, equals(sig));
    });

    test('throws FormatException on message shorter than minimum (40 bytes)', () {
      final tooShort = Uint8List(39);
      expect(() => codec.decode(tooShort), throwsA(isA<FormatException>()));
    });
  });

  // ─── encodeSongChanged ──────────────────────────────────────────────────────

  group('BleMessageCodec.encodeSongChanged', () {
    test('uses message type 0x01', () {
      final msg = codec.encodeSongChanged('id', 'Title', 1);
      expect(msg[0], equals(0x01));
    });

    test('encodes stueckId as UTF-8 with 1-byte length prefix', () {
      const stueckId = 'piece-abc';
      final msg = codec.encodeSongChanged(stueckId, 'T', 1);

      // payload at byte 8: [id_len(1)][id_bytes][title_len(1)][title_bytes]
      final idLen = msg[8];
      expect(idLen, equals(utf8.encode(stueckId).length));
    });

    test('encodes stueckTitel as UTF-8 with 1-byte length prefix', () {
      const stueckId = 'id';
      const stueckTitel = 'Böhmische Polka';
      final msg = codec.encodeSongChanged(stueckId, stueckTitel, 1);

      final idLen = msg[8]; // payload[0]
      // title length is at payload[1 + idLen]
      final titleLenOffset = 8 + 1 + idLen;
      final titleLen = msg[titleLenOffset];
      expect(titleLen, equals(utf8.encode(stueckTitel).length));
    });

    test('total encoded length fits within 4+4+182 = 190 bytes max', () {
      final longTitle = 'A' * 300;
      final msg = codec.encodeSongChanged('id', longTitle, 1);
      expect(msg.length, lessThanOrEqualTo(4 + 4 + 182));
    });

    test('short title produces smaller message than truncated long title', () {
      final longMsg = codec.encodeSongChanged('id', 'A' * 500, 1);
      final shortMsg = codec.encodeSongChanged('id', 'Hi', 1);
      expect(longMsg.length, lessThanOrEqualTo(4 + 4 + 182));
      expect(shortMsg.length, lessThan(longMsg.length));
    });
  });

  // ─── encodeMetronomeBeat ────────────────────────────────────────────────────

  group('BleMessageCodec.encodeMetronomeBeat', () {
    // Spec §3.2 / actual layout from MetronomeBeatPayload.toBytes():
    //   [0..1] BPM         uint16 big-endian
    //   [2]    beatsPerMeasure uint8
    //   [3]    beatUnit       uint8
    //   [4..7] beatTimestampMs uint32 big-endian
    //   [8]    beatNumberInMeasure uint8
    //   [9..12] nextBeatMs  uint32 big-endian
    //   Total: 13 bytes

    MetronomeBeatPayload makeBeat({
      int bpm = 120,
      int beatsPerMeasure = 4,
      int beatUnit = 4,
      int beatTimestampMs = 1000,
      int beatNumberInMeasure = 1,
      int nextBeatMs = 1500,
    }) =>
        MetronomeBeatPayload(
          bpm: bpm,
          beatsPerMeasure: beatsPerMeasure,
          beatUnit: beatUnit,
          beatTimestampMs: beatTimestampMs,
          beatNumberInMeasure: beatNumberInMeasure,
          nextBeatMs: nextBeatMs,
        );

    test('uses message type 0x02', () {
      final msg = codec.encodeMetronomeBeat(makeBeat(), 1);
      expect(msg[0], equals(0x02));
    });

    test('encodes BPM as uint16 at payload offset 0', () {
      final msg = codec.encodeMetronomeBeat(makeBeat(bpm: 180), 1);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint16(0, Endian.big), equals(180));
    });

    test('encodes time signature (beatsPerMeasure, beatUnit) at offsets 2–3', () {
      final msg = codec.encodeMetronomeBeat(
          makeBeat(beatsPerMeasure: 3, beatUnit: 8), 1);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint8(2), equals(3), reason: 'beatsPerMeasure');
      expect(bd.getUint8(3), equals(8), reason: 'beatUnit');
    });

    test('encodes beat timestamp as uint32 at payload offset 4', () {
      final msg = codec.encodeMetronomeBeat(makeBeat(beatTimestampMs: 0xDEAD), 1);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint32(4, Endian.big), equals(0xDEAD));
    });

    test('encodes next beat prediction as uint32 at payload offset 9', () {
      final msg = codec.encodeMetronomeBeat(makeBeat(nextBeatMs: 99999), 1);
      final bd = ByteData.sublistView(msg, 8);
      expect(bd.getUint32(9, Endian.big), equals(99999));
    });
  });

  // ─── encodeAnnotationInvalidation ──────────────────────────────────────────

  group('BleMessageCodec.encodeAnnotationInvalidation', () {
    // Payload layout:
    //   [0..35]  stueckGuid  36-byte UTF-8 string (UUID canonical form)
    //   [36]     stimmeId length uint8
    //   [37..N]  stimmeId UTF-8 bytes
    //   [N+1]    updateType uint8 (0=created, 1=modified, 2=deleted)

    const kGuid = '550e8400-e29b-41d4-a716-446655440000';

    AnnotationInvalidationPayload makeAnn({
      String guid = kGuid,
      String stimmeId = 'stimme-1',
      AnnotationUpdateType updateType = AnnotationUpdateType.created,
    }) =>
        AnnotationInvalidationPayload(
          stueckGuid: guid,
          stimmeId: stimmeId,
          updateType: updateType,
        );

    test('uses message type 0x03', () {
      final msg = codec.encodeAnnotationInvalidation(makeAnn(), 1);
      expect(msg[0], equals(0x03));
    });

    test('encodes stueckGuid as exactly 36 bytes at start of payload', () {
      final msg = codec.encodeAnnotationInvalidation(makeAnn(), 1);
      // 8 bytes header+ts, then 36-byte GUID
      expect(msg.length, greaterThanOrEqualTo(8 + 36 + 1 + 1));
    });

    test('encodes stimmeId as UTF-8 with 1-byte length prefix at offset 36', () {
      const stimmeId = 'trompete-1';
      final msg = codec.encodeAnnotationInvalidation(makeAnn(stimmeId: stimmeId), 1);
      // payload[36] = stimmeId length
      final stimmeLen = msg[8 + 36];
      expect(stimmeLen, equals(utf8.encode(stimmeId).length));
    });

    test('encodes update type as uint8 after stimmeId bytes', () {
      for (final type in AnnotationUpdateType.values) {
        const stimmeId = 'stimme-1';
        final msg = codec.encodeAnnotationInvalidation(
          makeAnn(stimmeId: stimmeId, updateType: type),
          1,
        );
        final stimmeBytes = utf8.encode(stimmeId);
        final updateOffset = 8 + 36 + 1 + stimmeBytes.length;
        expect(msg[updateOffset], equals(type.value),
            reason: 'updateType=${type.name}');
      }
    });
  });

  // ─── round-trip ─────────────────────────────────────────────────────────────

  group('BleMessageCodec round-trip', () {
    test('encode then decode produces original values for song changed', () {
      const seqNum = 7;
      const stueckId = 'piece-abc-123';
      const stueckTitel = 'Böhmische Polka';

      final unsigned = codec.encodeSongChanged(stueckId, stueckTitel, seqNum);
      final signed = _withDummyHmac(unsigned);
      final decoded = codec.decode(signed);

      expect(decoded.messageType, equals(0x01));
      expect(decoded.sequenceNumber, equals(seqNum));
      expect(decoded.signature.length, equals(32));

      // Decode the payload back to get stueckId/stueckTitel
      final (decodedId, decodedTitle) = codec.decodeSongChanged(decoded.payload);
      expect(decodedId, equals(stueckId));
      expect(decodedTitle, equals(stueckTitel));
    });

    test('encode then decode produces original values for metronome beat', () {
      const seqNum = 100;
      final beat = const MetronomeBeatPayload(
        bpm: 120,
        beatsPerMeasure: 4,
        beatUnit: 4,
        beatTimestampMs: 5000,
        beatNumberInMeasure: 2,
        nextBeatMs: 5500,
      );

      final unsigned = codec.encodeMetronomeBeat(beat, seqNum);
      final signed = _withDummyHmac(unsigned);
      final decoded = codec.decode(signed);

      expect(decoded.messageType, equals(0x02));
      expect(decoded.sequenceNumber, equals(seqNum));

      // Decode payload back to MetronomeBeatPayload
      final restored = MetronomeBeatPayload.fromBytes(decoded.payload);
      expect(restored.bpm, equals(120));
      expect(restored.beatsPerMeasure, equals(4));
      expect(restored.beatUnit, equals(4));
      expect(restored.beatTimestampMs, equals(5000));
      expect(restored.beatNumberInMeasure, equals(2));
      expect(restored.nextBeatMs, equals(5500));
    });

    test('encode then decode produces original values for annotation', () {
      const seqNum = 5;
      const guid = '550e8400-e29b-41d4-a716-446655440000';
      const stimmeId = 'trumpet';

      final ann = const AnnotationInvalidationPayload(
        stueckGuid: guid,
        stimmeId: stimmeId,
        updateType: AnnotationUpdateType.modified,
      );
      final unsigned = codec.encodeAnnotationInvalidation(ann, seqNum);
      final signed = _withDummyHmac(unsigned);
      final decoded = codec.decode(signed);

      expect(decoded.messageType, equals(0x03));
      expect(decoded.sequenceNumber, equals(seqNum));

      // Decode annotation payload
      final restored = codec.decodeAnnotationInvalidation(decoded.payload);
      expect(restored.stueckGuid.trim(), equals(guid));
      expect(restored.stimmeId, equals(stimmeId));
      expect(restored.updateType, equals(AnnotationUpdateType.modified));
    });
  });
}
