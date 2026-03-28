import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/spielmodus/presentation/widgets/spielmodus_overlay.dart';

Widget _buildOverlay({
  required bool visible,
  String pageIndicator = 'Seite 1 / 8',
  VoidCallback? onBack,
  VoidCallback? onSettings,
  VoidCallback? onStimme,
  VoidCallback? onNightMode,
  VoidCallback? onLock,
  VoidCallback? onPageIndicatorTap,
  VoidCallback? onInteraction,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          SpielmodusOverlay(
            visible: visible,
            pageIndicator: pageIndicator,
            onBack: onBack ?? () {},
            onSettings: onSettings ?? () {},
            onStimme: onStimme ?? () {},
            onNightMode: onNightMode ?? () {},
            onLock: onLock ?? () {},
            onPageIndicatorTap: onPageIndicatorTap ?? () {},
            onInteraction: onInteraction ?? () {},
          ),
        ],
      ),
    ),
  );
}

void main() {
  group('SpielmodusOverlay — visibility (AC-52)', () {
    testWidgets('overlay is visible when visible=true', (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: true));
      await tester.pump();

      final animated = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animated.opacity, 1.0);
    });

    testWidgets('overlay is invisible when visible=false', (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: false));
      await tester.pump();

      final animated = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(animated.opacity, 0.0);
    });

    testWidgets('overlay fade-in animation duration is 150ms (AC-52)',
        (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: true));
      final animated = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      // AppDurations.fast = 150ms
      expect(animated.duration.inMilliseconds, lessThanOrEqualTo(150));
    });
  });

  group('SpielmodusOverlay — page indicator', () {
    testWidgets('displays pageIndicator text', (tester) async {
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        pageIndicator: 'Stück 3 / 12',
      ));
      await tester.pump();

      expect(find.text('Stück 3 / 12'), findsOneWidget);
    });
  });

  group('SpielmodusOverlay — button callbacks', () {
    testWidgets('onBack is called when back button pressed', (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        onBack: () => backCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backCalled, isTrue);
    });

    testWidgets('onSettings is called when settings button pressed',
        (tester) async {
      bool settingsCalled = false;
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        onSettings: () => settingsCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();

      expect(settingsCalled, isTrue);
    });

    testWidgets('onStimme is called when Stimme button pressed', (tester) async {
      bool stimmeCalled = false;
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        onStimme: () => stimmeCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.text('Stimme'));
      await tester.pump();

      expect(stimmeCalled, isTrue);
    });

    testWidgets('onNightMode is called when night mode button pressed',
        (tester) async {
      bool nightCalled = false;
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        onNightMode: () => nightCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.text('Nacht'));
      await tester.pump();

      expect(nightCalled, isTrue);
    });

    testWidgets('onLock is called when Sperren button pressed', (tester) async {
      bool lockCalled = false;
      await tester.pumpWidget(_buildOverlay(
        visible: true,
        onLock: () => lockCalled = true,
      ));
      await tester.pump();

      await tester.tap(find.text('Sperren'));
      await tester.pump();

      expect(lockCalled, isTrue);
    });
  });

  group('SpielmodusOverlay — touch targets (AC-55)', () {
    testWidgets('back button has minimum 44px touch target', (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: true));
      await tester.pump();

      final backButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.arrow_back),
      );
      expect(backButton.constraints!.minWidth, greaterThanOrEqualTo(44.0));
      expect(backButton.constraints!.minHeight, greaterThanOrEqualTo(44.0));
    });

    testWidgets('settings button has minimum 44px touch target', (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: true));
      await tester.pump();

      final settingsButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.settings_outlined),
      );
      expect(settingsButton.constraints!.minWidth, greaterThanOrEqualTo(44.0));
      expect(settingsButton.constraints!.minHeight, greaterThanOrEqualTo(44.0));
    });
  });

  group('SpielmodusOverlay — night mode label', () {
    testWidgets('shows custom nightModeLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SpielmodusOverlay(
                  visible: true,
                  pageIndicator: 'Seite 1 / 1',
                  onBack: () {},
                  onSettings: () {},
                  onStimme: () {},
                  onNightMode: () {},
                  onLock: () {},
                  onPageIndicatorTap: () {},
                  onInteraction: () {},
                  nightModeLabel: 'Sepia',
                  nightModeIcon: Icons.filter_vintage_outlined,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sepia'), findsOneWidget);
    });
  });

  group('SpielmodusOverlay — pointer ignore when hidden', () {
    testWidgets('overlay ignores pointer when invisible (AC-52)', (tester) async {
      await tester.pumpWidget(_buildOverlay(visible: false));
      await tester.pump();

      // Find the IgnorePointer that is a direct child of SpielmodusOverlay
      final overlayFinder = find.byType(SpielmodusOverlay);
      final ignorePointerFinder = find.descendant(
        of: overlayFinder,
        matching: find.byType(IgnorePointer),
      );
      final ignorePointer = tester.widget<IgnorePointer>(
        ignorePointerFinder.first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });
  });
}
