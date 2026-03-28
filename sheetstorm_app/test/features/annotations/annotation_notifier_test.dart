import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Annotation _annotation({
  String id = 'test_id',
  AnnotationLevel level = AnnotationLevel.private,
  int pageIndex = 0,
}) =>
    Annotation(
      id: id,
      level: level,
      tool: AnnotationTool.pencil,
      pageIndex: pageIndex,
      bbox: const BBox(x: 0.1, y: 0.1, width: 0.2, height: 0.1),
      createdAt: DateTime(2026, 1, 1),
      points: const [
        StrokePoint(x: 0.1, y: 0.1),
        StrokePoint(x: 0.3, y: 0.2),
      ],
    );

/// Creates a [ProviderContainer] scoped to the given pieceId.
/// Automatically disposed at end of test via [addTearDown].
(ProviderContainer, AnnotationNotifier) _setup(
  dynamic testContext, {
  String pieceId = 'test-stuck',
}) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(annotationProvider(pieceId).notifier);
  return (container, notifier);
}

AnnotationState _state(ProviderContainer c, [String pieceId = 'test-stuck']) =>
    c.read(annotationProvider(pieceId));

void main() {
  // ─── Add Annotation ─────────────────────────────────────────────────────

  group('addAnnotation — alle 3 Ebenen', () {
    test('Privat-Annotation wird hinzugefügt', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(level: AnnotationLevel.private));
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.level, AnnotationLevel.private);
    });

    test('Stimme-Annotation wird hinzugefügt', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(level: AnnotationLevel.voice));
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.level, AnnotationLevel.voice);
    });

    test('Orchester-Annotation wird hinzugefügt', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(level: AnnotationLevel.orchestra));
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.level, AnnotationLevel.orchestra);
    });

    test('Mehrere annotations akkumulieren sich', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1', level: AnnotationLevel.private));
      n.addAnnotation(_annotation(id: 'a2', level: AnnotationLevel.voice));
      n.addAnnotation(_annotation(id: 'a3', level: AnnotationLevel.orchestra));
      expect(_state(c).annotations.length, 3);
    });

    test('addAnnotation leert Redo-Stack', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1'));
      n.undo();
      expect(_state(c).redoStack.isNotEmpty, isTrue);

      n.addAnnotation(_annotation(id: 'a2'));
      expect(_state(c).redoStack, isEmpty);
    });

    test('addAnnotation fügt Undo-Eintrag hinzu', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation());
      expect(_state(c).undoStack.length, 1);
      expect(_state(c).undoStack.first.type, UndoActionType.add);
    });
  });

  // ─── Remove Annotation ───────────────────────────────────────────────────

  group('removeAnnotation — Lösch-Logik', () {
    test('Annotation wird entfernt', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'del'));
      expect(_state(c).annotations.length, 1);

      n.removeAnnotation('del');
      expect(_state(c).annotations, isEmpty);
    });

    test('Unbekannte ID → keine Änderung', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1'));
      n.removeAnnotation('does_not_exist');
      expect(_state(c).annotations.length, 1);
    });

    test('Nur die angegebene Annotation wird gelöscht (andere bleiben)', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1'));
      n.addAnnotation(_annotation(id: 'a2'));
      n.removeAnnotation('a1');
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.id, 'a2');
    });

    test('removeAnnotation fügt Undo-Eintrag vom Typ remove hinzu', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'del'));
      n.removeAnnotation('del');
      expect(_state(c).undoStack.last.type, UndoActionType.remove);
    });
  });

  // ─── Undo / Redo ─────────────────────────────────────────────────────────

  group('Undo/Redo — Stack-Verhalten', () {
    test('Undo nach add → Annotation verschwindet', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation());
      n.undo();
      expect(_state(c).annotations, isEmpty);
    });

    test('Redo nach undo → Annotation kehrt zurück', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation());
      n.undo();
      n.redo();
      expect(_state(c).annotations.length, 1);
    });

    test('Undo nach remove → Annotation kehrt zurück', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'r1'));
      n.removeAnnotation('r1');
      n.undo();
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.id, 'r1');
    });

    test('Undo auf leerem Stack → keine Fehler', () {
      final (_, n) = _setup(null);
      expect(() => n.undo(), returnsNormally);
    });

    test('Redo auf leerem Stack → keine Fehler', () {
      final (_, n) = _setup(null);
      expect(() => n.redo(), returnsNormally);
    });

    test('canUndo ist false bei leerem Stack', () {
      final (c, _) = _setup(null);
      expect(_state(c).canUndo, isFalse);
    });

    test('canRedo ist false bei leerem Stack', () {
      final (c, _) = _setup(null);
      expect(_state(c).canRedo, isFalse);
    });

    test('canUndo ist true nach add', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation());
      expect(_state(c).canUndo, isTrue);
    });

    test('canRedo ist true nach undo', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation());
      n.undo();
      expect(_state(c).canRedo, isTrue);
    });

    test('Neue Aktion nach undo leert Redo-Stack', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1'));
      n.undo();
      n.addAnnotation(_annotation(id: 'a2'));
      expect(_state(c).canRedo, isFalse);
    });

    test('Mehrfaches Undo/Redo — korrekter End-Zustand', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'a1'));
      n.addAnnotation(_annotation(id: 'a2'));
      n.addAnnotation(_annotation(id: 'a3'));

      n.undo(); // undo a3
      n.undo(); // undo a2
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.id, 'a1');

      n.redo(); // redo a2
      expect(_state(c).annotations.length, 2);

      n.redo(); // redo a3
      expect(_state(c).annotations.length, 3);
    });

    test('Schnelles abwechselndes Undo/Redo — stabil', () {
      final (c, n) = _setup(null);
      for (var i = 0; i < 20; i++) {
        n.addAnnotation(_annotation(id: 'a$i'));
      }
      for (var i = 0; i < 15; i++) {
        n.undo();
      }
      for (var i = 0; i < 10; i++) {
        n.redo();
      }
      for (var i = 0; i < 5; i++) {
        n.undo();
      }
      final count = _state(c).annotations.length;
      expect(count, greaterThanOrEqualTo(0));
      expect(count, lessThanOrEqualTo(20));
    });
  });

  // ─── Layer Toggle ────────────────────────────────────────────────────────

  group('toggleLayerVisibility — Layer ein-/ausblenden', () {
    test('Privat ausblenden', () {
      final (c, n) = _setup(null);
      n.toggleLayerVisibility(AnnotationLevel.private);
      expect(_state(c).layerVisibility.privat, isFalse);
    });

    test('Stimme ausblenden', () {
      final (c, n) = _setup(null);
      n.toggleLayerVisibility(AnnotationLevel.voice);
      expect(_state(c).layerVisibility.stimme, isFalse);
    });

    test('Orchester ausblenden', () {
      final (c, n) = _setup(null);
      n.toggleLayerVisibility(AnnotationLevel.orchestra);
      expect(_state(c).layerVisibility.orchester, isFalse);
    });

    test('Doppeltes Toggle → wieder sichtbar', () {
      final (c, n) = _setup(null);
      n.toggleLayerVisibility(AnnotationLevel.private);
      n.toggleLayerVisibility(AnnotationLevel.private);
      expect(_state(c).layerVisibility.privat, isTrue);
    });

    test('Ausgeblendete Ebene erscheint nicht in visibleAnnotations', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'priv', level: AnnotationLevel.private));
      n.addAnnotation(_annotation(id: 'orch', level: AnnotationLevel.orchestra));

      n.toggleLayerVisibility(AnnotationLevel.private);

      final visible = _state(c).visibleAnnotations;
      expect(visible.any((a) => a.id == 'priv'), isFalse);
      expect(visible.any((a) => a.id == 'orch'), isTrue);
    });

    test('setLayerVisibility setzt alle Ebenen gleichzeitig', () {
      final (c, n) = _setup(null);
      n.setLayerVisibility(
        const LayerVisibility(privat: false, stimme: false, orchester: false),
      );
      expect(_state(c).layerVisibility.privat, isFalse);
      expect(_state(c).layerVisibility.stimme, isFalse);
      expect(_state(c).layerVisibility.orchester, isFalse);
    });
  });

  // ─── Seiten-Filter ───────────────────────────────────────────────────────

  group('visibleAnnotations — Seiten-Filterung', () {
    test('Nur annotations der aktuellen Seite sind sichtbar', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'p0', pageIndex: 0));
      n.addAnnotation(_annotation(id: 'p1', pageIndex: 1));

      expect(_state(c).visibleAnnotations.length, 1);
      expect(_state(c).visibleAnnotations.first.id, 'p0');
    });

    test('setPage wechselt sichtbare annotations', () {
      final (c, n) = _setup(null);
      n.addAnnotation(_annotation(id: 'p0', pageIndex: 0));
      n.addAnnotation(_annotation(id: 'p1', pageIndex: 1));

      n.setPage(1);
      expect(_state(c).visibleAnnotations.length, 1);
      expect(_state(c).visibleAnnotations.first.id, 'p1');
    });
  });

  // ─── commitStroke ─────────────────────────────────────────────────────────

  group('commitStroke — Freihand-Strich committen', () {
    test('Leere Punkte → keine Annotation', () {
      final (c, n) = _setup(null);
      n.commitStroke(
        points: [],
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        strokeWidth: 3.0,
        opacity: 1.0,
      );
      expect(_state(c).annotations, isEmpty);
    });

    test('Punkte mit Druckwert 0.0 werden akzeptiert', () {
      final (c, n) = _setup(null);
      n.commitStroke(
        points: [
          const StrokePoint(x: 0.1, y: 0.1, pressure: 0.0),
          const StrokePoint(x: 0.2, y: 0.2, pressure: 0.0),
        ],
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        strokeWidth: 3.0,
        opacity: 1.0,
      );
      expect(_state(c).annotations.length, 1);
    });

    test('Punkte mit Druckwert 1.0 werden akzeptiert', () {
      final (c, n) = _setup(null);
      n.commitStroke(
        points: [
          const StrokePoint(x: 0.1, y: 0.1, pressure: 1.0),
          const StrokePoint(x: 0.2, y: 0.2, pressure: 1.0),
        ],
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        strokeWidth: 3.0,
        opacity: 1.0,
      );
      expect(_state(c).annotations.length, 1);
    });

    test('BBox wird automatisch aus Punkten berechnet', () {
      final (c, n) = _setup(null);
      n.commitStroke(
        points: [
          const StrokePoint(x: 0.1, y: 0.1),
          const StrokePoint(x: 0.9, y: 0.9),
        ],
        level: AnnotationLevel.voice,
        tool: AnnotationTool.pencil,
        strokeWidth: 3.0,
        opacity: 1.0,
      );
      final bbox = _state(c).annotations.first.bbox;
      expect(bbox.x, closeTo(0.1, 1e-9));
      expect(bbox.y, closeTo(0.1, 1e-9));
      expect(bbox.width, closeTo(0.8, 1e-9));
      expect(bbox.height, closeTo(0.8, 1e-9));
    });
  });

  // ─── addTextAnnotation ────────────────────────────────────────────────────

  group('addTextAnnotation — Text-Annotation', () {
    test('Leerer Text → keine Annotation', () {
      final (c, n) = _setup(null);
      n.addTextAnnotation(
        text: '',
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations, isEmpty);
    });

    test('Text > 200 Zeichen wird auf 200 gekürzt', () {
      final (c, n) = _setup(null);
      final longText = 'A' * 250;
      n.addTextAnnotation(
        text: longText,
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations.first.text!.length, 200);
    });

    test('Text mit genau 200 Zeichen bleibt unverändert', () {
      final (c, n) = _setup(null);
      final text200 = 'B' * 200;
      n.addTextAnnotation(
        text: text200,
        x: 0.5,
        y: 0.5,
        level: AnnotationLevel.private,
      );
      expect(_state(c).annotations.first.text!.length, 200);
    });

    test('Normaler Text wird gespeichert', () {
      final (c, n) = _setup(null);
      n.addTextAnnotation(
        text: 'Atemzeichen',
        x: 0.3,
        y: 0.4,
        level: AnnotationLevel.voice,
      );
      expect(_state(c).annotations.first.text, 'Atemzeichen');
    });
  });

  // ─── Provider (family) ────────────────────────────────────────────────────

  group('annotationProvider — family-Scoping', () {
    test('Verschiedene pieceId-Scopes sind unabhängig', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(annotationProvider('stuck-1').notifier)
          .addAnnotation(_annotation(id: 'a1'));

      expect(container.read(annotationProvider('stuck-1')).annotations.length, 1);
      expect(container.read(annotationProvider('stuck-2')).annotations.length, 0);
    });
  });
}
