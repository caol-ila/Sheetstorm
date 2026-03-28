import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotationen/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotationen/presentation/widgets/level_picker.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Annotation _annot({
  String id = 'test',
  AnnotationLevel level = AnnotationLevel.privat,
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
        StrokePoint(x: 0.3, y: 0.3),
      ],
    );

(ProviderContainer, AnnotationNotifier) _setup() {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  return (c, c.read(annotationProvider('test').notifier));
}

AnnotationState _state(ProviderContainer c) => c.read(annotationProvider('test'));

void main() {
  // ─── Dirigent-Berechtigung ─────────────────────────────────────────────────

  group('Berechtigungen — Dirigent vs. Nicht-Dirigent', () {
    /// Im Datenmodell gibt es keine serverseitige Rollenprüfung im Notifier,
    /// aber die Berechtigungs-Logik steckt im LevelPicker-Widget:
    /// isDirigent: false → Orchester-Option ist gesperrt (onTap = null).
    ///
    /// Der AnnotationNotifier selbst kennt keine Rollen — die Rolle
    /// wird durch das UI erzwungen. Tests prüfen das UI-Gate.

    testWidgets(
      'Nicht-Dirigent: Orchester-ListTile hat keinen onTap (gesperrt)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelPicker(
                currentLevel: AnnotationLevel.privat,
                isDirigent: false,
              ),
            ),
          ),
        );

        // Orchester-Eintrag zeigt "nur Dirigent" als Untertitel
        expect(find.text('nur Dirigent'), findsOneWidget);

        // Schloss-Icon ist sichtbar
        expect(find.byIcon(Icons.lock), findsOneWidget);
      },
    );

    testWidgets(
      'Dirigent: Orchester-ListTile hat keinen Sperr-Hinweis',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelPicker(
                currentLevel: AnnotationLevel.privat,
                isDirigent: true,
              ),
            ),
          ),
        );

        expect(find.text('alle Kapellenmitglieder'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsNothing);
      },
    );

    testWidgets(
      'Nicht-Dirigent: Tap auf Orchester hat keine Auswirkung (kein Pop)',
      (tester) async {
        AnnotationLevel? selected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    selected = await showDialog<AnnotationLevel>(
                      context: ctx,
                      builder: (_) => const LevelPicker(
                        currentLevel: AnnotationLevel.privat,
                        isDirigent: false,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Tap auf Orchester-Eintrag
        await tester.tap(find.text('Orchester'));
        await tester.pumpAndSettle();

        // Dialog bleibt offen (kein Navigator.pop mit Level)
        expect(selected, isNull);
      },
    );

    testWidgets(
      'Dirigent: Tap auf Orchester gibt AnnotationLevel.orchester zurück',
      (tester) async {
        AnnotationLevel? selected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    selected = await showDialog<AnnotationLevel>(
                      context: ctx,
                      builder: (_) => const LevelPicker(
                        currentLevel: AnnotationLevel.privat,
                        isDirigent: true,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Orchester'));
        await tester.pumpAndSettle();

        expect(selected, AnnotationLevel.orchester);
      },
    );
  });

  // ─── Jeder kann Privat-Annotationen erstellen ─────────────────────────────

  group('Privat-Ebene — für alle zugänglich', () {
    test('Notifier akzeptiert Privat-Annotation ohne Rollenbeschränkung', () {
      final (c, n) = _setup();
      n.addAnnotation(_annot(level: AnnotationLevel.privat));
      expect(_state(c).annotations.length, 1);
      expect(_state(c).annotations.first.level, AnnotationLevel.privat);
    });

    testWidgets(
      'LevelPicker: Privat-Eintrag hat kein Schloss (nicht-Dirigent)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelPicker(
                currentLevel: AnnotationLevel.privat,
                isDirigent: false,
              ),
            ),
          ),
        );

        // Nur 1 Lock-Icon (für Orchester), Privat und Stimme haben keins
        expect(find.byIcon(Icons.lock), findsOneWidget);
        expect(find.text('Privat'), findsOneWidget);
      },
    );

    testWidgets(
      'LevelPicker: Tap auf Privat gibt AnnotationLevel.privat zurück',
      (tester) async {
        AnnotationLevel? selected;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () async {
                    selected = await showDialog<AnnotationLevel>(
                      context: ctx,
                      builder: (_) => const LevelPicker(
                        currentLevel: AnnotationLevel.stimme,
                        isDirigent: false,
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Privat'));
        await tester.pumpAndSettle();

        expect(selected, AnnotationLevel.privat);
      },
    );
  });

  // ─── Stimme-Sichtbarkeit (Layer-Toggle) ───────────────────────────────────

  group('Stimme-Ebene — Layer-Toggle Sichtbarkeit', () {
    test('Stimme-Annotationen sind nur sichtbar wenn Stimme-Layer an', () {
      final (c, n) = _setup();
      n.addAnnotation(_annot(id: 'stimme-1', level: AnnotationLevel.stimme));

      expect(
        _state(c).visibleAnnotations.any((a) => a.id == 'stimme-1'),
        isTrue,
      );

      // Stimme-Layer ausblenden
      n.toggleLayerVisibility(AnnotationLevel.stimme);

      expect(
        _state(c).visibleAnnotations.any((a) => a.id == 'stimme-1'),
        isFalse,
      );
    });

    test('Stimme ausblenden lässt Privat und Orchester weiterhin sichtbar', () {
      final (c, n) = _setup();
      n.addAnnotation(_annot(id: 'priv', level: AnnotationLevel.privat));
      n.addAnnotation(_annot(id: 'stim', level: AnnotationLevel.stimme));
      n.addAnnotation(_annot(id: 'orch', level: AnnotationLevel.orchester));

      n.toggleLayerVisibility(AnnotationLevel.stimme);

      final visible = _state(c).visibleAnnotations;
      expect(visible.any((a) => a.id == 'priv'), isTrue);
      expect(visible.any((a) => a.id == 'stim'), isFalse);
      expect(visible.any((a) => a.id == 'orch'), isTrue);
    });
  });

  // ─── Orchester — Löschen nur für Dirigent ────────────────────────────────

  group('Orchester-Annotation — Lösch-Schutz via UI', () {
    test(
      'Notifier erlaubt Löschen technisch (Schutz ist UI-seitig)',
      () {
        // Der Notifier selbst hat keine Rollenbeschränkung.
        // Der Lösch-Schutz für Orchester wird in der Presentation-Layer
        // durch Sichtbarkeit/Disabled-State erzwungen (Spec US-03 AK7).
        final (c, n) = _setup();
        n.addAnnotation(_annot(id: 'orch', level: AnnotationLevel.orchester));
        n.removeAnnotation('orch');
        expect(_state(c).annotations, isEmpty);
      },
    );

    testWidgets(
      'LevelPicker: Stimme hat kein Schloss-Icon (auch nicht-Dirigent)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LevelPicker(
                currentLevel: AnnotationLevel.privat,
                isDirigent: false,
                stimmeName: 'Klarinette 1',
              ),
            ),
          ),
        );

        expect(find.text('Klarinette 1'), findsOneWidget);
        // Nur Orchester ist gesperrt — genau 1 Lock-Icon
        expect(find.byIcon(Icons.lock), findsOneWidget);
      },
    );
  });
}
