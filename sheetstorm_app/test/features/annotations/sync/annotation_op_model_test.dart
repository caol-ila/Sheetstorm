import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';

void main() {
  // ─── AnnotationOpType ────────────────────────────────────────────────────

  group('AnnotationOpType', () {
    test('hat create, update, delete Werte', () {
      expect(AnnotationOpType.values, hasLength(3));
      expect(AnnotationOpType.values, contains(AnnotationOpType.create));
      expect(AnnotationOpType.values, contains(AnnotationOpType.update));
      expect(AnnotationOpType.values, contains(AnnotationOpType.delete));
    });

    test('fromJson parst String korrekt', () {
      expect(AnnotationOpType.fromJson('create'), AnnotationOpType.create);
      expect(AnnotationOpType.fromJson('update'), AnnotationOpType.update);
      expect(AnnotationOpType.fromJson('delete'), AnnotationOpType.delete);
    });

    test('fromJson wirft bei unbekanntem Wert', () {
      expect(
        () => AnnotationOpType.fromJson('invalid'),
        throwsArgumentError,
      );
    });

    test('toJson gibt korrekten String', () {
      expect(AnnotationOpType.create.toJson(), 'create');
      expect(AnnotationOpType.update.toJson(), 'update');
      expect(AnnotationOpType.delete.toJson(), 'delete');
    });
  });

  // ─── AnnotationSyncStatus ────────────────────────────────────────────────

  group('AnnotationSyncStatus', () {
    test('hat alle erwarteten Werte', () {
      expect(AnnotationSyncStatus.values, hasLength(5));
      expect(AnnotationSyncStatus.values,
          contains(AnnotationSyncStatus.disconnected));
      expect(AnnotationSyncStatus.values,
          contains(AnnotationSyncStatus.connecting));
      expect(AnnotationSyncStatus.values,
          contains(AnnotationSyncStatus.connected));
      expect(
          AnnotationSyncStatus.values, contains(AnnotationSyncStatus.syncing));
      expect(
          AnnotationSyncStatus.values, contains(AnnotationSyncStatus.error));
    });
  });

  // ─── AnnotationElementDto ────────────────────────────────────────────────

  group('AnnotationElementDto', () {
    final now = DateTime.utc(2026, 4, 1, 12, 0, 0);
    final json = <String, dynamic>{
      'id': 'elem-1',
      'annotationId': 'annot-1',
      'tool': 'pencil',
      'level': 'voice',
      'pageIndex': 2,
      'bbox': {'x': 0.1, 'y': 0.2, 'width': 0.3, 'height': 0.05},
      'points': [
        {'x': 0.1, 'y': 0.2, 'pressure': 0.5},
        {'x': 0.3, 'y': 0.4, 'pressure': 0.7},
      ],
      'text': null,
      'stampCategory': null,
      'stampValue': null,
      'opacity': 1.0,
      'strokeWidth': 3.0,
      'version': 1,
      'isDeleted': false,
      'userId': 'user-1',
      'createdAt': '2026-04-01T12:00:00.000Z',
      'changedAt': '2026-04-01T12:00:00.000Z',
    };

    test('fromJson parst vollständiges Element', () {
      final dto = AnnotationElementDto.fromJson(json);

      expect(dto.id, 'elem-1');
      expect(dto.annotationId, 'annot-1');
      expect(dto.tool, 'pencil');
      expect(dto.level, 'voice');
      expect(dto.pageIndex, 2);
      expect(dto.bbox.x, 0.1);
      expect(dto.bbox.y, 0.2);
      expect(dto.bbox.width, 0.3);
      expect(dto.bbox.height, 0.05);
      expect(dto.points, hasLength(2));
      expect(dto.points![0].x, 0.1);
      expect(dto.points![1].pressure, 0.7);
      expect(dto.text, isNull);
      expect(dto.stampCategory, isNull);
      expect(dto.stampValue, isNull);
      expect(dto.opacity, 1.0);
      expect(dto.strokeWidth, 3.0);
      expect(dto.version, 1);
      expect(dto.isDeleted, false);
      expect(dto.userId, 'user-1');
      expect(dto.createdAt, now);
      expect(dto.changedAt, now);
    });

    test('toJson erzeugt korrektes Map', () {
      final dto = AnnotationElementDto(
        id: 'elem-1',
        annotationId: 'annot-1',
        tool: 'pencil',
        level: 'voice',
        pageIndex: 2,
        bbox: const BBoxDto(x: 0.1, y: 0.2, width: 0.3, height: 0.05),
        points: const [
          StrokePointDto(x: 0.1, y: 0.2, pressure: 0.5),
          StrokePointDto(x: 0.3, y: 0.4, pressure: 0.7),
        ],
        opacity: 1.0,
        strokeWidth: 3.0,
        version: 1,
        isDeleted: false,
        userId: 'user-1',
        createdAt: now,
        changedAt: now,
      );

      final result = dto.toJson();
      expect(result['id'], 'elem-1');
      expect(result['annotationId'], 'annot-1');
      expect(result['tool'], 'pencil');
      expect(result['level'], 'voice');
      expect(result['pageIndex'], 2);
      expect(result['version'], 1);
      expect(result['isDeleted'], false);
    });

    test('fromJson mit Text-Element', () {
      final textJson = <String, dynamic>{
        ...json,
        'tool': 'text',
        'text': 'forte hier',
        'points': null,
      };
      final dto = AnnotationElementDto.fromJson(textJson);
      expect(dto.tool, 'text');
      expect(dto.text, 'forte hier');
      expect(dto.points, isNull);
    });

    test('fromJson mit Stempel-Element', () {
      final stampJson = <String, dynamic>{
        ...json,
        'tool': 'stamp',
        'stampCategory': 'dynamik',
        'stampValue': 'ff',
        'points': null,
      };
      final dto = AnnotationElementDto.fromJson(stampJson);
      expect(dto.stampCategory, 'dynamik');
      expect(dto.stampValue, 'ff');
    });

    test('roundtrip fromJson → toJson → fromJson', () {
      final original = AnnotationElementDto.fromJson(json);
      final roundtrip = AnnotationElementDto.fromJson(original.toJson());
      expect(roundtrip.id, original.id);
      expect(roundtrip.version, original.version);
      expect(roundtrip.tool, original.tool);
      expect(roundtrip.level, original.level);
      expect(roundtrip.pageIndex, original.pageIndex);
    });
  });

  // ─── BBoxDto ─────────────────────────────────────────────────────────────

  group('BBoxDto', () {
    test('fromJson/toJson roundtrip', () {
      const original = BBoxDto(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final json = original.toJson();
      final restored = BBoxDto.fromJson(json);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.width, original.width);
      expect(restored.height, original.height);
    });
  });

  // ─── StrokePointDto ──────────────────────────────────────────────────────

  group('StrokePointDto', () {
    test('fromJson/toJson roundtrip', () {
      const original = StrokePointDto(x: 0.5, y: 0.6, pressure: 0.8);
      final json = original.toJson();
      final restored = StrokePointDto.fromJson(json);
      expect(restored.x, original.x);
      expect(restored.y, original.y);
      expect(restored.pressure, original.pressure);
    });

    test('fromJson mit default pressure', () {
      final dto = StrokePointDto.fromJson({'x': 0.1, 'y': 0.2});
      expect(dto.pressure, 0.5);
    });
  });

  // ─── AnnotationOp ───────────────────────────────────────────────────────

  group('AnnotationOp', () {
    final now = DateTime.utc(2026, 4, 1, 12, 0, 0);

    test('create-Op hat korrekte Felder', () {
      final op = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.create,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-1',
        timestamp: now,
        version: 1,
      );
      expect(op.type, AnnotationOpType.create);
      expect(op.elementId, 'elem-1');
      expect(op.annotationId, 'annot-1');
      expect(op.userId, 'user-1');
      expect(op.version, 1);
    });

    test('fromJson parst create-Op', () {
      final json = <String, dynamic>{
        'id': 'op-1',
        'type': 'create',
        'elementId': 'elem-1',
        'annotationId': 'annot-1',
        'userId': 'user-1',
        'timestamp': '2026-04-01T12:00:00.000Z',
        'version': 1,
        'data': {'tool': 'pencil'},
      };
      final op = AnnotationOp.fromJson(json);
      expect(op.type, AnnotationOpType.create);
      expect(op.data, isNotNull);
      expect(op.data!['tool'], 'pencil');
    });

    test('toJson erzeugt korrektes Map', () {
      final op = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.delete,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-1',
        timestamp: now,
        version: 5,
      );
      final json = op.toJson();
      expect(json['type'], 'delete');
      expect(json['elementId'], 'elem-1');
      expect(json['version'], 5);
    });

    test('delete-Op benötigt kein data', () {
      final op = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.delete,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-1',
        timestamp: now,
        version: 3,
      );
      expect(op.data, isNull);
    });
  });

  // ─── SyncVersion ─────────────────────────────────────────────────────────

  group('SyncVersion', () {
    test('Konstruktor setzt Felder korrekt', () {
      final sv = SyncVersion(
        version: 42,
        lastSyncedAt: DateTime.utc(2026, 4, 1),
      );
      expect(sv.version, 42);
      expect(sv.lastSyncedAt, DateTime.utc(2026, 4, 1));
    });

    test('fromJson/toJson roundtrip', () {
      final original = SyncVersion(
        version: 10,
        lastSyncedAt: DateTime.utc(2026, 3, 30, 18, 0),
      );
      final json = original.toJson();
      final restored = SyncVersion.fromJson(json);
      expect(restored.version, original.version);
      expect(restored.lastSyncedAt, original.lastSyncedAt);
    });

    test('initial() beginnt bei Version 0', () {
      final sv = SyncVersion.initial();
      expect(sv.version, 0);
    });
  });

  // ─── ElementChangeNotification ───────────────────────────────────────────

  group('ElementChangeNotification', () {
    test('create-Notification enthält Element', () {
      final notif = ElementChangeNotification(
        type: AnnotationOpType.create,
        element: AnnotationElementDto(
          id: 'elem-1',
          annotationId: 'annot-1',
          tool: 'pencil',
          level: 'voice',
          pageIndex: 0,
          bbox: const BBoxDto(x: 0, y: 0, width: 0.1, height: 0.1),
          opacity: 1.0,
          strokeWidth: 3.0,
          version: 1,
          isDeleted: false,
          userId: 'user-1',
          createdAt: DateTime.utc(2026),
          changedAt: DateTime.utc(2026),
        ),
      );
      expect(notif.type, AnnotationOpType.create);
      expect(notif.element, isNotNull);
      expect(notif.element!.id, 'elem-1');
    });

    test('delete-Notification enthält elementId + annotationId', () {
      final notif = ElementChangeNotification(
        type: AnnotationOpType.delete,
        elementId: 'elem-1',
        annotationId: 'annot-1',
      );
      expect(notif.type, AnnotationOpType.delete);
      expect(notif.elementId, 'elem-1');
      expect(notif.annotationId, 'annot-1');
    });

    test('fromJson parst create-Notification', () {
      final json = <String, dynamic>{
        'type': 'create',
        'element': {
          'id': 'elem-1',
          'annotationId': 'annot-1',
          'tool': 'pencil',
          'level': 'voice',
          'pageIndex': 0,
          'bbox': {'x': 0, 'y': 0, 'width': 0.1, 'height': 0.1},
          'opacity': 1.0,
          'strokeWidth': 3.0,
          'version': 1,
          'isDeleted': false,
          'userId': 'user-1',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'changedAt': '2026-01-01T00:00:00.000Z',
        },
      };
      final notif = ElementChangeNotification.fromJson(json);
      expect(notif.type, AnnotationOpType.create);
      expect(notif.element, isNotNull);
    });

    test('toJson roundtrip für delete', () {
      final original = ElementChangeNotification(
        type: AnnotationOpType.delete,
        elementId: 'elem-99',
        annotationId: 'annot-5',
      );
      final json = original.toJson();
      final restored = ElementChangeNotification.fromJson(json);
      expect(restored.type, AnnotationOpType.delete);
      expect(restored.elementId, 'elem-99');
    });
  });

  // ─── Conflict Detection ──────────────────────────────────────────────────

  group('Conflict Detection — LWW per Element', () {
    test('neuerer Timestamp gewinnt bei gleichem Element', () {
      final older = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final newer = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 5),
        version: 6,
      );
      final winner = AnnotationOp.resolveConflict(older, newer);
      expect(winner.id, newer.id);
      expect(winner.userId, 'user-B');
    });

    test('bei gleichem Timestamp gewinnt höhere Version', () {
      final sameTime = DateTime.utc(2026, 4, 1, 12, 0, 0);
      final a = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: sameTime,
        version: 5,
      );
      final b = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: sameTime,
        version: 6,
      );
      final winner = AnnotationOp.resolveConflict(a, b);
      expect(winner.version, 6);
    });

    test('delete gewinnt über update bei neuerem Timestamp', () {
      final update = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final delete = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.delete,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 1),
        version: 6,
      );
      final winner = AnnotationOp.resolveConflict(update, delete);
      expect(winner.type, AnnotationOpType.delete);
    });

    test('älterer delete verliert gegen neueren update', () {
      final delete = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.delete,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final update = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 5),
        version: 6,
      );
      final winner = AnnotationOp.resolveConflict(delete, update);
      expect(winner.type, AnnotationOpType.update);
    });

    test('isConflict erkennt gleiche elementId', () {
      final a = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final b = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 1),
        version: 5,
      );
      expect(AnnotationOp.isConflict(a, b), true);
    });

    test('kein Konflikt bei unterschiedlichen Elementen', () {
      final a = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final b = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-2',
        annotationId: 'annot-1',
        userId: 'user-B',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 1),
        version: 5,
      );
      expect(AnnotationOp.isConflict(a, b), false);
    });

    test('kein Konflikt bei gleichem Nutzer', () {
      final a = AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 0),
        version: 5,
      );
      final b = AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-A',
        timestamp: DateTime.utc(2026, 4, 1, 12, 0, 1),
        version: 6,
      );
      expect(AnnotationOp.isConflict(a, b), false);
    });
  });
}
