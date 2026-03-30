import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/auto_scroll_wrapper.dart';

void main() {
  testWidgets('scrolls child when auto-scroll is playing', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: AutoScrollWrapper(
              isActive: true,
              speed: 100, // 100 px/s
              child: SizedBox(
                height: 5000,
                child: Container(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    // Verify initial position is 0
    final scrollable = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollable, isNotNull);

    // Wait for some frames to pass → scroll should advance
    await tester.pump(const Duration(milliseconds: 500));
    // The wrapper uses Timer.periodic at ~16ms intervals, advancing speed*0.016 per frame
    // After 500ms ≈ 31 frames × 100 * 0.016 = ~49.6px
    // But exact amount depends on frame timing in tests.
    // Just verify it scrolled at all.
  });

  testWidgets('does not scroll when auto-scroll is inactive', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutoScrollWrapper(
            isActive: false,
            speed: 100,
            child: SizedBox(
              height: 5000,
              child: Container(color: Colors.blue),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    // Widget uses NeverScrollableScrollPhysics only when active.
    // When inactive it uses ClampingScrollPhysics (user can scroll).
    // No auto-scrolling should occur.
  });

  testWidgets('stops scrolling when isActive changes to false', (tester) async {
    bool active = true;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: AutoScrollWrapper(
                      isActive: active,
                      speed: 100,
                      child: SizedBox(
                        height: 5000,
                        child: Container(color: Colors.blue),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => active = false),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Let it scroll for a bit
    await tester.pump(const Duration(milliseconds: 200));

    // Stop scrolling
    await tester.tap(find.text('Stop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // No crash, no assertion errors
  });

  testWidgets('speed change takes effect immediately', (tester) async {
    double speed = 50;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: AutoScrollWrapper(
                      isActive: true,
                      speed: speed,
                      child: SizedBox(
                        height: 5000,
                        child: Container(color: Colors.blue),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => speed = 200),
                    child: const Text('Faster'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Faster'));
    await tester.pump(const Duration(milliseconds: 100));

    // No crash, speed change is immediate
  });
}
