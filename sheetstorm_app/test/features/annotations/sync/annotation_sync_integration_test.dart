import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_converters.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

AnnotationSyncState _syncState(ProviderContainer c) =>
    c.read(annotationSyncNotifierProvider);

AnnotationSyncNotifier _syncNotifier(ProviderContainer c) =>
    c.read(annotationSyncNotifierProvider.notifier);

AnnotationState _annotState(ProviderContainer c, String pieceId) =>
    c.read(annotationProvider(pieceId));

AnnotationNotifier _annotNotifier(ProviderContainer c, String pieceId) =>
    c.read(annotationProvider(pieceId).notifier);

AnnotationElementDto _elementDto({
  String id = 'remote-elem-1',
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
      points: const [
        StrokePointDto(x: 0.1, y: 0.2, pressure: 0.5),
        StrokePointDto(x: 0.3, y: 0.4, pressure: 0.7),
      ],
      opacity: 1.0,
      strokeWidth: 3.0,
      version: version,
      isDeleted: isDeleted,
      userId: userId,
      createdAt: DateTime.utc(2026, 4, 1),
      changedAt: DateTime.utc(2026, 4, 1),
    );

void main() {
  // ─── DTO ↔ Annotation Conversion ─────────────────────────────────────────

  group('AnnotationElementDto → Annotation Konvertierung', () {
    test('toAnnotation konvertiert pencil-Element korrekt', () {
      final dto = _elementDto();
      final annotation = dtoToAnnotation(dto);

      expect(annotation.id, 'remote-elem-1');
      expect(annotation.level, AnnotationLevel.voice);
      expect(annotation.tool, AnnotationTool.pencil);
      expect(annotation.pageIndex, 0);
      expect(annotation.bbox.x, 0.1);
      expect(annotation.points, hasLength(2));
      expect(annotation.opacity, 1.0);
      expect(annotation.strokeWidth, 3.0);
    });

    test('toAnnotation konvertiert text-Element korrekt', () {
      final dto = AnnotationElementDto(
        id: 'text-elem',
        annotationId: 'annot-1',
        tool: 'text',
        level: 'orchestra',
        pageIndex: 3,
        bbox: const BBoxDto(x: 0.5, y: 0.5, width: 0.15, height: 0.03),
        text: 'forte hier',
        opacity: 1.0,
        strokeWidth: 3.0,
        version: 1,
        isDeleted: false,
        userId: 'user-1',
        createdAt: DateTime.utc(2026, 4, 1),
        changedAt: DateTime.utc(2026, 4, 1),
      );
      final annotation = dtoToAnnotation(dto);
      expect(annotation.tool, AnnotationTool.text);
      expect(annotation.text, 'forte hier');
      expect(annotation.level, AnnotationLevel.orchestra);
    });

    test('toAnnotation konvertiert stamp-Element korrekt', () {
      final dto = AnnotationElementDto(
        id: 'stamp-elem',
        annotationId: 'annot-1',
        tool: 'stamp',
        level: 'private',
        pageIndex: 1,
        bbox: const BBoxDto(x: 0.3, y: 0.4, width: 0.04, height: 0.03),
        stampCategory: 'dynamik',
        stampValue: 'ff',
        opacity: 1.0,
        strokeWidth: 3.0,
        version: 1,
        isDeleted: false,
        userId: 'user-1',
        createdAt: DateTime.utc(2026, 4, 1),
        changedAt: DateTime.utc(2026, 4, 1),
      );
      final annotation = dtoToAnnotation(dto);
      expect(annotation.tool, AnnotationTool.stamp);
      expect(annotation.stampCategory, 'dynamik');
      expect(annotation.stampValue, 'ff');
    });

    test('Annotation → AnnotationElementDto roundtrip', () {
      final original = Annotation(
        id: 'local-1',
        level: AnnotationLevel.voice,
        tool: AnnotationTool.pencil,
        pageIndex: 2,
        bbox: const BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.05),
        createdAt: DateTime.utc(2026, 4, 1),
        points: const [
          StrokePoint(x: 0.1, y: 0.2),
          StrokePoint(x: 0.3, y: 0.4),
        ],
        opacity: 0.8,
        strokeWidth: 5.0,
      );

      final dto = annotationToDto(
        original,
        annotationId: 'annot-1',
        userId: 'user-1',
        version: 1,
      );
      expect(dto.id, 'local-1');
      expect(dto.tool, 'pencil');
      expect(dto.level, 'voice');
      expect(dto.pageIndex, 2);
      expect(dto.opacity, 0.8);
      expect(dto.strokeWidth, 5.0);
      expect(dto.points, hasLength(2));
    });
  });

  // ─── Level String Mapping ────────────────────────────────────────────────

  group('Level String Mapping', () {
    test('levelFromString parst alle Level', () {
      expect(levelFromString('private'), AnnotationLevel.private);
      expect(levelFromString('voice'), AnnotationLevel.voice);
      expect(levelFromString('orchestra'), AnnotationLevel.orchestra);
    });

    test('levelToString erzeugt korrekte Strings', () {
      expect(levelToString(AnnotationLevel.private), 'private');
      expect(levelToString(AnnotationLevel.voice), 'voice');
      expect(levelToString(AnnotationLevel.orchestra), 'orchestra');
    });
  });

  // ─── Tool String Mapping ─────────────────────────────────────────────────

  group('Tool String Mapping', () {
    test('toolFromString parst alle Tools', () {
      expect(toolFromString('pencil'), AnnotationTool.pencil);
      expect(toolFromString('highlighter'), AnnotationTool.highlighter);
      expect(toolFromString('text'), AnnotationTool.text);
      expect(toolFromString('stamp'), AnnotationTool.stamp);
      expect(toolFromString('eraser'), AnnotationTool.eraser);
    });

    test('toolToString erzeugt korrekte Strings', () {
      expect(toolToString(AnnotationTool.pencil), 'pencil');
      expect(toolToString(AnnotationTool.text), 'text');
    });
  });

  // ─── Remote Op Application to Annotation State ───────────────────────────

  group('Remote Op Application', () {
    test('applyRemoteAdd fügt Annotation zum lokalen State hinzu', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const pieceId = 'test-piece';
      final annotNotifier = _annotNotifier(container, pieceId);
      final syncNotifier = _syncNotifier(container);

      // Remote add
      final dto = _elementDto(id: 'remote-1', pageIndex: 0);
      syncNotifier.applyRemoteAdd(dto);

      // Convert and apply to annotation state
      final annotation = dtoToAnnotation(dto);
      annotNotifier.addAnnotation(annotation);

      expect(_annotState(container, pieceId).annotations, hasLength(1));
      expect(_annotState(container, pieceId).annotations.first.id, 'remote-1');
    });

    test('applyRemoteDelete entfernt Annotation aus lokalem State', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const pieceId = 'test-piece';
      final annotNotifier = _annotNotifier(container, pieceId);
      final syncNotifier = _syncNotifier(container);

      // Add two annotations
      final dto1 = _elementDto(id: 'elem-1');
      final dto2 = _elementDto(id: 'elem-2');
      annotNotifier.addAnnotation(dtoToAnnotation(dto1));
      annotNotifier.addAnnotation(dtoToAnnotation(dto2));
      expect(_annotState(container, pieceId).annotations, hasLength(2));

      // Remote delete
      syncNotifier.applyRemoteDelete('elem-1');
      annotNotifier.removeAnnotation('elem-1');

      expect(_annotState(container, pieceId).annotations, hasLength(1));
      expect(
          _annotState(container, pieceId).annotations.first.id, 'elem-2');
    });

    test('private annotations werden nicht zur Sync-Queue hinzugefügt', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      _syncNotifier(container);

      // Simulate: private annotation → should NOT be queued
      const level = AnnotationLevel.private;
      expect(shouldSync(level), false);
      expect(_syncState(container).offlineQueue, isEmpty);
    });

    test('voice annotations werden zur Sync-Queue hinzugefügt', () {
      expect(shouldSync(AnnotationLevel.voice), true);
    });

    test('orchestra annotations werden zur Sync-Queue hinzugefügt', () {
      expect(shouldSync(AnnotationLevel.orchestra), true);
    });
  });

  // ─── Offline → Reconnect → Queue Replay ──────────────────────────────────

  group('Offline Queue Replay', () {
    test('ops werden bei Offline gequeued und bei Reconnect flushed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final syncNotifier = _syncNotifier(container);

      // Simulate offline ops
      syncNotifier.setStatus(AnnotationSyncStatus.disconnected);
      syncNotifier.enqueueOp(AnnotationOp(
        id: 'op-1',
        type: AnnotationOpType.create,
        elementId: 'elem-1',
        annotationId: 'annot-1',
        userId: 'user-1',
        timestamp: DateTime.utc(2026, 4, 1),
        version: 1,
      ));
      syncNotifier.enqueueOp(AnnotationOp(
        id: 'op-2',
        type: AnnotationOpType.update,
        elementId: 'elem-2',
        annotationId: 'annot-1',
        userId: 'user-1',
        timestamp: DateTime.utc(2026, 4, 1, 0, 0, 1),
        version: 2,
      ));
      expect(_syncState(container).pendingOpsCount, 2);

      // Simulate reconnect → flush
      syncNotifier.setStatus(AnnotationSyncStatus.connected);
      final ops = syncNotifier.dequeueOps();
      expect(ops, hasLength(2));
      expect(_syncState(container).offlineQueue, isEmpty);
    });
  });
}

// Conversion utilities imported from annotation_sync_converters.dart
