// Tests for BLE-specific data models.
//
// Spec: docs/specs/2026-03-30-ble-broadcast-dirigent.md §6.2
//
// Models under test:
//   - BleSessionInfo       — session key + leader device ID + expiry
//   - MetronomeBeatPayload — BPM, time signature, beat timing; binary serialization
//   - AnnotationInvalidationPayload — stueckGuid, stimmeId, updateType
//   - AnnotationUpdateType — created / modified / deleted

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

void main() {
  // ─── BleSessionInfo ─────────────────────────────────────────────────────────

  group('BleSessionInfo', () {
    test('fromJson parses all fields correctly', () {
      final expiresAt = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final json = <String, dynamic>{
        'sessionKey': 'dGVzdEtleQ==',
        'leaderDeviceId': 'device-abc-123',
        'expiresAt': expiresAt.toIso8601String(),
      };

      final info = BleSessionInfo.fromJson(json);

      expect(info.sessionKey, equals('dGVzdEtleQ=='));
      expect(info.leaderDeviceId, equals('device-abc-123'));
      expect(
        info.expiresAt.millisecondsSinceEpoch,
        equals(expiresAt.millisecondsSinceEpoch),
      );
    });

    test('toJson produces correct structure', () {
      final expiresAt = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final info = BleSessionInfo(
        sessionKey: 'dGVzdEtleQ==',
        leaderDeviceId: 'device-abc-123',
        expiresAt: expiresAt,
      );

      final json = info.toJson();

      expect(json['sessionKey'], equals('dGVzdEtleQ=='));
      expect(json['leaderDeviceId'], equals('device-abc-123'));
      expect(json['expiresAt'], isA<String>());
      // expiresAt is stored as ISO-8601 string
      expect(
        DateTime.parse(json['expiresAt'] as String).millisecondsSinceEpoch,
        equals(expiresAt.millisecondsSinceEpoch),
      );
    });

    test('fromJson/toJson round-trip preserves all values', () {
      final original = BleSessionInfo(
        sessionKey: 'c2Vzc2lvbktleQ==',
        leaderDeviceId: 'leader-42',
        expiresAt: DateTime.utc(2026, 6, 1),
      );

      final restored = BleSessionInfo.fromJson(original.toJson());

      expect(restored.sessionKey, equals(original.sessionKey));
      expect(restored.leaderDeviceId, equals(original.leaderDeviceId));
      expect(
        restored.expiresAt.millisecondsSinceEpoch,
        equals(original.expiresAt.millisecondsSinceEpoch),
      );
    });

    test('isExpired returns true when expiresAt is in the past', () {
      final expired = BleSessionInfo(
        sessionKey: 'key',
        leaderDeviceId: 'device',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(expired.isExpired, isTrue);
    });

    test('isExpired returns false when expiresAt is in the future', () {
      final valid = BleSessionInfo(
        sessionKey: 'key',
        leaderDeviceId: 'device',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
      );
      expect(valid.isExpired, isFalse);
    });
  });

  // ─── MetronomeBeatPayload ───────────────────────────────────────────────────

  group('MetronomeBeatPayload', () {
    // Spec §3.2 binary layout (via toBytes / fromBytes):
    //   [0..1] BPM uint16 big-endian
    //   [2]    beatsPerMeasure uint8
    //   [3]    beatUnit uint8
    //   [4..7] beatTimestampMs uint32 big-endian
    //   [8]    beatNumberInMeasure uint8
    //   [9..12] nextBeatMs uint32 big-endian
    //   Total: 13 bytes

    MetronomeBeatPayload makePayload({
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

    test('stores all fields correctly', () {
      final p = makePayload(
        bpm: 160,
        beatsPerMeasure: 3,
        beatUnit: 8,
        beatTimestampMs: 5000,
        beatNumberInMeasure: 2,
        nextBeatMs: 5375,
      );
      expect(p.bpm, equals(160));
      expect(p.beatsPerMeasure, equals(3));
      expect(p.beatUnit, equals(8));
      expect(p.beatTimestampMs, equals(5000));
      expect(p.beatNumberInMeasure, equals(2));
      expect(p.nextBeatMs, equals(5375));
    });

    test('toBytes produces exactly 13 bytes', () {
      expect(makePayload().toBytes().length, equals(13));
    });

    test('toBytes encodes BPM as uint16 big-endian at offset 0', () {
      final bytes = makePayload(bpm: 180).toBytes();
      final bd = ByteData.sublistView(bytes);
      expect(bd.getUint16(0, Endian.big), equals(180));
    });

    test('toBytes encodes beatsPerMeasure and beatUnit at offsets 2–3', () {
      final bytes = makePayload(beatsPerMeasure: 3, beatUnit: 8).toBytes();
      expect(bytes[2], equals(3), reason: 'beatsPerMeasure at offset 2');
      expect(bytes[3], equals(8), reason: 'beatUnit at offset 3');
    });

    test('toBytes encodes beatTimestampMs as uint32 big-endian at offset 4', () {
      final bytes = makePayload(beatTimestampMs: 0xDEAD).toBytes();
      final bd = ByteData.sublistView(bytes);
      expect(bd.getUint32(4, Endian.big), equals(0xDEAD));
    });

    test('toBytes encodes nextBeatMs as uint32 big-endian at offset 9', () {
      final bytes = makePayload(nextBeatMs: 99999).toBytes();
      final bd = ByteData.sublistView(bytes);
      expect(bd.getUint32(9, Endian.big), equals(99999));
    });

    test('fromBytes round-trip preserves all values', () {
      final original = makePayload(
        bpm: 200,
        beatsPerMeasure: 6,
        beatUnit: 8,
        beatTimestampMs: 30000,
        beatNumberInMeasure: 3,
        nextBeatMs: 30300,
      );
      final restored = MetronomeBeatPayload.fromBytes(original.toBytes());

      expect(restored.bpm, equals(original.bpm));
      expect(restored.beatsPerMeasure, equals(original.beatsPerMeasure));
      expect(restored.beatUnit, equals(original.beatUnit));
      expect(restored.beatTimestampMs, equals(original.beatTimestampMs));
      expect(restored.beatNumberInMeasure, equals(original.beatNumberInMeasure));
      expect(restored.nextBeatMs, equals(original.nextBeatMs));
    });

    test('fromJson round-trip preserves all values', () {
      final original = makePayload(bpm: 90, beatsPerMeasure: 2, beatUnit: 2);
      final json = <String, dynamic>{
        'bpm': original.bpm,
        'beatsPerMeasure': original.beatsPerMeasure,
        'beatUnit': original.beatUnit,
        'beatTimestampMs': original.beatTimestampMs,
        'beatNumberInMeasure': original.beatNumberInMeasure,
        'nextBeatMs': original.nextBeatMs,
      };
      final restored = MetronomeBeatPayload.fromJson(json);

      expect(restored.bpm, equals(original.bpm));
      expect(restored.beatsPerMeasure, equals(original.beatsPerMeasure));
      expect(restored.beatUnit, equals(original.beatUnit));
    });
  });

  // ─── AnnotationInvalidationPayload ─────────────────────────────────────────

  group('AnnotationInvalidationPayload', () {
    const kValidGuid = '550e8400-e29b-41d4-a716-446655440000';

    test('constructs with valid values', () {
      expect(
        () => const AnnotationInvalidationPayload(
          stueckGuid: kValidGuid,
          stimmeId: 'trumpet',
          updateType: AnnotationUpdateType.created,
        ),
        returnsNormally,
      );
    });

    test('stores all fields correctly', () {
      final p = const AnnotationInvalidationPayload(
        stueckGuid: kValidGuid,
        stimmeId: 'trompete-1',
        updateType: AnnotationUpdateType.modified,
      );
      expect(p.stueckGuid, equals(kValidGuid));
      expect(p.stimmeId, equals('trompete-1'));
      expect(p.updateType, equals(AnnotationUpdateType.modified));
    });

    test('AnnotationUpdateType has created, modified, deleted values', () {
      expect(AnnotationUpdateType.values, containsAll([
        AnnotationUpdateType.created,
        AnnotationUpdateType.modified,
        AnnotationUpdateType.deleted,
      ]));
    });

    test('AnnotationUpdateType raw values: created=0, modified=1, deleted=2', () {
      expect(AnnotationUpdateType.created.value, equals(0));
      expect(AnnotationUpdateType.modified.value, equals(1));
      expect(AnnotationUpdateType.deleted.value, equals(2));
    });

    test('AnnotationUpdateType.fromValue round-trips all values', () {
      for (final type in AnnotationUpdateType.values) {
        expect(
          AnnotationUpdateType.fromValue(type.value),
          equals(type),
          reason: '${type.name} (value=${type.value}) should round-trip',
        );
      }
    });

    test('AnnotationUpdateType.fromValue defaults to modified for unknown value',
        () {
      expect(
        AnnotationUpdateType.fromValue(99),
        equals(AnnotationUpdateType.modified),
      );
    });
  });
}
