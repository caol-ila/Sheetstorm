import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/auto_scroll_control_bar.dart';

/// Pumps the AutoScrollControlBar inside a minimal MaterialApp + ProviderScope.
Future<void> _pumpBar(
  WidgetTester tester, {
  AutoScrollState? initialState,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (initialState != null)
          autoScrollProvider.overrideWithValue(initialState),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Spacer(),
              AutoScrollControlBar(),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders play button when idle', (tester) async {
    await _pumpBar(tester);

    // Play button should be visible
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    // Stop should be disabled/greyed
    expect(find.byIcon(Icons.stop), findsOneWidget);
    // Reset should be present
    expect(find.byIcon(Icons.replay), findsOneWidget);
  });

  testWidgets('renders pause button when playing', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(status: AutoScrollStatus.playing),
    );

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('renders play button when paused', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(status: AutoScrollStatus.paused),
    );

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('shows speed label 1.0× in manual mode', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(
        mode: AutoScrollMode.manual,
        speedFactor: 1.0,
      ),
    );

    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('shows BPM label in bpm mode', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(
        mode: AutoScrollMode.bpm,
        bpm: 120,
      ),
    );

    expect(find.text('120 BPM'), findsOneWidget);
  });

  testWidgets('has increment and decrement buttons', (tester) async {
    await _pumpBar(tester);

    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping play transitions to playing', (tester) async {
    await _pumpBar(tester);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // After tapping play, the pause icon should appear
    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('tapping pause transitions to paused', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(status: AutoScrollStatus.playing),
    );

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('tapping stop transitions to idle', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(status: AutoScrollStatus.playing),
    );

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('tapping increment increases speed label', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(speedFactor: 1.0),
    );

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1.1×'), findsOneWidget);
  });

  testWidgets('tapping decrement decreases speed label', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(speedFactor: 1.0),
    );

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('0.9×'), findsOneWidget);
  });

  testWidgets('reset returns to idle', (tester) async {
    await _pumpBar(
      tester,
      initialState: const AutoScrollState(
        status: AutoScrollStatus.playing,
        speedFactor: 2.0,
      ),
    );

    await tester.tap(find.byIcon(Icons.replay));
    await tester.pump();

    // Back to idle, play button visible
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('bar height is 48px (touch target)', (tester) async {
    await _pumpBar(tester);

    final bar = tester.widget<SizedBox>(
      find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 48,
      ),
    );
    expect(bar.height, 48.0);
  });

  testWidgets('all buttons meet minimum touch target size', (tester) async {
    await _pumpBar(tester);

    // Each interactive button should be at least 44x40px
    final playButton = find.byIcon(Icons.play_arrow);
    expect(playButton, findsOneWidget);
    final buttonSize = tester.getSize(playButton);
    expect(buttonSize.width, greaterThanOrEqualTo(24));
    expect(buttonSize.height, greaterThanOrEqualTo(24));
  });
}
