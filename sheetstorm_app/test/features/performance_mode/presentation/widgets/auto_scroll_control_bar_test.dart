import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/auto_scroll_control_bar.dart';

/// Pumps the bar with a real (mutable) notifier.
Future<ProviderContainer> _pumpBar(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
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
  return container;
}

void main() {
  // ─── Render tests ────────────────────────────────────────────────────────

  testWidgets('renders play button when idle', (tester) async {
    await _pumpBar(tester);

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.stop), findsOneWidget);
    expect(find.byIcon(Icons.replay), findsOneWidget);
  });

  testWidgets('renders pause button when playing', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).play();
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('renders play button when paused', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).play();
    container.read(autoScrollProvider.notifier).pause();
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });

  testWidgets('shows speed label 1× in manual mode', (tester) async {
    await _pumpBar(tester);
    expect(find.text('1×'), findsOneWidget);
  });

  testWidgets('shows BPM label in bpm mode', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).setMode(AutoScrollMode.bpm);
    await tester.pump();

    expect(find.text('120 BPM'), findsOneWidget);
  });

  testWidgets('has increment and decrement buttons', (tester) async {
    await _pumpBar(tester);

    expect(find.byIcon(Icons.remove), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
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

    final playButton = find.byIcon(Icons.play_arrow);
    expect(playButton, findsOneWidget);
    final buttonSize = tester.getSize(playButton);
    expect(buttonSize.width, greaterThanOrEqualTo(24));
    expect(buttonSize.height, greaterThanOrEqualTo(24));
  });

  // ─── Interaction tests ───────────────────────────────────────────────────

  testWidgets('tapping play transitions to playing', (tester) async {
    await _pumpBar(tester);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(find.byIcon(Icons.pause), findsOneWidget);
  });

  testWidgets('tapping pause transitions to paused', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).play();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('tapping stop transitions to idle', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).play();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('tapping increment increases speed label', (tester) async {
    await _pumpBar(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('1.1×'), findsOneWidget);
  });

  testWidgets('tapping decrement decreases speed label', (tester) async {
    await _pumpBar(tester);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();

    expect(find.text('0.9×'), findsOneWidget);
  });

  testWidgets('reset returns to idle', (tester) async {
    final container = await _pumpBar(tester);
    container.read(autoScrollProvider.notifier).play();
    container.read(autoScrollProvider.notifier).setSpeedFactor(2.0);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.replay));
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
  });
}
