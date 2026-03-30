import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';

void main() {
  // ─── SyncStatus ──────────────────────────────────────────────────────────────

  group('SyncStatus — enum values', () {
    test('contains idle', () => expect(SyncStatus.values, contains(SyncStatus.idle)));
    test('contains syncing', () => expect(SyncStatus.values, contains(SyncStatus.syncing)));
    test('contains synced', () => expect(SyncStatus.values, contains(SyncStatus.synced)));
    test('contains conflict', () => expect(SyncStatus.values, contains(SyncStatus.conflict)));
    test('contains offline', () => expect(SyncStatus.values, contains(SyncStatus.offline)));
    test('contains error', () => expect(SyncStatus.values, contains(SyncStatus.error)));
  });

  // ─── SyncVersion ─────────────────────────────────────────────────────────────

  group('SyncVersion — fromJson/toJson round-trip', () {
    final json = {
      'deviceId': 'device-abc',
      'timestamp': '2025-06-01T10:00:00.000Z',
      'vectorClock': {'device-abc': 5, 'device-xyz': 3},
    };

    test('fromJson parses deviceId', () {
      final v = SyncVersion.fromJson(json);
      expect(v.deviceId, 'device-abc');
    });

    test('fromJson parses timestamp', () {
      final v = SyncVersion.fromJson(json);
      expect(v.timestamp, DateTime.parse('2025-06-01T10:00:00.000Z'));
    });

    test('fromJson parses vectorClock', () {
      final v = SyncVersion.fromJson(json);
      expect(v.vectorClock['device-abc'], 5);
      expect(v.vectorClock['device-xyz'], 3);
    });

    test('toJson produces correct keys', () {
      final v = SyncVersion.fromJson(json);
      final out = v.toJson();
      expect(out['deviceId'], 'device-abc');
      expect(out['vectorClock'], isA<Map>());
    });

    test('empty vectorClock is allowed', () {
      final v = SyncVersion.fromJson({
        'deviceId': 'dev1',
        'timestamp': '2025-01-01T00:00:00.000Z',
      });
      expect(v.vectorClock, isEmpty);
    });
  });

  // ─── SyncDelta ────────────────────────────────────────────────────────────────

  group('SyncDelta — fromJson/toJson round-trip', () {
    final versionJson = {
      'deviceId': 'dev1',
      'timestamp': '2025-06-01T10:00:00.000Z',
      'vectorClock': <String, dynamic>{},
    };

    final deltaJson = {
      'entityType': 'sheet_music',
      'entityId': 'sm-001',
      'operation': 'update',
      'version': versionJson,
      'payload': {'title': 'Ode an die Freude'},
    };

    test('fromJson parses entityType', () {
      final d = SyncDelta.fromJson(deltaJson);
      expect(d.entityType, 'sheet_music');
    });

    test('fromJson parses entityId', () {
      final d = SyncDelta.fromJson(deltaJson);
      expect(d.entityId, 'sm-001');
    });

    test('fromJson parses operation', () {
      final d = SyncDelta.fromJson(deltaJson);
      expect(d.operation, 'update');
    });

    test('fromJson parses version', () {
      final d = SyncDelta.fromJson(deltaJson);
      expect(d.version.deviceId, 'dev1');
    });

    test('fromJson parses payload', () {
      final d = SyncDelta.fromJson(deltaJson);
      expect(d.payload['title'], 'Ode an die Freude');
    });

    test('toJson round-trip preserves entityId', () {
      final d = SyncDelta.fromJson(deltaJson);
      final out = d.toJson();
      expect(out['entityId'], 'sm-001');
    });

    test('toJson round-trip preserves operation', () {
      final d = SyncDelta.fromJson(deltaJson);
      final out = d.toJson();
      expect(out['operation'], 'update');
    });

    test('missing payload defaults to empty map', () {
      final json = {
        'entityType': 'annotation',
        'entityId': 'ann-1',
        'operation': 'delete',
        'version': versionJson,
      };
      final d = SyncDelta.fromJson(json);
      expect(d.payload, isEmpty);
    });
  });

  // ─── SyncConflict ─────────────────────────────────────────────────────────────

  group('SyncConflict — fromJson/toJson', () {
    final vJson = {
      'deviceId': 'dev1',
      'timestamp': '2025-06-01T10:00:00.000Z',
      'vectorClock': <String, dynamic>{},
    };
    final deltaJson = {
      'entityType': 'sheet_music',
      'entityId': 'sm-001',
      'operation': 'update',
      'version': vJson,
      'payload': <String, dynamic>{},
    };

    final conflictJson = {
      'entityType': 'sheet_music',
      'entityId': 'sm-001',
      'localDelta': deltaJson,
      'serverDelta': deltaJson,
      'resolvedWith': 'server',
    };

    test('fromJson parses entityType', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.entityType, 'sheet_music');
    });

    test('fromJson parses resolvedWith', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.resolvedWith, 'server');
    });

    test('fromJson defaults resolvedWith to server', () {
      final json = Map<String, dynamic>.from(conflictJson)..remove('resolvedWith');
      final c = SyncConflict.fromJson(json);
      expect(c.resolvedWith, 'server');
    });

    test('toJson round-trip preserves entityId', () {
      final c = SyncConflict.fromJson(conflictJson);
      final out = c.toJson();
      expect(out['entityId'], 'sm-001');
    });
  });

  // ─── SyncState ────────────────────────────────────────────────────────────────

  group('SyncState — defaults and copyWith', () {
    test('default status is idle', () {
      const s = SyncState();
      expect(s.status, SyncStatus.idle);
    });

    test('default pendingChanges is 0', () {
      const s = SyncState();
      expect(s.pendingChanges, 0);
    });

    test('default conflicts is empty', () {
      const s = SyncState();
      expect(s.conflicts, isEmpty);
    });

    test('default lastSyncAt is null', () {
      const s = SyncState();
      expect(s.lastSyncAt, isNull);
    });

    test('hasConflicts is false when conflicts empty', () {
      const s = SyncState();
      expect(s.hasConflicts, isFalse);
    });

    test('isOffline is true when status is offline', () {
      const s = SyncState(status: SyncStatus.offline);
      expect(s.isOffline, isTrue);
    });

    test('isSyncing is true when status is syncing', () {
      const s = SyncState(status: SyncStatus.syncing);
      expect(s.isSyncing, isTrue);
    });

    test('copyWith updates status', () {
      const s = SyncState();
      final updated = s.copyWith(status: SyncStatus.synced);
      expect(updated.status, SyncStatus.synced);
    });

    test('copyWith updates pendingChanges', () {
      const s = SyncState();
      final updated = s.copyWith(pendingChanges: 3);
      expect(updated.pendingChanges, 3);
    });

    test('copyWith preserves unchanged fields', () {
      const s = SyncState(pendingChanges: 2);
      final updated = s.copyWith(status: SyncStatus.syncing);
      expect(updated.pendingChanges, 2);
    });

    test('copyWith updates lastSyncAt', () {
      const s = SyncState();
      final now = DateTime(2025, 6, 1);
      final updated = s.copyWith(lastSyncAt: now);
      expect(updated.lastSyncAt, now);
    });

    test('equatable: two identical states are equal', () {
      const a = SyncState(status: SyncStatus.idle, pendingChanges: 0);
      const b = SyncState(status: SyncStatus.idle, pendingChanges: 0);
      expect(a, equals(b));
    });
  });

  // ─── SyncStateResponse ────────────────────────────────────────────────────────

  group('SyncStateResponse — fromJson', () {
    test('parses pendingChanges', () {
      final r = SyncStateResponse.fromJson({
        'lastSyncAt': null,
        'pendingChanges': 4,
        'conflicts': <dynamic>[],
      });
      expect(r.pendingChanges, 4);
    });

    test('parses lastSyncAt', () {
      final r = SyncStateResponse.fromJson({
        'lastSyncAt': '2025-05-30T08:00:00.000Z',
        'pendingChanges': 0,
        'conflicts': <dynamic>[],
      });
      expect(r.lastSyncAt, isNotNull);
    });

    test('null lastSyncAt stays null', () {
      final r = SyncStateResponse.fromJson({
        'pendingChanges': 0,
        'conflicts': <dynamic>[],
      });
      expect(r.lastSyncAt, isNull);
    });
  });
}
