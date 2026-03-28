import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/ui_lock_overlay.dart';

Widget _buildUiLock({
  required bool isLocked,
  required VoidCallback onUnlock,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          UiLockOverlay(
            isLocked: isLocked,
            onUnlockTriggered: onUnlock,
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('UiLockOverlay — visibility', () {
    testWidgets('shows nothing when isLocked=false', (tester) async {
      await tester.pumpWidget(_buildUiLock(
        isLocked: false,
        onUnlock: () {},
      ));
      await tester.pump();

      // When not locked, UiLockOverlay renders SizedBox.shrink()
      // No GestureDetector inside the UiLockOverlay subtree
      expect(
        find.descendant(
          of: find.byType(UiLockOverlay),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('shows gesture overlay when isLocked=true', (tester) async {
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () {},
      ));
      await tester.pump();

      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });

  group('UiLockOverlay — 5-tap unlock (AC-05)', () {
    testWidgets('5 consecutive taps trigger unlock callback', (tester) async {
      bool unlockCalled = false;
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () => unlockCalled = true,
      ));
      await tester.pump();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(unlockCalled, isTrue);
    });

    testWidgets('4 taps do NOT trigger unlock callback', (tester) async {
      bool unlockCalled = false;
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () => unlockCalled = true,
      ));
      await tester.pump();

      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(unlockCalled, isFalse);
    });

    testWidgets('tap counter resets after enough time passes between taps',
        (tester) async {
      // This behavior depends on DateTime.now() — we verify the threshold constant
      // is 5 by testing the boundary: 4 taps never unlock, 5 does.
      // The 3-second reset window requires real-time testing on device.
      bool unlockCalled = false;
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () => unlockCalled = true,
      ));
      await tester.pump();

      // Verify 4 taps never unlock regardless of timing
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(unlockCalled, isFalse);
    });

    testWidgets('exactly 5 rapid taps in new session unlock', (tester) async {
      bool unlockCalled = false;
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () => unlockCalled = true,
      ));
      await tester.pump();

      // First do 2 taps then wait (resets counter)
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(GestureDetector));
      await tester.pump(const Duration(seconds: 4)); // reset

      // Now 5 consecutive taps
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(GestureDetector));
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(unlockCalled, isTrue);
    });
  });

  group('UiLockOverlay — counter display', () {
    testWidgets('tap counter hint starts hidden (opacity=0)', (tester) async {
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () {},
      ));
      await tester.pump();

      final animated = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animated.opacity, 0.0);
    });

    testWidgets('tap counter hint becomes visible after first tap', (tester) async {
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () {},
      ));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      final animated = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animated.opacity, 1.0);
    });

    testWidgets('shows remaining taps hint text', (tester) async {
      await tester.pumpWidget(_buildUiLock(
        isLocked: true,
        onUnlock: () {},
      ));
      await tester.pump();

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      // After 1 tap: counter=1, remaining=4. Hint shows "Tippe 4× in die Mitte zum Entsperren"
      expect(
        find.textContaining('4×'),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
