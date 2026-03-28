import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/application/annotation_toolbar_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotations/data/models/stamp_catalog.dart';
import 'package:sheetstorm/features/annotations/presentation/painters/annotation_painter.dart';
import 'package:sheetstorm/features/annotations/presentation/painters/drawing_painter.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Annotation _annot({
  String id = 'edge',
  AnnotationLevel level = AnnotationLevel.private,
  AnnotationTool tool = AnnotationTool.pencil,
  List<StrokePoint> points = const [],
  String? text,
}) =>
    Annotation(
      id: id,
      level: level,
      tool: tool,
      pageIndex: 0,
      bbox: const BBox(x: 0, y: 0, width: 0, height: 0),
      createdAt: DateTime(2026, 1, 1),
      points: points,
      text: text,
    );

void _paintOnCanvas(CustomPainter painter) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, const Size(400, 600));
  recorder.endRecording();
}

(ProviderContainer, AnnotationNotifier) _setup() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return (c, c.read(annotationProvider('edge').notifier));
}

AnnotationState _state(ProviderContainer c) => c.read(annotationProvider('edge'));

(ProviderContainer, AnnotationToolbarNotifier) _toolbarSetup() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return (c, c.read(annotationToolbarProvider.notifier));
}

void main() {
  // ─── Leere Annotation (Null-Pfad) ─────────────────────────────────────────

  group('Edge Case: Leere Annotation (zero-length path)', () {
    test('svgPath für leere Punkte ist leer', () {
      expect(_annot().svgPath, '');
    });

    test('computeBBox für leere Punkte → Null-BBox', () {
      expect(
        Annotation.computeBBox([]),
        equals(const BBox(x: 0, y: 0, width: 0, height: 0)),
      );
    });

    test('commitStroke mit leeren Punkten → keine Annotation hinzugefügt', () {
      final (c, n) = _setup();
      n.commitStroke(
        points: [],
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        strokeWidth: 3.0,
        opacity: 1.0,
      );
      expect(_state(c).annotations, isEmpty);
    });

    test('AnnotationPainter: Annotation mit 0 Punkten → kein Fehler', () {
      final painter = AnnotationPainter(
        annotations: [_annot()],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('AnnotationPainter: Annotation mit nur 1 Punkt → kein Fehler', () {
      final painter = AnnotationPainter(
        annotations: [
          _annot(points: [const StrokePoint(x: 0.5, y: 0.5)])
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('DrawingPainter: leer → kein Fehler', () {
      final painter = DrawingPainter(
        points: const [],
        color: Colors.blue,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });
  });

  // ─── Sehr langer Text ─────────────────────────────────────────────────────

  group('Edge Case: Sehr langer Text', () {
    test('Text mit 201 Zeichen wird auf 200 gekürzt', () {
      final (c, n) = _setup();
      n.addTextAnnotation(
        text: 'X' * 201,
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations.first.text!.length, 200);
    });

    test('Text mit 1000 Zeichen wird auf 200 gekürzt', () {
      final (c, n) = _setup();
      n.addTextAnnotation(
        text: 'A' * 1000,
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations.first.text!.length, 200);
    });

    test('Text mit genau 200 Zeichen bleibt unverändert', () {
      final (c, n) = _setup();
      n.addTextAnnotation(
        text: 'Z' * 200,
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.voice,
      );
      expect(_state(c).annotations.first.text!.length, 200);
    });

    test('Leerer Text → keine Annotation (Guard)', () {
      final (c, n) = _setup();
      n.addTextAnnotation(
        text: '',
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations, isEmpty);
    });

    test('AnnotationPainter: Annotation mit langem Text → kein Fehler', () {
      final painter = AnnotationPainter(
        annotations: [
          _annot(
            tool: AnnotationTool.text,
            text: 'T' * 200,
          )
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });
  });

  // ─── Schnelles Undo/Redo ──────────────────────────────────────────────────

  group('Edge Case: Schnelles Undo/Redo', () {
    test('Rapid undo über Stack-Ende hinaus → kein Fehler', () {
      final (c, n) = _setup();
      n.addAnnotation(_annot(id: 'a'));
      for (var i = 0; i < 20; i++) {
        n.undo(); // über Stack-Ende hinaus
      }
      expect(_state(c).annotations, isEmpty);
      expect(_state(c).undoStack, isEmpty);
    });

    test('Rapid redo über Stack-Ende hinaus → kein Fehler', () {
      final (c, n) = _setup();
      n.addAnnotation(_annot(id: 'a'));
      n.undo();
      for (var i = 0; i < 20; i++) {
        n.redo(); // über Stack-Ende hinaus
      }
      expect(_state(c).annotations.length, 1);
      expect(_state(c).redoStack, isEmpty);
    });

    test('100 Undo-Operationen in Folge — konsistenter Zustand', () {
      final (c, n) = _setup();
      for (var i = 0; i < 50; i++) {
        n.addAnnotation(_annot(id: 'a$i'));
      }
      for (var i = 0; i < 100; i++) {
        n.undo();
      }
      expect(_state(c).annotations, isEmpty);
      expect(_state(c).undoStack, isEmpty);
    });

    test('50× add + 50× undo + 50× redo → 50 annotations', () {
      final (c, n) = _setup();
      for (var i = 0; i < 50; i++) {
        n.addAnnotation(_annot(id: 'a$i'));
      }
      for (var i = 0; i < 50; i++) {
        n.undo();
      }
      for (var i = 0; i < 50; i++) {
        n.redo();
      }
      expect(_state(c).annotations.length, 50);
    });
  });

  // ─── Druckwerte ───────────────────────────────────────────────────────────

  group('Edge Case: Druckwerte (pressure sensitivity)', () {
    test('Druckwert 0.0 wird in StrokePoint gespeichert', () {
      const p = StrokePoint(x: 0.5, y: 0.5, pressure: 0.0);
      expect(p.pressure, 0.0);
    });

    test('Druckwert 1.0 wird in StrokePoint gespeichert', () {
      const p = StrokePoint(x: 0.5, y: 0.5, pressure: 1.0);
      expect(p.pressure, 1.0);
    });

    test('DrawingPainter mit Druck 0.0 — keine Exception', () {
      final painter = DrawingPainter(
        points: [
          const StrokePoint(x: 0.1, y: 0.1, pressure: 0.0),
          const StrokePoint(x: 0.9, y: 0.9, pressure: 0.0),
        ],
        color: Colors.blue,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('DrawingPainter mit Druck 1.0 — keine Exception', () {
      final painter = DrawingPainter(
        points: [
          const StrokePoint(x: 0.1, y: 0.1, pressure: 1.0),
          const StrokePoint(x: 0.9, y: 0.9, pressure: 1.0),
        ],
        color: Colors.orange,
        strokeWidth: 8.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('AnnotationPainter: Stroke mit Druck 0.0 wird geclippt (≥0.2)', () {
      // Der Painter clampt pressure auf [0.2, 1.0] intern.
      // Wir prüfen, dass kein Fehler entsteht.
      final painter = AnnotationPainter(
        annotations: [
          Annotation(
            id: 'low-p',
            level: AnnotationLevel.private,
            tool: AnnotationTool.pencil,
            pageIndex: 0,
            bbox: const BBox(x: 0.1, y: 0.1, width: 0.5, height: 0.1),
            createdAt: DateTime(2026),
            points: const [
              StrokePoint(x: 0.1, y: 0.1, pressure: 0.0),
              StrokePoint(x: 0.3, y: 0.2, pressure: 0.0),
              StrokePoint(x: 0.6, y: 0.1, pressure: 0.0),
            ],
            strokeWidth: 3.0,
          )
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('setOpacity(2.0) wird auf 1.0 geklemmt', () {
      final (c, n) = _toolbarSetup();
      n.setOpacity(2.0);
      expect(c.read(annotationToolbarProvider).opacity, closeTo(1.0, 1e-9));
    });

    test('setOpacity(-1.0) wird auf 0.0 geklemmt', () {
      final (c, n) = _toolbarSetup();
      n.setOpacity(-1.0);
      expect(c.read(annotationToolbarProvider).opacity, closeTo(0.0, 1e-9));
    });
  });

  // ─── Sonderfälle im Stempel-Katalog ──────────────────────────────────────

  group('Edge Case: Stempel-Katalog', () {
    test('Unbekannte Kategorie → find() gibt null zurück', () {
      expect(StampCatalog.find('unbekannt', 'xxx'), isNull);
    });

    test('Unbekannter Wert in valider Kategorie → null', () {
      expect(StampCatalog.find('dynamik', 'ffffffff'), isNull);
    });

    test('Bekannte Kategorie + Wert → StampDefinition zurück', () {
      final result = StampCatalog.find('dynamik', 'mf');
      expect(result, isNotNull);
      expect(result!.value, 'mf');
    });
  });
}
