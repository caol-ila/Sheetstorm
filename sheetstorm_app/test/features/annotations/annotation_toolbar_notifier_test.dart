import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/application/annotation_toolbar_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

(ProviderContainer, AnnotationToolbarNotifier) _setup() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return (container, container.read(annotationToolbarProvider.notifier));
}

AnnotationToolbarState _state(ProviderContainer c) =>
    c.read(annotationToolbarProvider);

void main() {
  // ─── Tool-Auswahl ─────────────────────────────────────────────────────────

  group('selectTool — Werkzeugauswahl', () {
    test('Standard-Werkzeug ist Stift', () {
      final (c, _) = _setup();
      expect(_state(c).activeTool, AnnotationTool.pencil);
    });

    test('selectTool(text) → activeTool = text', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.text);
      expect(_state(c).activeTool, AnnotationTool.text);
    });

    test('selectTool(highlighter) → activeTool = highlighter', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.highlighter);
      expect(_state(c).activeTool, AnnotationTool.highlighter);
    });

    test('selectTool(eraser) → activeTool = eraser', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.eraser);
      expect(_state(c).activeTool, AnnotationTool.eraser);
    });

    test('selectTool(stamp) → Stamp-Picker öffnet sich', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.stamp);
      expect(_state(c).activeTool, AnnotationTool.stamp);
      expect(_state(c).isStampPickerOpen, isTrue);
    });

    test('selectTool(nicht-stamp) → Stamp-Picker bleibt geschlossen', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.stamp); // öffnen
      n.selectTool(AnnotationTool.pencil); // wechseln
      expect(_state(c).isStampPickerOpen, isFalse);
    });

    test('previousTool wird gesetzt beim Werkzeugwechsel', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.text);
      n.selectTool(AnnotationTool.eraser);
      expect(_state(c).previousTool, AnnotationTool.text);
    });
  });

  // ─── Ebenen-Auswahl ───────────────────────────────────────────────────────

  group('selectLevel — Ebenenauswahl', () {
    test('Standard-Ebene ist Privat', () {
      final (c, _) = _setup();
      expect(_state(c).activeLevel, AnnotationLevel.private);
    });

    test('selectLevel(stimme) → activeLevel = stimme', () {
      final (c, n) = _setup();
      n.selectLevel(AnnotationLevel.voice);
      expect(_state(c).activeLevel, AnnotationLevel.voice);
    });

    test('selectLevel(orchester) → activeLevel = orchester', () {
      final (c, n) = _setup();
      n.selectLevel(AnnotationLevel.orchestra);
      expect(_state(c).activeLevel, AnnotationLevel.orchestra);
    });
  });

  // ─── Textmarker ───────────────────────────────────────────────────────────

  group('effectiveOpacity — Textmarker automatisch 40%', () {
    test('Textmarker → effectiveOpacity = 0.4', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.highlighter);
      expect(_state(c).effectiveOpacity, closeTo(0.4, 1e-9));
    });

    test('Stift → effectiveOpacity = opacity-Wert (default 1.0)', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.pencil);
      expect(_state(c).effectiveOpacity, closeTo(1.0, 1e-9));
    });

    test('Textmarker → effectiveStrokeWidth = 4× Dicke', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.highlighter);
      n.setStrokeThickness(StrokeThickness.normal); // 3.0
      expect(_state(c).effectiveStrokeWidth, closeTo(12.0, 1e-9));
    });
  });

  // ─── Strich-Dicke & Opazität ──────────────────────────────────────────────

  group('setStrokeThickness / setOpacity', () {
    test('setStrokeThickness setzt Dicke', () {
      final (c, n) = _setup();
      n.setStrokeThickness(StrokeThickness.thick);
      expect(_state(c).strokeThickness, StrokeThickness.thick);
    });

    test('setOpacity klemmt auf [0, 1]', () {
      final (c, n) = _setup();
      n.setOpacity(1.5);
      expect(_state(c).opacity, closeTo(1.0, 1e-9));
    });

    test('setOpacity(negativ) klemmt auf 0.0', () {
      final (c, n) = _setup();
      n.setOpacity(-0.5);
      expect(_state(c).opacity, closeTo(0.0, 1e-9));
    });

    test('setOpacity(0.7) wird korrekt gesetzt', () {
      final (c, n) = _setup();
      n.setOpacity(0.7);
      expect(_state(c).opacity, closeTo(0.7, 1e-9));
    });
  });

  // ─── Apple Pencil Toggle ──────────────────────────────────────────────────

  group('toggleEraser — Apple Pencil Doppeltipp', () {
    test('Stift → toggleEraser → Radierer', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.pencil);
      n.toggleEraser();
      expect(_state(c).activeTool, AnnotationTool.eraser);
    });

    test('Radierer → toggleEraser → vorheriges Werkzeug', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.text);
      n.toggleEraser(); // → eraser, previous = text
      n.toggleEraser(); // → text
      expect(_state(c).activeTool, AnnotationTool.text);
    });

    test('Kein previousTool → toggleEraser zurück zu Stift', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.eraser);
      // previousTool wurde durch selectTool auf pencil gesetzt
      n.toggleEraser();
      expect(_state(c).activeTool, AnnotationTool.pencil);
    });
  });

  // ─── Stempel-Picker ───────────────────────────────────────────────────────

  group('StampPicker — Kategorie & Auswahl', () {
    test('selectStamp setzt Kategorie und Wert', () {
      final (c, n) = _setup();
      n.selectStamp('atem', 'einatmen');
      expect(_state(c).selectedStampCategory, 'atem');
      expect(_state(c).selectedStampValue, 'einatmen');
    });

    test('selectStamp schließt Stamp-Picker', () {
      final (c, n) = _setup();
      n.selectTool(AnnotationTool.stamp); // öffnet picker
      n.selectStamp('dynamik', 'mf');
      expect(_state(c).isStampPickerOpen, isFalse);
    });

    test('toggleStampPicker schaltet um', () {
      final (c, n) = _setup();
      expect(_state(c).isStampPickerOpen, isFalse);
      n.toggleStampPicker();
      expect(_state(c).isStampPickerOpen, isTrue);
      n.toggleStampPicker();
      expect(_state(c).isStampPickerOpen, isFalse);
    });

    test('closeStampPicker schließt Picker', () {
      final (c, n) = _setup();
      n.toggleStampPicker();
      n.closeStampPicker();
      expect(_state(c).isStampPickerOpen, isFalse);
    });
  });

  // ─── Toolbar Visibility ───────────────────────────────────────────────────

  group('showToolbar / hideToolbar', () {
    test('Default: Toolbar sichtbar', () {
      final (c, _) = _setup();
      expect(_state(c).isToolbarVisible, isTrue);
    });

    test('hideToolbar → nicht sichtbar', () {
      final (c, n) = _setup();
      n.hideToolbar();
      expect(_state(c).isToolbarVisible, isFalse);
    });

    test('showToolbar → sichtbar', () {
      final (c, n) = _setup();
      n.hideToolbar();
      n.showToolbar();
      expect(_state(c).isToolbarVisible, isTrue);
    });
  });

  // ─── Dock-Position ────────────────────────────────────────────────────────

  group('setDockPosition', () {
    test('Default ist bottom', () {
      final (c, _) = _setup();
      expect(_state(c).toolbarDockPosition, ToolbarDock.bottom);
    });

    test('setDockPosition(left)', () {
      final (c, n) = _setup();
      n.setDockPosition(ToolbarDock.left);
      expect(_state(c).toolbarDockPosition, ToolbarDock.left);
    });
  });
}
