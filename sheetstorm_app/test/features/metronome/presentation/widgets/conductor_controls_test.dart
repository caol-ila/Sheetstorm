import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/metronome_connection_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/conductor_controls.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';

class MockMetronomeSignalRService extends Mock
    implements MetronomeSignalRService {}

void main() {
  late MockMetronomeSignalRService mockSignalR;

  setUp(() {
    mockSignalR = MockMetronomeSignalRService();
    when(() => mockSignalR.onSessionStarted)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.onSessionStopped)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.onSessionUpdated)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.onClockSyncResponse)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.onParticipantCountChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.onConnectionStateChanged)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockSignalR.connectionState)
        .thenReturn(MetronomeConnectionState.disconnected);
    when(() => mockSignalR.connect()).thenAnswer((_) async {});
  });

  ProviderContainer _makeContainer() {
    final container = ProviderContainer(
      overrides: [
        metronomeSignalRServiceProvider.overrideWithValue(mockSignalR),
        activeBandProvider.overrideWithValue('band-1'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ConductorControls', () {
    testWidgets('shows BPM display', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      // Default BPM = 120
      expect(find.text('120'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
    });

    testWidgets('shows Start button when stopped', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('shows time signature chips', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      expect(find.text('2/4'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);
      expect(find.text('4/4'), findsOneWidget);
      expect(find.text('6/8'), findsOneWidget);
    });

    testWidgets('shows Audio-Click toggle', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      expect(find.text('Audio-Click'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('shows Tap Tempo button', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      expect(find.text('Tap Tempo'), findsOneWidget);
    });

    testWidgets('BPM stepper buttons change BPM', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      // Initial BPM = 120
      expect(find.text('120'), findsOneWidget);

      // Tap [+] button (BPM + 1)
      final plusButton = find.byIcon(Icons.chevron_right);
      await tester.tap(plusButton);
      await tester.pump();

      expect(find.text('121'), findsOneWidget);
    });

    testWidgets('selecting time signature chip updates state', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      // Tap 3/4 chip
      await tester.tap(find.text('3/4'));
      await tester.pump();

      final state = container.read(metronomeProvider);
      expect(state.timeSignature, TimeSignature.waltz);
    });

    testWidgets('toggling audio click updates state', (tester) async {
      final container = _makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ConductorControls()),
          ),
        ),
      );

      expect(container.read(metronomeProvider).audioClickEnabled, false);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(container.read(metronomeProvider).audioClickEnabled, true);
    });
  });
}
