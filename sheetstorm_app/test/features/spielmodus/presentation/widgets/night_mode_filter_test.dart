import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/night_mode_filter.dart';

Widget _buildFilter({
  required Farbmodus farbmodus,
  double helligkeit = 1.0,
}) {
  return MaterialApp(
    home: Scaffold(
      body: NightModeFilter(
        farbmodus: farbmodus,
        helligkeit: helligkeit,
        child: const SizedBox(
          width: 100,
          height: 100,
          key: Key('child'),
        ),
      ),
    ),
  );
}

void main() {
  group('NightModeFilter — standard mode passthrough (AC-30)', () {
    testWidgets('standard mode + brightness=1.0 renders child directly',
        (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.standard, helligkeit: 1.0),
      );
      await tester.pump();

      // No ColorFiltered wrapper when standard + brightness=1.0
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('standard mode + brightness < 1.0 applies brightness filter',
        (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.standard, helligkeit: 0.8),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
    });
  });

  group('NightModeFilter — night mode (AC-30, AC-34)', () {
    testWidgets('night mode applies ColorFiltered', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('night mode child is still present', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byKey(const Key('child')), findsOneWidget);
    });

    testWidgets('night mode with reduced brightness applies filter', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 0.7),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
    });
  });

  group('NightModeFilter — sepia mode (AC-33)', () {
    testWidgets('sepia mode applies ColorFiltered', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.sepia, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('sepia mode child is present', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.sepia, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byKey(const Key('child')), findsOneWidget);
    });
  });

  group('NightModeFilter — mode switching (AC-31)', () {
    testWidgets('switching from standard to nacht adds ColorFiltered',
        (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.standard, helligkeit: 1.0),
      );
      await tester.pump();
      expect(find.byType(ColorFiltered), findsNothing);

      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();
      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('switching from nacht to sepia keeps ColorFiltered',
        (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();

      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.sepia, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsOneWidget);
    });

    testWidgets('switching from nacht back to standard removes filter',
        (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();

      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.standard, helligkeit: 1.0),
      );
      await tester.pump();

      expect(find.byType(ColorFiltered), findsNothing);
    });
  });

  group('NightModeFilter — color matrix values (AC-30)', () {
    testWidgets('night mode applies a non-identity color filter', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.nacht, helligkeit: 1.0),
      );
      await tester.pump();

      // Night mode must apply ColorFiltered (not pass-through)
      final filtered = tester.widget<ColorFiltered>(
        find.byType(ColorFiltered),
      );
      // The filter must be a matrix filter (not identity)
      expect(filtered.colorFilter, isNotNull);
      expect(filtered.colorFilter.toString(), contains('ColorFilter.matrix'));
    });

    testWidgets('sepia mode applies a non-identity color filter', (tester) async {
      await tester.pumpWidget(
        _buildFilter(farbmodus: Farbmodus.sepia, helligkeit: 1.0),
      );
      await tester.pump();

      final filtered = tester.widget<ColorFiltered>(
        find.byType(ColorFiltered),
      );
      expect(filtered.colorFilter, isNotNull);
      expect(filtered.colorFilter.toString(), contains('ColorFilter.matrix'));
    });
  });
}
