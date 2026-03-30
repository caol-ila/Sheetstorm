import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/cloud_sync/application/sync_notifier.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/data/services/sync_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockSyncService extends Mock implements SyncService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

SyncVersion _version() => SyncVersion(
      deviceId: 'dev1',
      timestamp: DateTime(2025, 6, 1),
    );

SyncDelta _delta({String entityId = 'sm-001'}) => SyncDelta(
      entityType: 'sheet_music',
      entityId: entityId,
      operation: 'update',
      version: _version(),
    );

SyncConflict _conflict({String entityId = 'sm-001'}) => SyncConflict(
      entityType: 'sheet_music',
      entityId: entityId,
      localDelta: _delta(entityId: entityId),
      serverDelta: _delta(entityId: entityId),
      resolvedWith: 'server',
    );

(ProviderContainer, SyncNotifier, MockSyncService) _setup() {
  final service = MockSyncService();
  final container = ProviderContainer(
    overrides: [
      syncServiceProvider.overrideWithValue(service),
    ],
  );
  addTearDown(container.dispose);

  final notifier = container.read(syncProvider.notifier);
  return (container, notifier, service);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(DateTime(2025));
  });

  // ─── Initial State ────────────────────────────────────────────────────────

  group('SyncNotifier — Initialzustand', () {
    test('Startzustand ist idle', () {
      final (c, _, __) = _setup();
      expect(c.read(syncProvider).status, SyncStatus.idle);
    });

    test('Startzustand hat keine Konflikte', () {
      final (c, _, __) = _setup();
      expect(c.read(syncProvider).conflicts, isEmpty);
    });

    test('Startzustand hat 0 pendingChanges', () {
      final (c, _, __) = _setup();
      expect(c.read(syncProvider).pendingChanges, 0);
    });
  });

  // ─── Offline / Online ─────────────────────────────────────────────────────

  group('SyncNotifier — Offline/Online', () {
    test('setOffline() setzt Status auf offline', () {
      final (c, n, _) = _setup();
      n.setOffline();
      expect(c.read(syncProvider).status, SyncStatus.offline);
    });

    test('setOnline() von offline setzt Status auf idle', () {
      final (c, n, _) = _setup();
      n.setOffline();
      n.setOnline();
      expect(c.read(syncProvider).status, SyncStatus.idle);
    });

    test('setOnline() bei nicht-offline ändert Status nicht', () {
      final (c, n, _) = _setup();
      // Status is idle initially — setOnline should be a no-op
      n.setOnline();
      expect(c.read(syncProvider).status, SyncStatus.idle);
    });

    test('isOffline gibt true zurück bei offline', () {
      final (c, n, _) = _setup();
      n.setOffline();
      expect(c.read(syncProvider).isOffline, isTrue);
    });
  });

  // ─── Sync flow ────────────────────────────────────────────────────────────

  group('SyncNotifier — sync() Erfolg', () {
    test('sync() wechselt zu synced nach Erfolg', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          const SyncStateResponse(pendingChanges: 0, conflicts: []));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();

      expect(c.read(syncProvider).status, SyncStatus.synced);
    });

    test('sync() setzt lastSyncAt nach Erfolg', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          const SyncStateResponse(pendingChanges: 0, conflicts: []));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();

      expect(c.read(syncProvider).lastSyncAt, isNotNull);
    });

    test('sync() setzt pendingChanges aus Server-Antwort', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          const SyncStateResponse(pendingChanges: 2, conflicts: []));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();

      expect(c.read(syncProvider).pendingChanges, 2);
    });

    test('sync() bei Konflikten setzt Status auf conflict', () async {
      final (c, n, service) = _setup();
      final conflict = _conflict();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          SyncStateResponse(pendingChanges: 0, conflicts: [conflict]));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();

      expect(c.read(syncProvider).status, SyncStatus.conflict);
      expect(c.read(syncProvider).conflicts, hasLength(1));
    });
  });

  group('SyncNotifier — sync() Fehler', () {
    test('sync() setzt Status auf error bei Exception', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenThrow(Exception('Netzwerkfehler'));

      await n.sync();

      expect(c.read(syncProvider).status, SyncStatus.error);
    });

    test('sync() speichert Fehlermeldung', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState())
          .thenThrow(Exception('Verbindung unterbrochen'));

      await n.sync();

      expect(c.read(syncProvider).errorMessage, isNotNull);
    });

    test('sync() während laufendem Sync wird ignoriert', () async {
      final (c, n, service) = _setup();

      // Only verify no double-sync: set to syncing then call sync again
      // by directly calling sync on already-syncing state
      when(() => service.getSyncState()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const SyncStateResponse(pendingChanges: 0, conflicts: []);
      });
      when(() => service.pull(any())).thenAnswer((_) async => []);

      // Start first sync (don't await)
      final first = n.sync();
      // Start second sync — should be ignored since status is now syncing
      await n.sync();
      await first;

      // getSyncState should only be called once
      verify(() => service.getSyncState()).called(1);
    });
  });

  // ─── push() ──────────────────────────────────────────────────────────────

  group('SyncNotifier — push()', () {
    test('push() gibt true bei Erfolg zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.push(any())).thenAnswer((_) async {});

      final result = await n.push([_delta()]);

      expect(result, isTrue);
    });

    test('push() gibt false bei Fehler zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.push(any())).thenThrow(Exception('Push fehlgeschlagen'));

      final result = await n.push([_delta()]);

      expect(result, isFalse);
    });

    test('push() setzt Status auf error bei Fehler', () async {
      final (c, n, service) = _setup();

      when(() => service.push(any())).thenThrow(Exception('Fehler'));

      await n.push([_delta()]);

      expect(c.read(syncProvider).status, SyncStatus.error);
    });
  });

  // ─── pull() ──────────────────────────────────────────────────────────────

  group('SyncNotifier — pull()', () {
    test('pull() gibt true bei Erfolg zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.pull(any())).thenAnswer((_) async => []);

      final result = await n.pull();

      expect(result, isTrue);
    });

    test('pull() setzt lastSyncAt nach Erfolg', () async {
      final (c, n, service) = _setup();

      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.pull();

      expect(c.read(syncProvider).lastSyncAt, isNotNull);
    });

    test('pull() gibt false bei Fehler zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.pull(any())).thenThrow(Exception('Pull fehlgeschlagen'));

      final result = await n.pull();

      expect(result, isFalse);
    });
  });

  // ─── resolveConflict() ───────────────────────────────────────────────────

  group('SyncNotifier — resolveConflict()', () {
    test('entfernt Konflikt aus Liste', () async {
      final (c, n, service) = _setup();
      final conflict = _conflict(entityId: 'sm-001');

      when(() => service.getSyncState()).thenAnswer((_) async =>
          SyncStateResponse(pendingChanges: 0, conflicts: [conflict]));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();
      expect(c.read(syncProvider).conflicts, hasLength(1));

      n.resolveConflict('sm-001');

      expect(c.read(syncProvider).conflicts, isEmpty);
    });

    test('setzt Status auf synced wenn keine Konflikte mehr', () async {
      final (c, n, service) = _setup();
      final conflict = _conflict(entityId: 'sm-001');

      when(() => service.getSyncState()).thenAnswer((_) async =>
          SyncStateResponse(pendingChanges: 0, conflicts: [conflict]));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();
      n.resolveConflict('sm-001');

      expect(c.read(syncProvider).status, SyncStatus.synced);
    });

    test('behält anderen Konflikt wenn mehrere vorhanden', () async {
      final (c, n, service) = _setup();
      final c1 = _conflict(entityId: 'sm-001');
      final c2 = _conflict(entityId: 'sm-002');

      when(() => service.getSyncState()).thenAnswer((_) async =>
          SyncStateResponse(pendingChanges: 0, conflicts: [c1, c2]));
      when(() => service.pull(any())).thenAnswer((_) async => []);

      await n.sync();
      n.resolveConflict('sm-001');

      expect(c.read(syncProvider).conflicts, hasLength(1));
      expect(c.read(syncProvider).conflicts.first.entityId, 'sm-002');
    });
  });

  // ─── addPendingChange() ──────────────────────────────────────────────────

  group('SyncNotifier — addPendingChange()', () {
    test('erhöht pendingChanges um 1', () {
      final (c, n, _) = _setup();
      n.addPendingChange();
      expect(c.read(syncProvider).pendingChanges, 1);
    });

    test('mehrfaches Aufrufen akkumuliert', () {
      final (c, n, _) = _setup();
      n.addPendingChange();
      n.addPendingChange();
      n.addPendingChange();
      expect(c.read(syncProvider).pendingChanges, 3);
    });
  });
}
