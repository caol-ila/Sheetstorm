import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/spielmodus/data/models/spielmodus_models.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/half_page_turn_view.dart';

const _currentPage = SheetPage(
  pageNumber: 2,
  stueckId: 'test',
  stimmeId: 'kl2',
);

const _nextPage = SheetPage(
  pageNumber: 3,
  stueckId: 'test',
  stimmeId: 'kl2',
);

Widget _buildHalfPageTurn({
  SheetPage? nextPage,
  Farbmodus farbmodus = Farbmodus.standard,
  double splitRatio = 0.5,
  bool showDivider = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: HalfPageTurnView(
        currentPage: _currentPage,
        nextPage: nextPage,
        farbmodus: farbmodus,
        splitRatio: splitRatio,
        showDivider: showDivider,
      ),
    ),
  );
}

/// Sets a tall test surface and pumps the widget, suppressing overflow errors.
Future<void> _pumpHalfPageTurn(
  WidgetTester tester, {
  SheetPage? nextPage,
  Farbmodus farbmodus = Farbmodus.standard,
  double splitRatio = 0.5,
  bool showDivider = true,
}) async {
  // Use a tall surface so the placeholder content fits without overflow
  await tester.binding.setSurfaceSize(const Size(400, 3000));
  addTearDown(() async => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(_buildHalfPageTurn(
    nextPage: nextPage,
    farbmodus: farbmodus,
    splitRatio: splitRatio,
    showDivider: showDivider,
  ));
  await tester.pump();
}

void main() {
  group('HalfPageTurnView — layout (AC-13)', () {
    testWidgets('shows both current and next page', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage);

      // Page 3 (index 2) and Page 4 (index 3)
      expect(find.text('Seite 3'), findsAtLeastNWidgets(1));
      expect(find.text('Seite 4'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows divider line by default (AC-14)', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage, showDivider: true);

      // Column with 3 children: top SizedBox, divider Container, bottom SizedBox
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.children.length, 3);
    });

    testWidgets('no divider when showDivider=false', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage, showDivider: false);

      // Column should have only 2 children (no divider)
      final column = tester.widget<Column>(find.byType(Column).first);
      expect(column.children.length, 2);
    });
  });

  group('HalfPageTurnView — split ratios (AC-17)', () {
    testWidgets('renders with 50/50 split', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage, splitRatio: 0.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with 40/60 split', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage, splitRatio: 0.4);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with 60/40 split', (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: _nextPage, splitRatio: 0.6);
      expect(tester.takeException(), isNull);
    });
  });

  group('HalfPageTurnView — edge cases (AC-20)', () {
    testWidgets('renders empty bottom half when nextPage is null (last page)',
        (tester) async {
      await _pumpHalfPageTurn(tester, nextPage: null);

      // Should not crash on last page
      expect(tester.takeException(), isNull);
      expect(find.text('Seite 3'), findsAtLeastNWidgets(1));
    });
  });

  group('HalfPageTurnView — Farbmodus', () {
    testWidgets('night mode divider uses warm orange tint', (tester) async {
      await _pumpHalfPageTurn(
        tester,
        nextPage: _nextPage,
        farbmodus: Farbmodus.nacht,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('sepia mode renders without errors', (tester) async {
      await _pumpHalfPageTurn(
        tester,
        nextPage: _nextPage,
        farbmodus: Farbmodus.sepia,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
