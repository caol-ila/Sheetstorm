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

  // ─── SyncChangeEntry ────────────────────────────────────────────────────────

  group('SyncChangeEntry — fromJson', () {
    final json = {
      'version': 42,
      'entityType': 'sheet_music',
      'entityId': 'sm-001',
      'operation': 'update',
      'fieldName': 'title',
      'newValue': 'Ode an die Freude',
      'changedAt': '2025-06-01T10:00:00.000Z',
    };

    test('parses version', () {
      final e = SyncChangeEntry.fromJson(json);
      expect(e.version, 42);
    });

    test('parses entityType', () {
      final e = SyncChangeEntry.fromJson(json);
      expect(e.entityType, 'sheet_music');
    });

    test('parses operation', () {
      final e = SyncChangeEntry.fromJson(json);
      expect(e.operation, 'update');
    });

    test('parses fieldName and newValue', () {
      final e = SyncChangeEntry.fromJson(json);
      expect(e.fieldName, 'title');
      expect(e.newValue, 'Ode an die Freude');
    });

    test('null fieldName is allowed', () {
      final j = Map<String, dynamic>.from(json)
        ..remove('fieldName')
        ..remove('newValue');
      final e = SyncChangeEntry.fromJson(j);
      expect(e.fieldName, isNull);
      expect(e.newValue, isNull);
    });

    test('parses fields map', () {
      final j = Map<String, dynamic>.from(json)
        ..['fields'] = {'title': 'New', 'key': 'new_key'};
      final e = SyncChangeEntry.fromJson(j);
      expect(e.fields?['title'], 'New');
    });
  });

  // ─── SyncDelta (push format) ───────────────────────────────────────────────

  group('SyncDelta — toJson', () {
    test('serializes all fields', () {
      final d = SyncDelta(
        clientChangeId: 'cc-1',
        entityType: 'sheet_music',
        entityId: 'sm-001',
        operation: 'update',
        fieldName: 'title',
        newValue: 'Neuer Titel',
        changedAt: DateTime.utc(2025, 6, 1, 10),
      );
      final out = d.toJson();
      expect(out['clientChangeId'], 'cc-1');
      expect(out['entityType'], 'sheet_music');
      expect(out['entityId'], 'sm-001');
      expect(out['operation'], 'update');
      expect(out['fieldName'], 'title');
      expect(out['newValue'], 'Neuer Titel');
    });

    test('omits null optional fields', () {
      final d = SyncDelta(
        clientChangeId: 'cc-2',
        entityType: 'annotation',
        operation: 'create',
        changedAt: DateTime.utc(2025, 6, 1),
      );
      final out = d.toJson();
      expect(out.containsKey('entityId'), isFalse);
      expect(out.containsKey('fieldName'), isFalse);
      expect(out.containsKey('newValue'), isFalse);
    });
  });

  // ─── SyncConflict ─────────────────────────────────────────────────────────────

  group('SyncConflict — fromJson', () {
    final conflictJson = {
      'clientChangeId': 'cc-1',
      'entityType': 'sheet_music',
      'entityId': 'sm-001',
      'fieldName': 'title',
      'clientValue': 'Mein Titel',
      'serverValue': 'Server Titel',
      'serverChangedAt': '2025-06-01T10:00:00.000Z',
      'resolution': 'server',
    };

    test('parses entityType', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.entityType, 'sheet_music');
    });

    test('parses resolution', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.resolution, 'server');
    });

    test('parses clientValue and serverValue', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.clientValue, 'Mein Titel');
      expect(c.serverValue, 'Server Titel');
    });

    test('parses clientChangeId', () {
      final c = SyncConflict.fromJson(conflictJson);
      expect(c.clientChangeId, 'cc-1');
    });
  });

  // ─── PullResponse ─────────────────────────────────────────────────────────────

  group('PullResponse — fromJson', () {
    test('parses changes and version', () {
      final json = {
        'changes': [
          {
            'version': 1,
            'entityType': 'sheet_music',
            'entityId': 'sm-001',
            'operation': 'create',
            'changedAt': '2025-06-01T10:00:00.000Z',
          },
        ],
        'currentVersion': 5,
        'hasMore': false,
      };
      final r = PullResponse.fromJson(json);
      expect(r.changes.length, 1);
      expect(r.currentVersion, 5);
      expect(r.hasMore, isFalse);
    });
  });

  // ─── PushResponse ─────────────────────────────────────────────────────────────

  group('PushResponse — fromJson', () {
    test('parses accepted and conflicts', () {
      final json = {
        'accepted': [
          {
            'clientChangeId': 'cc-1',
            'serverVersion': 6,
            'serverEntityId': 'sm-001',
          },
        ],
        'conflicts': <dynamic>[],
        'newVersion': 7,
      };
      final r = PushResponse.fromJson(json);
      expect(r.accepted.length, 1);
      expect(r.accepted.first.clientChangeId, 'cc-1');
      expect(r.conflicts, isEmpty);
      expect(r.newVersion, 7);
    });
  });

  // ─── SyncState ────────────────────────────────────────────────────────────────

  group('SyncState — defaults and copyWith', () {
    test('default status is idle', () {
      const s = SyncState();
      expect(s.status, SyncStatus.idle);
    });

    test('default currentVersion is 0', () {
      const s = SyncState();
      expect(s.currentVersion, 0);
    });

    test('default pendingServerChanges is 0', () {
      const s = SyncState();
      expect(s.pendingServerChanges, 0);
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

    test('copyWith updates pendingServerChanges', () {
      const s = SyncState();
      final updated = s.copyWith(pendingServerChanges: 3);
      expect(updated.pendingServerChanges, 3);
    });

    test('copyWith preserves unchanged fields', () {
      const s = SyncState(pendingServerChanges: 2);
      final updated = s.copyWith(status: SyncStatus.syncing);
      expect(updated.pendingServerChanges, 2);
    });

    test('copyWith updates lastSyncAt', () {
      const s = SyncState();
      final now = DateTime(2025, 6, 1);
      final updated = s.copyWith(lastSyncAt: now);
      expect(updated.lastSyncAt, now);
    });

    test('copyWith clearError resets errorMessage', () {
      const s = SyncState(errorMessage: 'old error');
      final updated = s.copyWith(clearError: true);
      expect(updated.errorMessage, isNull);
    });

    test('equatable: two identical states are equal', () {
      const a = SyncState(status: SyncStatus.idle, pendingServerChanges: 0);
      const b = SyncState(status: SyncStatus.idle, pendingServerChanges: 0);
      expect(a, equals(b));
    });
  });

  // ─── SyncStateResponse ────────────────────────────────────────────────────────

  group('SyncStateResponse — fromJson', () {
    test('parses currentVersion and pendingServerChanges', () {
      final r = SyncStateResponse.fromJson({
        'currentVersion': 42,
        'lastSyncAt': null,
        'pendingServerChanges': 4,
      });
      expect(r.currentVersion, 42);
      expect(r.pendingServerChanges, 4);
    });

    test('parses lastSyncAt', () {
      final r = SyncStateResponse.fromJson({
        'currentVersion': 1,
        'lastSyncAt': '2025-05-30T08:00:00.000Z',
        'pendingServerChanges': 0,
      });
      expect(r.lastSyncAt, isNotNull);
    });

    test('null lastSyncAt stays null', () {
      final r = SyncStateResponse.fromJson({
        'currentVersion': 0,
        'pendingServerChanges': 0,
      });
      expect(r.lastSyncAt, isNull);
    });
  });
}
