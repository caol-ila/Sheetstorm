import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

AnnotationSyncState _state(ProviderContainer c) =>
    c.read(annotationSyncNotifierProvider);

AnnotationSyncNotifier _notifier(ProviderContainer c) =>
    c.read(annotationSyncNotifierProvider.notifier);

AnnotationOp _op({
  String id = 'op-1',
  AnnotationOpType type = AnnotationOpType.create,
  String elementId = 'elem-1',
  String annotationId = 'annot-1',
  String userId = 'user-1',
  int version = 1,
  DateTime? timestamp,
}) =>
    AnnotationOp(
      id: id,
      type: type,
      elementId: elementId,
      annotationId: annotationId,
      userId: userId,
      timestamp: timestamp ?? DateTime.utc(2026, 4, 1),
      version: version,
    );

AnnotationElementDto _elementDto({
  String id = 'elem-1',
  String annotationId = 'annot-1',
  String tool = 'pencil',
  String level = 'voice',
  int pageIndex = 0,
  int version = 1,
  bool isDeleted = false,
  String userId = 'user-remote',
}) =>
    AnnotationElementDto(
      id: id,
      annotationId: annotationId,
      tool: tool,
      level: level,
      pageIndex: pageIndex,
      bbox: const BBoxDto(x: 0.1, y: 0.2, width: 0.3, height: 0.05),
      opacity: 1.0,
      strokeWidth: 3.0,
      version: version,
      isDeleted: isDeleted,
      userId: userId,
      createdAt: DateTime.utc(2026, 4, 1),
      changedAt: DateTime.utc(2026, 4, 1),
    );

void main() {
  // ─── Initial State ───────────────────────────────────────────────────────

  group('AnnotationSyncState — initialer Zustand', () {
    test('beginnt als disconnected', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).status, AnnotationSyncStatus.disconnected);
    });

    test('beginnt mit leerer Offline-Queue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).offlineQueue, isEmpty);
    });

    test('beginnt mit SyncVersion 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).syncVersion.version, 0);
    });

    test('beginnt ohne Fehler', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).error, isNull);
    });

    test('beginnt mit leerer remoteElements-Liste', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).remoteElements, isEmpty);
    });

    test('beginnt mit leerer activeEditors-Map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(_state(container).activeEditors, isEmpty);
    });
  });

  // ─── Status-Transitions ──────────────────────────────────────────────────

  group('Status-Transitions', () {
    test('setStatus ändert Status korrekt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setStatus(AnnotationSyncStatus.connecting);
      expect(_state(container).status, AnnotationSyncStatus.connecting);

      n.setStatus(AnnotationSyncStatus.connected);
      expect(_state(container).status, AnnotationSyncStatus.connected);
    });

    test('setError setzt Status auf error + Fehlermeldung', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setError('Verbindung verloren');
      expect(_state(container).status, AnnotationSyncStatus.error);
      expect(_state(container).error, 'Verbindung verloren');
    });

    test('clearError setzt Status auf disconnected + löscht Fehler', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setError('Fehler');
      n.clearError();
      expect(_state(container).status, AnnotationSyncStatus.disconnected);
      expect(_state(container).error, isNull);
    });
  });

  // ─── Offline Queue ───────────────────────────────────────────────────────

  group('Offline Queue — Op-Queuing', () {
    test('enqueueOp fügt Op zur Queue hinzu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.enqueueOp(_op());
      expect(_state(container).offlineQueue, hasLength(1));
      expect(_state(container).offlineQueue.first.id, 'op-1');
    });

    test('enqueueOp fügt mehrere Ops hinzu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.enqueueOp(_op(id: 'op-1'));
      n.enqueueOp(_op(id: 'op-2'));
      n.enqueueOp(_op(id: 'op-3'));
      expect(_state(container).offlineQueue, hasLength(3));
    });

    test('clearQueue leert die Queue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.enqueueOp(_op(id: 'op-1'));
      n.enqueueOp(_op(id: 'op-2'));
      n.clearQueue();
      expect(_state(container).offlineQueue, isEmpty);
    });

    test('dequeueOps gibt Queue zurück und leert sie', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.enqueueOp(_op(id: 'op-1'));
      n.enqueueOp(_op(id: 'op-2'));
      final ops = n.dequeueOps();
      expect(ops, hasLength(2));
      expect(_state(container).offlineQueue, isEmpty);
    });
  });

  // ─── Remote Element Application ──────────────────────────────────────────

  group('Remote Element Application', () {
    test('applyRemoteAdd fügt Element hinzu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto());
      expect(_state(container).remoteElements, hasLength(1));
      expect(_state(container).remoteElements.first.id, 'elem-1');
    });

    test('applyRemoteAdd ignoriert Duplikate (gleiche ID)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'elem-1'));
      n.applyRemoteAdd(_elementDto(id: 'elem-1'));
      expect(_state(container).remoteElements, hasLength(1));
    });

    test('applyRemoteUpdate aktualisiert vorhandenes Element', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'elem-1', version: 1));
      n.applyRemoteUpdate(
          _elementDto(id: 'elem-1', version: 2, tool: 'highlighter'));

      final elem = _state(container).remoteElements.first;
      expect(elem.version, 2);
      expect(elem.tool, 'highlighter');
    });

    test('applyRemoteUpdate ignoriert ältere Version', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'elem-1', version: 3));
      n.applyRemoteUpdate(_elementDto(id: 'elem-1', version: 2));

      expect(_state(container).remoteElements.first.version, 3);
    });

    test('applyRemoteDelete entfernt Element', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'elem-1'));
      n.applyRemoteAdd(_elementDto(id: 'elem-2'));
      n.applyRemoteDelete('elem-1');

      expect(_state(container).remoteElements, hasLength(1));
      expect(_state(container).remoteElements.first.id, 'elem-2');
    });

    test('applyRemoteDelete ignoriert unbekanntes Element', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'elem-1'));
      n.applyRemoteDelete('elem-999');
      expect(_state(container).remoteElements, hasLength(1));
    });
  });

  // ─── Bulk Sync ───────────────────────────────────────────────────────────

  group('Bulk Sync', () {
    test('applyBulkSync ersetzt alle remoteElements', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyRemoteAdd(_elementDto(id: 'old-1'));
      n.applyBulkSync([
        _elementDto(id: 'new-1'),
        _elementDto(id: 'new-2'),
      ], 42);

      expect(_state(container).remoteElements, hasLength(2));
      expect(
          _state(container).remoteElements.map((e) => e.id), ['new-1', 'new-2']);
      expect(_state(container).syncVersion.version, 42);
    });

    test('applyBulkSync filtert gelöschte Elemente heraus', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.applyBulkSync([
        _elementDto(id: 'alive', isDeleted: false),
        _elementDto(id: 'dead', isDeleted: true),
      ], 10);

      expect(_state(container).remoteElements, hasLength(1));
      expect(_state(container).remoteElements.first.id, 'alive');
    });
  });

  // ─── SyncVersion Updates ─────────────────────────────────────────────────

  group('SyncVersion', () {
    test('updateSyncVersion aktualisiert Version', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.updateSyncVersion(99);
      expect(_state(container).syncVersion.version, 99);
    });
  });

  // ─── Active Editors (Presence) ───────────────────────────────────────────

  group('Active Editors — Presence', () {
    test('setActiveEditor registriert Editor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setActiveEditor('user-A', 'elem-1');
      expect(_state(container).activeEditors, {'user-A': 'elem-1'});
    });

    test('removeActiveEditor entfernt Editor', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setActiveEditor('user-A', 'elem-1');
      n.removeActiveEditor('user-A');
      expect(_state(container).activeEditors, isEmpty);
    });

    test('mehrere Editoren gleichzeitig', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setActiveEditor('user-A', 'elem-1');
      n.setActiveEditor('user-B', 'elem-2');
      expect(_state(container).activeEditors, hasLength(2));
    });

    test('clearActiveEditors entfernt alle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.setActiveEditor('user-A', 'elem-1');
      n.setActiveEditor('user-B', 'elem-2');
      n.clearActiveEditors();
      expect(_state(container).activeEditors, isEmpty);
    });
  });

  // ─── Conflict Tracking ───────────────────────────────────────────────────

  group('Conflict Tracking', () {
    test('recordConflict speichert Konflikt-Info', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.recordConflict(ConflictInfo(
        elementId: 'elem-1',
        winnerUserId: 'user-B',
        loserUserId: 'user-A',
        resolvedAt: DateTime.utc(2026, 4, 1),
      ));
      expect(_state(container).lastConflict, isNotNull);
      expect(_state(container).lastConflict!.winnerUserId, 'user-B');
    });

    test('dismissConflict löscht Konflikt-Info', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final n = _notifier(container);

      n.recordConflict(ConflictInfo(
        elementId: 'elem-1',
        winnerUserId: 'user-B',
        loserUserId: 'user-A',
        resolvedAt: DateTime.utc(2026, 4, 1),
      ));
      n.dismissConflict();
      expect(_state(container).lastConflict, isNull);
    });
  });

  // ─── State copyWith ──────────────────────────────────────────────────────

  group('AnnotationSyncState copyWith', () {
    test('copyWith übernimmt Werte korrekt', () {
      const initial = AnnotationSyncState();
      final updated = initial.copyWith(
        status: AnnotationSyncStatus.connected,
      );
      expect(updated.status, AnnotationSyncStatus.connected);
      expect(updated.offlineQueue, isEmpty);
    });

    test('copyWith mit sentinel für nullable Felder', () {
      final withError = const AnnotationSyncState().copyWith(
        error: 'test error',
      );
      expect(withError.error, 'test error');

      final cleared = withError.copyWith(clearError: true);
      expect(cleared.error, isNull);
    });

    test('isOnline helper', () {
      expect(
        const AnnotationSyncState(status: AnnotationSyncStatus.connected)
            .isOnline,
        true,
      );
      expect(
        const AnnotationSyncState(status: AnnotationSyncStatus.syncing)
            .isOnline,
        true,
      );
      expect(
        const AnnotationSyncState(status: AnnotationSyncStatus.disconnected)
            .isOnline,
        false,
      );
      expect(
        const AnnotationSyncState(status: AnnotationSyncStatus.error).isOnline,
        false,
      );
    });

    test('pendingOpsCount zählt Queue', () {
      final s = const AnnotationSyncState().copyWith(
        offlineQueue: [_op(id: 'a'), _op(id: 'b')],
      );
      expect(s.pendingOpsCount, 2);
    });
  });
}
