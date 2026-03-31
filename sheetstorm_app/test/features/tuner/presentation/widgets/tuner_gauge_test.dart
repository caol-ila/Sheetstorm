import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/tuner/presentation/widgets/tuner_gauge.dart';

Widget _buildGauge(double centDeviation) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 200,
          child: TunerGauge(centDeviation: centDeviation),
        ),
      ),
    ),
  );
}

void main() {
  group('TunerGauge — rendert ohne Fehler', () {
    testWidgets('rendert bei 0 Cent (perfekt gestimmt)', (tester) async {
      await tester.pumpWidget(_buildGauge(0.0));
      expect(tester.takeException(), isNull);
      expect(find.byType(TunerGauge), findsOneWidget);
    });

    testWidgets('rendert bei +30 Cent (rot, zu hoch)', (tester) async {
      await tester.pumpWidget(_buildGauge(30.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert bei -30 Cent (rot, zu tief)', (tester) async {
      await tester.pumpWidget(_buildGauge(-30.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert bei +10 Cent (gelb, nah dran)', (tester) async {
      await tester.pumpWidget(_buildGauge(10.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert bei -10 Cent (gelb, nah dran)', (tester) async {
      await tester.pumpWidget(_buildGauge(-10.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert bei +50 Cent (Maximum)', (tester) async {
      await tester.pumpWidget(_buildGauge(50.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rendert bei -50 Cent (Minimum)', (tester) async {
      await tester.pumpWidget(_buildGauge(-50.0));
      expect(tester.takeException(), isNull);
    });
  });

  group('TunerGauge — Zonenfarben', () {
    testWidgets('hat grüne Farbe bei 0 Cent (±5 Cent Zone)', (tester) async {
      await tester.pumpWidget(_buildGauge(0.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _greenColor.toARGB32());
    });

    testWidgets('hat grüne Farbe bei 5 Cent (Grenze grüne Zone)',
        (tester) async {
      await tester.pumpWidget(_buildGauge(5.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _greenColor.toARGB32());
    });

    testWidgets('hat gelbe Farbe bei 10 Cent (gelbe Zone)', (tester) async {
      await tester.pumpWidget(_buildGauge(10.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _yellowColor.toARGB32());
    });

    testWidgets('hat gelbe Farbe bei 15 Cent (Grenze gelbe Zone)',
        (tester) async {
      await tester.pumpWidget(_buildGauge(15.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _yellowColor.toARGB32());
    });

    testWidgets('hat rote Farbe bei 20 Cent (rote Zone)', (tester) async {
      await tester.pumpWidget(_buildGauge(20.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _redColor.toARGB32());
    });

    testWidgets('hat rote Farbe bei -20 Cent (rote Zone)', (tester) async {
      await tester.pumpWidget(_buildGauge(-20.0));
      final gauge = tester.widget<TunerGauge>(find.byType(TunerGauge));
      expect(gauge.tuneColor.toARGB32(), _redColor.toARGB32());
    });
  });

  group('TunerGauge — Semantik', () {
    testWidgets('hat Semantics-Widget für Barrierefreiheit', (tester) async {
      await tester.pumpWidget(_buildGauge(0.0));
      expect(find.byType(Semantics), findsWidgets);
    });
  });

  group('TunerGauge — CustomPaint', () {
    testWidgets('enthält CustomPaint für die Gauge-Darstellung', (tester) async {
      await tester.pumpWidget(_buildGauge(15.0));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}

// Expected color values matching TunerGauge.tuneColor
const _greenColor = Color(0xFF16A34A);
const _yellowColor = Color(0xFFD97706);
const _redColor = Color(0xFFDC2626);
