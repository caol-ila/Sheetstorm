import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/metronome_connection_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/bpm_picker.dart';
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

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        metronomeSignalRServiceProvider.overrideWithValue(mockSignalR),
        activeBandProvider.overrideWithValue('band-1'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('BpmPicker', () {
    testWidgets('shows current BPM', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
      expect(find.text('BPM'), findsOneWidget);
    });

    testWidgets('has stepper buttons', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      // [--], [-], [+], [++]
      expect(find.byIcon(Icons.keyboard_double_arrow_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_right), findsOneWidget);
    });

    testWidgets('has slider', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('has Tap Tempo button', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      expect(find.text('Tap Tempo'), findsOneWidget);
    });

    testWidgets('[+] increments BPM by 1', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(container.read(metronomeProvider).bpm, 121);
    });

    testWidgets('[-] decrements BPM by 1', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(container.read(metronomeProvider).bpm, 119);
    });

    testWidgets('[++] increments BPM by 5', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_right));
      await tester.pump();

      expect(container.read(metronomeProvider).bpm, 125);
    });

    testWidgets('[--] decrements BPM by 5', (tester) async {
      final container = makeContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SingleChildScrollView(child: BpmPicker())),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pump();

      expect(container.read(metronomeProvider).bpm, 115);
    });
  });
}
