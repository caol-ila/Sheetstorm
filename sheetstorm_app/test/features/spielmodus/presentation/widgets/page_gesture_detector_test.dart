import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/page_gesture_detector.dart';

/// Sets a 400×800 surface and pumps the PageGestureDetector filling the screen.
/// The widget fills the entire surface so tap positions are predictable.
Future<void> _pumpDetector(
  WidgetTester tester, {
  required VoidCallback onNext,
  required VoidCallback onPrev,
  required VoidCallback onOverlay,
  required VoidCallback onDoubleTap,
  bool isLocked = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(400, 800));
  addTearDown(() async => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PageGestureDetector(
          onNextPage: onNext,
          onPreviousPage: onPrev,
          onToggleOverlay: onOverlay,
          onDoubleTap: onDoubleTap,
          isLocked: isLocked,
          child: Container(color: Colors.white),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('PageGestureDetector — tap zones (AC-06, AC-07, AC-12)', () {
    testWidgets('tap in right 60% triggers next page (AC-06)', (tester) async {
      bool nextCalled = false;
      bool prevCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () => prevCalled = true,
        onOverlay: () {},
        onDoubleTap: () {},
      );

      // Tap at x=300 (75% of 400) — right 60% zone
      await tester.tapAt(const Offset(300, 400));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
      expect(prevCalled, isFalse);
    });

    testWidgets('tap in left 40% triggers previous page (AC-07)', (tester) async {
      bool nextCalled = false;
      bool prevCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () => prevCalled = true,
        onOverlay: () {},
        onDoubleTap: () {},
      );

      // Tap at x=80 (20% of 400) — left 40% zone
      await tester.tapAt(const Offset(80, 400));
      await tester.pump();

      expect(prevCalled, isTrue);
      expect(nextCalled, isFalse);
    });

    testWidgets('tap in center (45%–55%) triggers overlay (AC-12)',
        (tester) async {
      bool overlayCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () => prevCalled = true,
        onOverlay: () => overlayCalled = true,
        onDoubleTap: () {},
      );

      // Tap at x=200 (50% of 400) — center zone
      await tester.tapAt(const Offset(200, 400));
      await tester.pump();

      expect(overlayCalled, isTrue);
      expect(nextCalled, isFalse);
      expect(prevCalled, isFalse);
    });

    testWidgets('boundary tap at 40.5% goes to next page, not previous',
        (tester) async {
      bool nextCalled = false;
      bool prevCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () => prevCalled = true,
        onOverlay: () {},
        onDoubleTap: () {},
      );

      // Tap at x=163 (40.75% of 400) — just past left zone boundary
      await tester.tapAt(const Offset(163, 400));
      await tester.pump();

      expect(nextCalled, isTrue);
      expect(prevCalled, isFalse);
    });
  });

  group('PageGestureDetector — swipe gestures (AC-08)', () {
    testWidgets('swipe left triggers next page', (tester) async {
      bool nextCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () {},
        onOverlay: () {},
        onDoubleTap: () {},
      );

      await tester.drag(
        find.byType(PageGestureDetector),
        const Offset(-150, 0),
      );
      await tester.pump();

      expect(nextCalled, isTrue);
    });

    testWidgets('swipe right triggers previous page', (tester) async {
      bool prevCalled = false;

      await _pumpDetector(
        tester,
        onNext: () {},
        onPrev: () => prevCalled = true,
        onOverlay: () {},
        onDoubleTap: () {},
      );

      await tester.drag(
        find.byType(PageGestureDetector),
        const Offset(150, 0),
      );
      await tester.pump();

      expect(prevCalled, isTrue);
    });
  });

  group('PageGestureDetector — UI lock (AC-05)', () {
    testWidgets('tap does nothing when isLocked=true', (tester) async {
      bool nextCalled = false;
      bool prevCalled = false;
      bool overlayCalled = false;

      await _pumpDetector(
        tester,
        onNext: () => nextCalled = true,
        onPrev: () => prevCalled = true,
        onOverlay: () => overlayCalled = true,
        onDoubleTap: () {},
        isLocked: true,
      );

      await tester.tapAt(const Offset(300, 400));
      await tester.tapAt(const Offset(80, 400));
      await tester.tapAt(const Offset(200, 400));
      await tester.pump();

      expect(nextCalled, isFalse);
      expect(prevCalled, isFalse);
      expect(overlayCalled, isFalse);
    });
  });

  group('PageGestureDetector — double tap (AC-51)', () {
    testWidgets('double tap triggers onDoubleTap callback', (tester) async {
      bool doubleTapCalled = false;

      await _pumpDetector(
        tester,
        onNext: () {},
        onPrev: () {},
        onOverlay: () {},
        onDoubleTap: () => doubleTapCalled = true,
      );

      await tester.tap(find.byType(PageGestureDetector));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(PageGestureDetector));
      await tester.pump();

      expect(doubleTapCalled, isTrue);
    });

    testWidgets('double tap disabled when locked', (tester) async {
      bool doubleTapCalled = false;

      await _pumpDetector(
        tester,
        onNext: () {},
        onPrev: () {},
        onOverlay: () {},
        onDoubleTap: () => doubleTapCalled = true,
        isLocked: true,
      );

      await tester.tap(find.byType(PageGestureDetector));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(PageGestureDetector));
      await tester.pump();

      expect(doubleTapCalled, isFalse);
    });
  });
}
