import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/cloud_sync/application/sync_notifier.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';
import 'package:sheetstorm/features/cloud_sync/data/services/sync_service.dart';

// ─── Mocks ────────────────────────────────────────────────────────────────────

class MockSyncService extends Mock implements SyncService {}

// ─── Helpers ──────────────────────────────────────────────────────────────────

SyncDelta _delta({String clientChangeId = 'cc-1', String entityId = 'sm-001'}) =>
    SyncDelta(
      clientChangeId: clientChangeId,
      entityType: 'sheet_music',
      entityId: entityId,
      operation: 'update',
      changedAt: DateTime(2025, 6, 1),
    );

SyncConflict _conflict({String entityId = 'sm-001'}) => SyncConflict(
      clientChangeId: 'cc-1',
      entityType: 'sheet_music',
      entityId: entityId,
      serverChangedAt: DateTime(2025, 6, 1),
      resolution: 'server',
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
    registerFallbackValue(0);
    registerFallbackValue(<SyncDelta>[]);
  });

  // ─── Initial State ────────────────────────────────────────────────────────

  group('SyncNotifier — Initialzustand', () {
    test('Startzustand ist idle', () {
      final (c, _, _) = _setup();
      expect(c.read(syncProvider).status, SyncStatus.idle);
    });

    test('Startzustand hat keine Konflikte', () {
      final (c, _, _) = _setup();
      expect(c.read(syncProvider).conflicts, isEmpty);
    });

    test('Startzustand hat currentVersion 0', () {
      final (c, _, _) = _setup();
      expect(c.read(syncProvider).currentVersion, 0);
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
          const SyncStateResponse(currentVersion: 5, pendingServerChanges: 0));
      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 5, hasMore: false));

      await n.sync();

      expect(c.read(syncProvider).status, SyncStatus.synced);
    });

    test('sync() setzt lastSyncAt nach Erfolg', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          const SyncStateResponse(currentVersion: 1, pendingServerChanges: 0));
      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 1, hasMore: false));

      await n.sync();

      expect(c.read(syncProvider).lastSyncAt, isNotNull);
    });

    test('sync() setzt currentVersion aus Pull-Antwort', () async {
      final (c, n, service) = _setup();

      when(() => service.getSyncState()).thenAnswer((_) async =>
          const SyncStateResponse(currentVersion: 10, pendingServerChanges: 2));
      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 10, hasMore: false));

      await n.sync();

      expect(c.read(syncProvider).currentVersion, 10);
      expect(c.read(syncProvider).pendingServerChanges, 2);
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

      when(() => service.getSyncState()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const SyncStateResponse(
            currentVersion: 1, pendingServerChanges: 0);
      });
      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 1, hasMore: false));

      final first = n.sync();
      await n.sync();
      await first;

      verify(() => service.getSyncState()).called(1);
    });
  });

  // ─── push() ──────────────────────────────────────────────────────────────

  group('SyncNotifier — push()', () {
    test('push() gibt PushResponse bei Erfolg zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.push(any(), any())).thenAnswer((_) async =>
          const PushResponse(accepted: [], conflicts: [], newVersion: 2));

      final result = await n.push([_delta()]);

      expect(result, isNotNull);
      expect(result!.newVersion, 2);
    });

    test('push() gibt null bei Fehler zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.push(any(), any()))
          .thenThrow(Exception('Push fehlgeschlagen'));

      final result = await n.push([_delta()]);

      expect(result, isNull);
    });

    test('push() setzt Status auf error bei Fehler', () async {
      final (c, n, service) = _setup();

      when(() => service.push(any(), any())).thenThrow(Exception('Fehler'));

      await n.push([_delta()]);

      expect(c.read(syncProvider).status, SyncStatus.error);
    });

    test('push() mit Konflikten setzt Status auf conflict', () async {
      final (c, n, service) = _setup();
      final conflict = _conflict();

      when(() => service.push(any(), any())).thenAnswer((_) async =>
          PushResponse(accepted: const [], conflicts: [conflict], newVersion: 3));

      await n.push([_delta()]);

      expect(c.read(syncProvider).status, SyncStatus.conflict);
      expect(c.read(syncProvider).conflicts, hasLength(1));
    });
  });

  // ─── pull() ──────────────────────────────────────────────────────────────

  group('SyncNotifier — pull()', () {
    test('pull() gibt true bei Erfolg zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 1, hasMore: false));

      final result = await n.pull();

      expect(result, isTrue);
    });

    test('pull() setzt lastSyncAt nach Erfolg', () async {
      final (c, n, service) = _setup();

      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 5, hasMore: false));

      await n.pull();

      expect(c.read(syncProvider).lastSyncAt, isNotNull);
      expect(c.read(syncProvider).currentVersion, 5);
    });

    test('pull() gibt false bei Fehler zurück', () async {
      final (_, n, service) = _setup();

      when(() => service.pull(any()))
          .thenThrow(Exception('Pull fehlgeschlagen'));

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
          const SyncStateResponse(currentVersion: 1, pendingServerChanges: 0));
      when(() => service.pull(any())).thenAnswer((_) async =>
          const PullResponse(changes: [], currentVersion: 1, hasMore: false));
      // Pre-inject conflict via push
      when(() => service.push(any(), any())).thenAnswer((_) async =>
          PushResponse(accepted: const [], conflicts: [conflict], newVersion: 2));

      await n.sync();
      await n.push([_delta()]);
      expect(c.read(syncProvider).conflicts, hasLength(1));

      n.resolveConflict('sm-001');

      expect(c.read(syncProvider).conflicts, isEmpty);
    });

    test('setzt Status auf synced wenn keine Konflikte mehr', () async {
      final (c, n, service) = _setup();
      final conflict = _conflict(entityId: 'sm-001');

      when(() => service.push(any(), any())).thenAnswer((_) async =>
          PushResponse(accepted: const [], conflicts: [conflict], newVersion: 2));

      await n.push([_delta()]);
      n.resolveConflict('sm-001');

      expect(c.read(syncProvider).status, SyncStatus.synced);
    });
  });
}
