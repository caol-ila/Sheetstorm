import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';

void main() {
  // ─── AnnotationLevel ──────────────────────────────────────────────────────

  group('AnnotationLevel — Farb-Kodierung (Spec §1: Farbe = Reichweite)', () {
    test('Privat → Blau (#3B82F6)', () {
      expect(
        AnnotationLevel.private.color.value,
        equals(AppColors.annotationPrivate.value),
      );
      expect(
        AnnotationLevel.private.color.value,
        equals(const Color(0xFF3B82F6).value),
      );
    });

    test('Stimme → Grün (#22C55E)', () {
      expect(
        AnnotationLevel.voice.color.value,
        equals(AppColors.annotationVoice.value),
      );
      expect(
        AnnotationLevel.voice.color.value,
        equals(const Color(0xFF22C55E).value),
      );
    });

    test('Orchester → Orange (#F97316)', () {
      expect(
        AnnotationLevel.orchestra.color.value,
        equals(AppColors.annotationOrchestra.value),
      );
      expect(
        AnnotationLevel.orchestra.color.value,
        equals(const Color(0xFFF97316).value),
      );
    });

    test('Labels sind korrekt deutsch', () {
      expect(AnnotationLevel.private.label, 'Privat');
      expect(AnnotationLevel.voice.label, 'Stimme');
      expect(AnnotationLevel.orchestra.label, 'Orchester');
    });

    test('Beschreibungen decken Reichweite ab', () {
      expect(AnnotationLevel.private.description, contains('mich'));
      expect(AnnotationLevel.voice.description, contains('Stimme'));
      expect(AnnotationLevel.orchestra.description, contains('Kapellenmitglieder'));
    });

    test('Alle 3 Ebenen haben einen iconChar', () {
      for (final level in AnnotationLevel.values) {
        expect(level.iconChar.isNotEmpty, isTrue);
      }
    });
  });

  // ─── BBox ─────────────────────────────────────────────────────────────────

  group('BBox — Relative Koordinaten', () {
    test('Konstruktor setzt alle Felder korrekt', () {
      const bbox = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      expect(bbox.x, 0.1);
      expect(bbox.y, 0.2);
      expect(bbox.width, 0.3);
      expect(bbox.height, 0.4);
    });

    test('copyWith überschreibt nur angegebene Felder', () {
      const original = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      final copy = original.copyWith(x: 0.9);
      expect(copy.x, 0.9);
      expect(copy.y, 0.2);
      expect(copy.width, 0.3);
      expect(copy.height, 0.4);
    });

    test('Gleichheit per value equality', () {
      const a = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const b = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      expect(a, equals(b));
    });

    test('Ungleichheit bei unterschiedlichen Werten', () {
      const a = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const b = BBox(x: 0.9, y: 0.2, width: 0.3, height: 0.4);
      expect(a, isNot(equals(b)));
    });

    test('hashCode ist konsistent für gleiche BBox', () {
      const a = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      const b = BBox(x: 0.1, y: 0.2, width: 0.3, height: 0.4);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ─── Annotation.computeBBox ──────────────────────────────────────────────

  group('Annotation.computeBBox — BBox-Berechnung aus Punkten', () {
    test('Leere Punkte → Null-BBox', () {
      final bbox = Annotation.computeBBox([]);
      expect(bbox, equals(const BBox(x: 0, y: 0, width: 0, height: 0)));
    });

    test('Einzelner Punkt → Null-Größe BBox an Punkt-Position', () {
      final bbox = Annotation.computeBBox([
        const StrokePoint(x: 0.5, y: 0.3),
      ]);
      expect(bbox.x, 0.5);
      expect(bbox.y, 0.3);
      expect(bbox.width, 0.0);
      expect(bbox.height, 0.0);
    });

    test('Mehrere Punkte → korrekte Min/Max-BBox', () {
      final points = [
        const StrokePoint(x: 0.1, y: 0.4),
        const StrokePoint(x: 0.8, y: 0.1),
        const StrokePoint(x: 0.3, y: 0.7),
        const StrokePoint(x: 0.6, y: 0.2),
      ];
      final bbox = Annotation.computeBBox(points);
      expect(bbox.x, closeTo(0.1, 1e-9));
      expect(bbox.y, closeTo(0.1, 1e-9));
      expect(bbox.width, closeTo(0.7, 1e-9));   // 0.8 - 0.1
      expect(bbox.height, closeTo(0.6, 1e-9));  // 0.7 - 0.1
    });

    test('Identische Punkte → Null-Größe BBox', () {
      final points = List.filled(5, const StrokePoint(x: 0.5, y: 0.5));
      final bbox = Annotation.computeBBox(points);
      expect(bbox.width, 0.0);
      expect(bbox.height, 0.0);
    });

    test('Punkte an den Rändern (0.0 und 1.0)', () {
      final bbox = Annotation.computeBBox([
        const StrokePoint(x: 0.0, y: 0.0),
        const StrokePoint(x: 1.0, y: 1.0),
      ]);
      expect(bbox.x, 0.0);
      expect(bbox.y, 0.0);
      expect(bbox.width, closeTo(1.0, 1e-9));
      expect(bbox.height, closeTo(1.0, 1e-9));
    });
  });

  // ─── Annotation.svgPath ───────────────────────────────────────────────────

  group('Annotation.svgPath — SVG-Pfad Serialisierung', () {
    Annotation _makeAnnotation(List<StrokePoint> points) => Annotation(
          id: 'test_id',
          level: AnnotationLevel.private,
          tool: AnnotationTool.pencil,
          pageIndex: 0,
          bbox: const BBox(x: 0, y: 0, width: 0.1, height: 0.1),
          createdAt: DateTime(2026, 1, 1),
          points: points,
        );

    test('Leere Punkte → leerer SVG-Pfad', () {
      expect(_makeAnnotation([]).svgPath, '');
    });

    test('Einzelner Punkt → MoveTo ohne LineTo', () {
      final path = _makeAnnotation([
        const StrokePoint(x: 0.25, y: 0.5),
      ]).svgPath;
      expect(path, startsWith('M'));
      expect(path, isNot(contains('L')));
    });

    test('Zwei Punkte → M dann L Segment', () {
      final path = _makeAnnotation([
        const StrokePoint(x: 0.1, y: 0.2),
        const StrokePoint(x: 0.3, y: 0.4),
      ]).svgPath;
      expect(path, startsWith('M0.1000,0.2000'));
      expect(path, contains('L0.3000,0.4000'));
    });

    test('Drei Punkte → M und zwei L-Segmente', () {
      final path = _makeAnnotation([
        const StrokePoint(x: 0.0, y: 0.0),
        const StrokePoint(x: 0.5, y: 0.5),
        const StrokePoint(x: 1.0, y: 1.0),
      ]).svgPath;
      expect(path, startsWith('M'));
      expect('L'.allMatches(path).length, equals(2));
    });

    test('Koordinaten werden auf 4 Dezimalstellen formatiert', () {
      final path = _makeAnnotation([
        const StrokePoint(x: 1 / 3, y: 2 / 3),
        const StrokePoint(x: 0.5, y: 0.5),
      ]).svgPath;
      // 1/3 ≈ 0.3333
      expect(path, contains('0.3333'));
    });
  });

  // ─── StrokePoint ──────────────────────────────────────────────────────────

  group('StrokePoint — Druckwerte', () {
    test('Default-Druck ist 0.5', () {
      const p = StrokePoint(x: 0.5, y: 0.5);
      expect(p.pressure, 0.5);
    });

    test('Druck 0.0 ist gültig', () {
      const p = StrokePoint(x: 0.5, y: 0.5, pressure: 0.0);
      expect(p.pressure, 0.0);
    });

    test('Druck 1.0 ist gültig', () {
      const p = StrokePoint(x: 0.5, y: 0.5, pressure: 1.0);
      expect(p.pressure, 1.0);
    });

    test('Gleichheit per value equality', () {
      const a = StrokePoint(x: 0.1, y: 0.2, pressure: 0.8);
      const b = StrokePoint(x: 0.1, y: 0.2, pressure: 0.8);
      expect(a, equals(b));
    });
  });

  // ─── LayerVisibility ──────────────────────────────────────────────────────

  group('LayerVisibility — Layer-Toggle', () {
    test('Default: alle Ebenen sichtbar', () {
      const vis = LayerVisibility();
      expect(vis.isVisible(AnnotationLevel.private), isTrue);
      expect(vis.isVisible(AnnotationLevel.voice), isTrue);
      expect(vis.isVisible(AnnotationLevel.orchestra), isTrue);
    });

    test('toggle(privat) schaltet nur Privat um', () {
      const vis = LayerVisibility();
      final toggled = vis.toggle(AnnotationLevel.private);
      expect(toggled.isPrivate, isFalse);
      expect(toggled.isVoice, isTrue);
      expect(toggled.isOrchestra, isTrue);
    });

    test('toggle(stimme) schaltet nur Stimme um', () {
      const vis = LayerVisibility();
      final toggled = vis.toggle(AnnotationLevel.voice);
      expect(toggled.isPrivate, isTrue);
      expect(toggled.isVoice, isFalse);
      expect(toggled.isOrchestra, isTrue);
    });

    test('toggle(orchester) schaltet nur Orchester um', () {
      const vis = LayerVisibility();
      final toggled = vis.toggle(AnnotationLevel.orchestra);
      expect(toggled.isPrivate, isTrue);
      expect(toggled.isVoice, isTrue);
      expect(toggled.isOrchestra, isFalse);
    });

    test('Doppeltes toggle = Ausgangszustand', () {
      const vis = LayerVisibility();
      final result = vis
          .toggle(AnnotationLevel.private)
          .toggle(AnnotationLevel.private);
      expect(result, equals(vis));
    });

    test('isVisible respektiert false-Werte', () {
      const vis = LayerVisibility(isPrivate: false, isVoice: true, isOrchestra: false);
      expect(vis.isVisible(AnnotationLevel.private), isFalse);
      expect(vis.isVisible(AnnotationLevel.voice), isTrue);
      expect(vis.isVisible(AnnotationLevel.orchestra), isFalse);
    });

    test('Gleichheit per value equality', () {
      const a = LayerVisibility(isPrivate: true, isVoice: false, isOrchestra: true);
      const b = LayerVisibility(isPrivate: true, isVoice: false, isOrchestra: true);
      expect(a, equals(b));
    });
  });

  // ─── Annotation ───────────────────────────────────────────────────────────

  group('Annotation — Gleichheit per ID', () {
    test('Gleichheit basiert auf ID, nicht auf Inhalt', () {
      final a = Annotation(
        id: 'abc',
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        pageIndex: 0,
        bbox: const BBox(x: 0, y: 0, width: 0.1, height: 0.1),
        createdAt: DateTime(2026, 1, 1),
      );
      final b = a.copyWith(level: AnnotationLevel.orchestra);
      expect(a, equals(b)); // gleiche ID
    });

    test('Ungleichheit bei unterschiedlicher ID', () {
      final t = DateTime(2026);
      final bbox = const BBox(x: 0, y: 0, width: 0.1, height: 0.1);
      final a = Annotation(
        id: 'id-1',
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        pageIndex: 0,
        bbox: bbox,
        createdAt: t,
      );
      final b = Annotation(
        id: 'id-2',
        level: AnnotationLevel.private,
        tool: AnnotationTool.pencil,
        pageIndex: 0,
        bbox: bbox,
        createdAt: t,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
