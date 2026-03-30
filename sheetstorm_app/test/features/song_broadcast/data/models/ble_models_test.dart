import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

// Spec reference: docs/specs/2026-03-30-ble-broadcast-dirigent.md §6.2
//
// BLE-specific models:
//  - BleSessionInfo     — session key + leader device ID + expiry + auth devices
//  - MetronomeBeatPayload — BPM range 20–300, nextBeatMs > beatTimestampMs
//  - AnnotationInvalidationPayload — stueckGuid (UUID), stimmeId, updateType

void main() {
  // ─── BleSessionInfo ─────────────────────────────────────────────────────────

  group('BleSessionInfo', () {
    test('fromJson parses all fields correctly', () {
      final expiresAt = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final json = {
        'sessionKey': 'dGVzdEtleQ==',
        'leaderDeviceId': 'device-abc-123',
        'expiresAt': expiresAt.toIso8601String(),
        'authenticatedDevices': ['device-abc-123', 'device-xyz-456'],
      };

      final info = BleSessionInfo.fromJson(json);

      expect(info.sessionKey, equals('dGVzdEtleQ=='));
      expect(info.leaderDeviceId, equals('device-abc-123'));
      expect(info.expiresAt.toIso8601String(), equals(expiresAt.toIso8601String()));
      expect(
        info.authenticatedDevices,
        containsAll(['device-abc-123', 'device-xyz-456']),
      );
    });

    test('toJson produces correct structure', () {
      final expiresAt = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final info = BleSessionInfo(
        sessionKey: 'dGVzdEtleQ==',
        leaderDeviceId: 'device-abc-123',
        expiresAt: expiresAt,
        authenticatedDevices: {'device-abc-123', 'device-xyz-456'},
      );

      final json = info.toJson();

      expect(json['sessionKey'], equals('dGVzdEtleQ=='));
      expect(json['leaderDeviceId'], equals('device-abc-123'));
      expect(json['expiresAt'], isA<String>());
      expect(
        json['authenticatedDevices'],
        containsAll(['device-abc-123', 'device-xyz-456']),
      );
    });

    test('fromJson/toJson round-trip preserves all values', () {
      final original = BleSessionInfo(
        sessionKey: 'c2Vzc2lvbktleQ==',
        leaderDeviceId: 'leader-42',
        expiresAt: DateTime.utc(2026, 6, 1),
        authenticatedDevices: {'leader-42', 'member-1', 'member-2'},
      );

      final restored = BleSessionInfo.fromJson(original.toJson());

      expect(restored.sessionKey, equals(original.sessionKey));
      expect(restored.leaderDeviceId, equals(original.leaderDeviceId));
      expect(
        restored.expiresAt.millisecondsSinceEpoch,
        equals(original.expiresAt.millisecondsSinceEpoch),
      );
      expect(
        restored.authenticatedDevices,
        equals(original.authenticatedDevices),
      );
    });

    test('isExpired returns true for past expiresAt', () {
      final expired = BleSessionInfo(
        sessionKey: 'key',
        leaderDeviceId: 'device',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        authenticatedDevices: const {},
      );

      expect(expired.isExpired, isTrue);
    });

    test('isExpired returns false for future expiresAt', () {
      final valid = BleSessionInfo(
        sessionKey: 'key',
        leaderDeviceId: 'device',
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
        authenticatedDevices: const {},
      );

      expect(valid.isExpired, isFalse);
    });
  });

  // ─── MetronomeBeatPayload ───────────────────────────────────────────────────

  group('MetronomeBeatPayload', () {
    MetronomeBeatPayload _valid({
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

    test('constructs with valid values without error', () {
      expect(() => _valid(), returnsNormally);
    });

    test('validates BPM lower bound — 19 is invalid, 20 is valid', () {
      expect(() => _valid(bpm: 19), throwsAssertionError);
      expect(() => _valid(bpm: 20), returnsNormally);
    });

    test('validates BPM upper bound — 301 is invalid, 300 is valid', () {
      expect(() => _valid(bpm: 301), throwsAssertionError);
      expect(() => _valid(bpm: 300), returnsNormally);
    });

    test('validates beat number within measure', () {
      // beatNumberInMeasure must be >= 1 and <= beatsPerMeasure
      expect(
        () => _valid(beatsPerMeasure: 4, beatNumberInMeasure: 0),
        throwsAssertionError,
      );
      expect(
        () => _valid(beatsPerMeasure: 4, beatNumberInMeasure: 5),
        throwsAssertionError,
      );
      expect(
        () => _valid(beatsPerMeasure: 4, beatNumberInMeasure: 4),
        returnsNormally,
      );
    });

    test('nextBeatMs is always > beatTimestampMs', () {
      // Equal timestamps are also invalid (next beat must be in the future)
      expect(
        () => _valid(beatTimestampMs: 1000, nextBeatMs: 1000),
        throwsAssertionError,
      );
      expect(
        () => _valid(beatTimestampMs: 1000, nextBeatMs: 999),
        throwsAssertionError,
      );
      expect(
        () => _valid(beatTimestampMs: 1000, nextBeatMs: 1001),
        returnsNormally,
      );
    });

    test('BPM boundary values 20 and 300 are both valid', () {
      expect(() => _valid(bpm: 20), returnsNormally);
      expect(() => _valid(bpm: 300), returnsNormally);
    });

    test('stores all fields correctly', () {
      final payload = _valid(
        bpm: 180,
        beatsPerMeasure: 3,
        beatUnit: 8,
        beatTimestampMs: 5000,
        beatNumberInMeasure: 2,
        nextBeatMs: 5417,
      );

      expect(payload.bpm, equals(180));
      expect(payload.beatsPerMeasure, equals(3));
      expect(payload.beatUnit, equals(8));
      expect(payload.beatTimestampMs, equals(5000));
      expect(payload.beatNumberInMeasure, equals(2));
      expect(payload.nextBeatMs, equals(5417));
    });
  });

  // ─── AnnotationInvalidationPayload ─────────────────────────────────────────

  group('AnnotationInvalidationPayload', () {
    const kValidGuid = '550e8400-e29b-41d4-a716-446655440000';

    test('constructs with valid values without error', () {
      expect(
        () => AnnotationInvalidationPayload(
          stueckGuid: kValidGuid,
          stimmeId: 'trumpet',
          updateType: AnnotationUpdateType.created,
        ),
        returnsNormally,
      );
    });

    test('all update types serialize correctly', () {
      for (final type in AnnotationUpdateType.values) {
        final payload = AnnotationInvalidationPayload(
          stueckGuid: kValidGuid,
          stimmeId: 'stimme',
          updateType: type,
        );
        final json = payload.toJson();
        final restored = AnnotationInvalidationPayload.fromJson(json);
        expect(restored.updateType, equals(type),
            reason: 'updateType=$type should survive round-trip');
      }
    });

    test('stueckGuid is accepted in valid UUID format', () {
      expect(
        () => AnnotationInvalidationPayload(
          stueckGuid: kValidGuid,
          stimmeId: 'stimme',
          updateType: AnnotationUpdateType.modified,
        ),
        returnsNormally,
      );
    });

    test('rejects stueckGuid that is not valid UUID format', () {
      expect(
        () => AnnotationInvalidationPayload(
          stueckGuid: 'not-a-uuid', // invalid UUID
          stimmeId: 'stimme',
          updateType: AnnotationUpdateType.deleted,
        ),
        throwsAssertionError,
      );
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final original = AnnotationInvalidationPayload(
        stueckGuid: kValidGuid,
        stimmeId: 'trompete-1',
        updateType: AnnotationUpdateType.modified,
      );

      final restored = AnnotationInvalidationPayload.fromJson(original.toJson());

      expect(restored.stueckGuid, equals(original.stueckGuid));
      expect(restored.stimmeId, equals(original.stimmeId));
      expect(restored.updateType, equals(original.updateType));
    });

    test('AnnotationUpdateType has created, modified, deleted values', () {
      expect(AnnotationUpdateType.values, containsAll([
        AnnotationUpdateType.created,
        AnnotationUpdateType.modified,
        AnnotationUpdateType.deleted,
      ]));
    });
  });
}
