import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/application/annotation_toolbar_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotations/presentation/painters/annotation_painter.dart';
import 'package:sheetstorm/features/annotations/presentation/painters/drawing_painter.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/annotation_toolbar.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/level_picker.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/stamp_picker.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Annotation _annot({
  String id = 'test',
  AnnotationLevel level = AnnotationLevel.private,
  AnnotationTool tool = AnnotationTool.pencil,
  List<StrokePoint> points = const [
    StrokePoint(x: 0.1, y: 0.1),
    StrokePoint(x: 0.3, y: 0.3),
    StrokePoint(x: 0.5, y: 0.2),
  ],
  String? text,
  String? stampValue,
  String? stampCategory,
}) =>
    Annotation(
      id: id,
      level: level,
      tool: tool,
      pageIndex: 0,
      bbox: const BBox(x: 0.1, y: 0.1, width: 0.2, height: 0.1),
      createdAt: DateTime(2026, 1, 1),
      points: points,
      text: text,
      stampValue: stampValue,
      stampCategory: stampCategory,
    );

/// Renders a [CustomPainter] onto a 400×600 canvas and returns the recorder.
///
/// Useful for smoke-testing that painters don't throw during paint().
void _paintOnCanvas(CustomPainter painter) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, const Size(400, 600));
  recorder.endRecording();
}

void main() {
  // ─── AnnotationPainter ────────────────────────────────────────────────────

  group('AnnotationPainter — gespeicherte annotations rendern', () {
    test('paint() läuft fehlerfrei mit leerer Annotations-Liste', () {
      final painter = AnnotationPainter(
        annotations: const [],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() läuft fehlerfrei mit Stift-Annotation', () {
      final painter = AnnotationPainter(
        annotations: [_annot(level: AnnotationLevel.private)],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() läuft fehlerfrei mit Text-Annotation', () {
      final painter = AnnotationPainter(
        annotations: [
          _annot(
            level: AnnotationLevel.voice,
            tool: AnnotationTool.text,
            points: [],
            text: 'Forte spielen!',
          )
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() läuft fehlerfrei mit Stempel-Annotation', () {
      final painter = AnnotationPainter(
        annotations: [
          _annot(
            level: AnnotationLevel.orchestra,
            tool: AnnotationTool.stamp,
            points: [],
            stampCategory: 'dynamik',
            stampValue: 'ff',
          )
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit allen 3 Ebenen gleichzeitig', () {
      final painter = AnnotationPainter(
        annotations: [
          _annot(id: 'p', level: AnnotationLevel.private),
          _annot(id: 's', level: AnnotationLevel.voice),
          _annot(id: 'o', level: AnnotationLevel.orchestra),
        ],
        layerVisibility: const LayerVisibility(),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('shouldRepaint true wenn annotations geändert', () {
      final annotations = [_annot()];
      final a = AnnotationPainter(
        annotations: annotations,
        layerVisibility: const LayerVisibility(),
      );
      final b = AnnotationPainter(
        annotations: const [],
        layerVisibility: const LayerVisibility(),
      );
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint false wenn alles gleich', () {
      final annotations = [_annot()];
      final a = AnnotationPainter(
        annotations: annotations,
        layerVisibility: const LayerVisibility(),
      );
      final b = AnnotationPainter(
        annotations: annotations,
        layerVisibility: const LayerVisibility(),
      );
      expect(a.shouldRepaint(b), isFalse);
    });

    test('Ausgeblendete Ebene wird nicht gemalt (kein Fehler)', () {
      final painter = AnnotationPainter(
        annotations: [_annot(level: AnnotationLevel.private)],
        layerVisibility:
            const LayerVisibility(privat: false, stimme: true, orchester: true),
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });
  });

  // ─── DrawingPainter ───────────────────────────────────────────────────────

  group('DrawingPainter — aktiver Strich rendern', () {
    test('paint() mit leerer Punkt-Liste — kein Fehler', () {
      final painter = DrawingPainter(
        points: const [],
        color: AppColors.annotationPrivate,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit einem Punkt → Dot (kein Fehler)', () {
      final painter = DrawingPainter(
        points: const [StrokePoint(x: 0.5, y: 0.5, pressure: 0.8)],
        color: AppColors.annotationVoice,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit mehreren Punkten — Stift (kein Fehler)', () {
      final painter = DrawingPainter(
        points: const [
          StrokePoint(x: 0.1, y: 0.1, pressure: 0.5),
          StrokePoint(x: 0.3, y: 0.4, pressure: 0.8),
          StrokePoint(x: 0.6, y: 0.2, pressure: 1.0),
        ],
        color: AppColors.annotationOrchestra,
        strokeWidth: 5.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit Textmarker-Werkzeug — kein Fehler', () {
      final painter = DrawingPainter(
        points: const [
          StrokePoint(x: 0.1, y: 0.1),
          StrokePoint(x: 0.9, y: 0.1),
        ],
        color: AppColors.annotationVoice,
        strokeWidth: 12.0,
        opacity: 0.4,
        tool: AnnotationTool.highlighter,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit Radierer-Werkzeug — Cursor-Kreis (kein Fehler)', () {
      final painter = DrawingPainter(
        points: const [
          StrokePoint(x: 0.5, y: 0.5),
          StrokePoint(x: 0.6, y: 0.5),
        ],
        color: Colors.grey,
        strokeWidth: 20.0,
        opacity: 1.0,
        tool: AnnotationTool.eraser,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('paint() mit Druck 0.0 — kein Fehler', () {
      final painter = DrawingPainter(
        points: const [
          StrokePoint(x: 0.2, y: 0.2, pressure: 0.0),
          StrokePoint(x: 0.4, y: 0.4, pressure: 0.0),
        ],
        color: AppColors.annotationPrivate,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(() => _paintOnCanvas(painter), returnsNormally);
    });

    test('shouldRepaint immer true (Live-Drawing)', () {
      final p = DrawingPainter(
        points: const [],
        color: Colors.blue,
        strokeWidth: 3.0,
        opacity: 1.0,
        tool: AnnotationTool.pencil,
      );
      expect(p.shouldRepaint(p), isTrue);
    });
  });

  // ─── Farb-Kodierung ───────────────────────────────────────────────────────

  group('Farb-Kodierung (Spec §1: Farbe = Reichweite)', () {
    test('Privat-Annotation benutzt blaue Farbe', () {
      final annot = _annot(level: AnnotationLevel.private);
      expect(annot.level.color.value, equals(const Color(0xFF3B82F6).value));
    });

    test('Stimme-Annotation benutzt grüne Farbe', () {
      final annot = _annot(level: AnnotationLevel.voice);
      expect(annot.level.color.value, equals(const Color(0xFF22C55E).value));
    });

    test('Orchester-Annotation benutzt orange Farbe', () {
      final annot = _annot(level: AnnotationLevel.orchestra);
      expect(annot.level.color.value, equals(const Color(0xFFF97316).value));
    });

    test('Alle 3 Farben sind unterschiedlich', () {
      final colors = AnnotationLevel.values.map((l) => l.color.value).toSet();
      expect(colors.length, 3);
    });
  });

  // ─── AnnotationToolbar Widget ─────────────────────────────────────────────

  group('AnnotationToolbar — Werkzeugauswahl im Widget', () {
    testWidgets('Toolbar rendert alle Haupt-Werkzeuge', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationToolbar(pieceId: 'test-stuck'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Werkzeug-Icons sind vorhanden (Tooltip messages)
      expect(find.byTooltip('Stift'), findsOneWidget);
      expect(find.byTooltip('Text'), findsOneWidget);
      expect(find.byTooltip('Marker'), findsOneWidget);
      expect(find.byTooltip('Stempel'), findsOneWidget);
      expect(find.byTooltip('Radierer'), findsOneWidget);
    });

    testWidgets('Undo/Redo-Buttons sind vorhanden', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationToolbar(pieceId: 'test-stuck'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Undo'), findsOneWidget);
      expect(find.byTooltip('Redo'), findsOneWidget);
    });

    testWidgets('Fertig-Button ist vorhanden', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AnnotationToolbar(pieceId: 'test-stuck'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Fertig'), findsOneWidget);
    });
  });

  // ─── StampPicker Widget ───────────────────────────────────────────────────

  group('StampPicker — Stempel-Kategorien', () {
    testWidgets('Alle 4 Kategorien sind als Tabs sichtbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StampPicker(onStampSelected: (_, __) {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dynamik'), findsOneWidget);
      expect(find.text('Artikulation'), findsOneWidget);
      expect(find.text('Atemzeichen'), findsOneWidget);
      expect(find.text('Navigation'), findsOneWidget);
    });

    testWidgets('Dynamik-Tab zeigt mf-Stempel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StampPicker(onStampSelected: (_, __) {}),
          ),
        ),
      );
      await tester.pump();

      // mf display text is '𝆐𝆑'
      expect(find.text('𝆐𝆑'), findsOneWidget);
    });

    testWidgets('Stempel-Tap ruft Callback mit korrekten Werten auf',
        (tester) async {
      String? selectedCategory;
      String? selectedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StampPicker(
              onStampSelected: (cat, val) {
                selectedCategory = cat;
                selectedValue = val;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Tap first stamp in Dynamik tab (pp = '𝆏𝆏')
      await tester.tap(find.text('𝆏𝆏').first);
      await tester.pump();

      expect(selectedCategory, 'dynamik');
      expect(selectedValue, 'pp');
    });
  });

  // ─── LevelPicker Widget ───────────────────────────────────────────────────

  group('LevelPicker — Ebenen-Auswahl', () {
    testWidgets('Alle 3 Ebenen sind sichtbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelPicker(
              currentLevel: AnnotationLevel.private,
              isDirigent: true,
            ),
          ),
        ),
      );

      expect(find.text('Privat'), findsOneWidget);
      expect(find.text('Stimme'), findsOneWidget);
      expect(find.text('Orchester'), findsOneWidget);
    });

    testWidgets('Orchester zeigt Schloss-Icon für Nicht-Dirigenten',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelPicker(
              currentLevel: AnnotationLevel.private,
              isDirigent: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('Kein Schloss-Icon für Dirigenten', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelPicker(
              currentLevel: AnnotationLevel.private,
              isDirigent: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsNothing);
    });
  });
}
