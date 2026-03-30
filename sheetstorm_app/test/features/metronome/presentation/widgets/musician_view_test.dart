import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/musician_view.dart';

void main() {
  group('MusicianView', () {
    testWidgets('shows waiting state when not playing', (tester) async {
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
            home: Scaffold(body: MusicianView()),
          ),
        ),
      );

      expect(find.text('Kein Metronom aktiv'), findsOneWidget);
      expect(find.text('Warte auf Dirigent...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows beat indicator when playing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            bpm: 120,
            timeSignature: TimeSignature(beatsPerMeasure: 4, beatUnit: 4),
            transport: MetronomeTransport.websocket,
            connectionState: MetronomeConnectionState.connected,
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
            home: Scaffold(body: MusicianView()),
          ),
        ),
      );

      // Should show beat info
      expect(find.text('120 BPM · 4/4'), findsOneWidget);
      // Should show audio click toggle
      expect(find.text('Audio-Click (lokal)'), findsOneWidget);
      // Should NOT show waiting state
      expect(find.text('Kein Metronom aktiv'), findsNothing);
    });

    testWidgets('shows transport type in header', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            transport: MetronomeTransport.udp,
            connectionState: MetronomeConnectionState.connected,
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
            home: Scaffold(body: MusicianView()),
          ),
        ),
      );

      expect(find.text('UDP'), findsOneWidget);
    });

    testWidgets('shows latency compensation display', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            latencyCompensationMs: 15,
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
            home: Scaffold(body: MusicianView()),
          ),
        ),
      );

      expect(find.text('Latenz: +15ms'), findsOneWidget);
    });

    testWidgets('shows negative latency compensation', (tester) async {
      final container = ProviderContainer(
        overrides: [
          metronomeProvider.overrideWithValue(const MetronomeState(
            isPlaying: true,
            latencyCompensationMs: -10,
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
            home: Scaffold(body: MusicianView()),
          ),
        ),
      );

      expect(find.text('Latenz: -10ms'), findsOneWidget);
    });
  });
}
