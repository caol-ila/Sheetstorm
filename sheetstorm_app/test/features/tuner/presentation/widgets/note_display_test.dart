import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';
import 'package:sheetstorm/features/tuner/presentation/widgets/note_display.dart';

Widget _buildDisplay(TunerNote? note) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: NoteDisplay(note: note)),
    ),
  );
}

void main() {
  group('NoteDisplay — kein Ton erkannt', () {
    testWidgets('zeigt "—" wenn kein Ton', (tester) async {
      await tester.pumpWidget(_buildDisplay(null));
      expect(tester.takeException(), isNull);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('rendert ohne Fehler bei null', (tester) async {
      await tester.pumpWidget(_buildDisplay(null));
      expect(tester.takeException(), isNull);
      expect(find.byType(NoteDisplay), findsOneWidget);
    });
  });

  group('NoteDisplay — Ton anzeigen', () {
    testWidgets('zeigt Tonname A4', (tester) async {
      const note = TunerNote(name: 'A', octave: 4, frequency: 440.0);
      await tester.pumpWidget(_buildDisplay(note));
      expect(tester.takeException(), isNull);
      // Note name and octave should appear somewhere
      expect(find.textContaining('A'), findsWidgets);
      expect(find.textContaining('4'), findsWidgets);
    });

    testWidgets('zeigt Tonname C#3', (tester) async {
      const note = TunerNote(name: 'C#', octave: 3, frequency: 138.59);
      await tester.pumpWidget(_buildDisplay(note));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('C#'), findsOneWidget);
    });

    testWidgets('zeigt Bb4', (tester) async {
      const note = TunerNote(name: 'A#', octave: 4, frequency: 466.16);
      await tester.pumpWidget(_buildDisplay(note));
      expect(tester.takeException(), isNull);
    });

    testWidgets('zeigt Frequenz in Hz', (tester) async {
      const note = TunerNote(name: 'A', octave: 4, frequency: 440.0);
      await tester.pumpWidget(_buildDisplay(note));
      expect(find.textContaining('440'), findsWidgets);
    });
  });

  group('NoteDisplay — Semantik', () {
    testWidgets('hat Semantics für Barrierefreiheit', (tester) async {
      const note = TunerNote(name: 'A', octave: 4, frequency: 440.0);
      await tester.pumpWidget(_buildDisplay(note));
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('NoteDisplay — Schriftgröße', () {
    testWidgets('Tonname hat große Schriftgröße (≥ 72sp)', (tester) async {
      const note = TunerNote(name: 'A', octave: 4, frequency: 440.0);
      await tester.pumpWidget(_buildDisplay(note));
      // Find the Text widgets and check for large font
      final texts = tester.widgetList<Text>(find.byType(Text));
      final hasLargeText = texts.any((t) =>
          t.style?.fontSize != null && t.style!.fontSize! >= 72.0);
      expect(hasLargeText, isTrue);
    });
  });
}
