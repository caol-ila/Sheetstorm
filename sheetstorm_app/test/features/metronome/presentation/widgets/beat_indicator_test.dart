import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/beat_indicator.dart';

void main() {
  group('BeatCirclePainter', () {
    test('shouldRepaint returns true when isActive changes', () {
      final painter1 = BeatCirclePainter(
        isActive: false,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      final painter2 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns true when pulseScale changes', () {
      final painter1 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      final painter2 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.3,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });

    test('shouldRepaint returns false when nothing changes', () {
      final painter1 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      final painter2 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      expect(painter1.shouldRepaint(painter2), false);
    });

    test('shouldRepaint returns true when isDownbeat changes', () {
      final painter1 = BeatCirclePainter(
        isActive: true,
        isDownbeat: false,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      final painter2 = BeatCirclePainter(
        isActive: true,
        isDownbeat: true,
        pulseScale: 1.0,
        accentColor: Colors.blue,
        inactiveColor: Colors.grey,
      );
      expect(painter1.shouldRepaint(painter2), true);
    });
  });

  group('BeatIndicator widget', () {
    testWidgets('renders without error in idle state', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: BeatIndicator(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BeatIndicator), findsOneWidget);
      // CustomPaint is used by our painter
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('shows beat position dots for 4/4', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            timeSignature: TimeSignature(beatsPerMeasure: 4, beatUnit: 4),
            currentBeat: BeatEvent(
              beatNumber: 0,
              timestampUs: 0,
              measure: 0,
              beatInMeasure: 0,
              isDownbeat: true,
            ),
          )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: BeatIndicator(),
              ),
            ),
          ),
        ),
      );

      // Should show 4 beat numbers
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows 3 dots for 3/4 time signature', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            timeSignature: TimeSignature(beatsPerMeasure: 3, beatUnit: 4),
            currentBeat: BeatEvent(
              beatNumber: 0,
              timestampUs: 0,
              measure: 0,
              beatInMeasure: 0,
              isDownbeat: true,
            ),
          )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: BeatIndicator(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
    });
  });
}
