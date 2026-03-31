import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/metronome_connection_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';

class MockMetronomeSignalRService extends Mock
    implements MetronomeSignalRService {}

void main() {
  late MockMetronomeSignalRService mockSignalR;

  setUp(() {
    mockSignalR = MockMetronomeSignalRService();

    // Default stream stubs
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

  ProviderContainer makeContainer({String? bandId = 'band-1'}) {
    final container = ProviderContainer(
      overrides: [
        metronomeSignalRServiceProvider.overrideWithValue(mockSignalR),
        activeBandProvider.overrideWithValue(bandId),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  MetronomeNotifier setupNotifier({String? bandId = 'band-1'}) {
    final container = makeContainer(bandId: bandId);
    return container.read(metronomeProvider.notifier);
  }

  group('MetronomeNotifier', () {
    group('initial state', () {
      test('has sensible defaults', () {
        final container = makeContainer();
        final state = container.read(metronomeProvider);
        expect(state.isPlaying, false);
        expect(state.bpm, 120);
        expect(state.timeSignature, TimeSignature.common);
        expect(state.isConductor, false);
        expect(state.transport, MetronomeTransport.none);
      });
    });

    group('conductor commands', () {
      test('startAsConductor sets conductor mode and connects', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        await notifier.startAsConductor(
          bpm: 140,
          timeSignature: TimeSignature.waltz,
        );

        final state = container.read(metronomeProvider);
        expect(state.isConductor, true);
        expect(state.bpm, 140);
        expect(state.timeSignature, TimeSignature.waltz);
        expect(state.isPlaying, true);

        verify(() => mockSignalR.connect()).called(1);
        verify(() => mockSignalR.startSession(
              bandId: 'band-1',
              bpm: 140,
              beatsPerMeasure: 3,
              beatUnit: 4,
            )).called(1);
      });

      test('startAsConductor does nothing without bandId', () async {
        final notifier = setupNotifier(bandId: null);
        await notifier.startAsConductor(
          bpm: 120,
          timeSignature: TimeSignature.common,
        );
        verifyNever(() => mockSignalR.connect());
      });

      test('stop sends stop command and resets state', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        await notifier.startAsConductor(
          bpm: 120,
          timeSignature: TimeSignature.common,
        );

        notifier.stop();

        final state = container.read(metronomeProvider);
        expect(state.isPlaying, false);
        expect(state.session, isNull);

        verify(() => mockSignalR.stopSession('band-1')).called(1);
      });

      test('changeBpm updates state and sends update', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        await notifier.startAsConductor(
          bpm: 120,
          timeSignature: TimeSignature.common,
        );

        notifier.changeBpm(160);

        final state = container.read(metronomeProvider);
        expect(state.bpm, 160);

        verify(() => mockSignalR.updateSession(
              bandId: 'band-1',
              bpm: 160,
              beatsPerMeasure: 4,
              beatUnit: 4,
            )).called(1);
      });

      test('changeBpm clamps to valid range', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        await notifier.startAsConductor(
          bpm: 120,
          timeSignature: TimeSignature.common,
        );

        notifier.changeBpm(500);
        expect(container.read(metronomeProvider).bpm, 300);

        notifier.changeBpm(5);
        expect(container.read(metronomeProvider).bpm, 20);
      });

      test('changeTimeSignature updates and sends update', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        await notifier.startAsConductor(
          bpm: 120,
          timeSignature: TimeSignature.common,
        );

        notifier.changeTimeSignature(TimeSignature.waltz);

        final state = container.read(metronomeProvider);
        expect(state.timeSignature, TimeSignature.waltz);

        verify(() => mockSignalR.updateSession(
              bandId: 'band-1',
              bpm: 120,
              beatsPerMeasure: 3,
              beatUnit: 4,
            )).called(1);
      });
    });

    group('musician commands', () {
      test('joinAsMusician connects and joins', () async {
        final notifier = setupNotifier();
        await notifier.joinAsMusician();

        verify(() => mockSignalR.connect()).called(1);
        verify(() => mockSignalR.joinSession('band-1')).called(1);
      });

      test('joinAsMusician sets isConductor to false', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        await notifier.joinAsMusician();

        final state = container.read(metronomeProvider);
        expect(state.isConductor, false);
      });

      test('leave sends leave and resets state', () async {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        await notifier.joinAsMusician();

        notifier.leave();

        verify(() => mockSignalR.leaveSession('band-1')).called(1);
        final state = container.read(metronomeProvider);
        expect(state.isPlaying, false);
        expect(state.isConductor, false);
      });
    });

    group('settings', () {
      test('toggleAudioClick flips state', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        expect(container.read(metronomeProvider).audioClickEnabled, false);
        notifier.toggleAudioClick();
        expect(container.read(metronomeProvider).audioClickEnabled, true);
        notifier.toggleAudioClick();
        expect(container.read(metronomeProvider).audioClickEnabled, false);
      });

      test('setLatencyCompensation clamps to range', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setLatencyCompensation(50);
        expect(
            container.read(metronomeProvider).latencyCompensationMs, 50);

        notifier.setLatencyCompensation(200);
        expect(
            container.read(metronomeProvider).latencyCompensationMs, 100);

        notifier.setLatencyCompensation(-200);
        expect(
            container.read(metronomeProvider).latencyCompensationMs, -100);
      });

      test('setBpm clamps to valid range', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setBpm(150);
        expect(container.read(metronomeProvider).bpm, 150);

        notifier.setBpm(0);
        expect(container.read(metronomeProvider).bpm, 20);

        notifier.setBpm(400);
        expect(container.read(metronomeProvider).bpm, 300);
      });

      test('setTimeSignature updates state', () {
        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);

        notifier.setTimeSignature(TimeSignature.sixEight);
        expect(container.read(metronomeProvider).timeSignature,
            TimeSignature.sixEight);
      });
    });

    group('session events', () {
      test('onSessionStarted sets playing state and creates calculator',
          () async {
        final sessionController =
            StreamController<MetronomeSession>.broadcast();
        when(() => mockSignalR.onSessionStarted)
            .thenAnswer((_) => sessionController.stream);

        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        await notifier.joinAsMusician();

        final session = MetronomeSession(
          sessionId: 'sess-1',
          bandId: 'band-1',
          bpm: 120,
          timeSignature: TimeSignature.common,
          startTimeUs: DateTime.now().microsecondsSinceEpoch,
          conductorId: 'user-1',
          conductorName: 'Max',
          connectedClients: 5,
        );
        sessionController.add(session);
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(metronomeProvider);
        expect(state.isPlaying, true);
        expect(state.bpm, 120);
        expect(state.session, isNotNull);
        expect(state.connectedClients, 5);

        sessionController.close();
      });

      test('onSessionStopped resets state', () async {
        final sessionStartController =
            StreamController<MetronomeSession>.broadcast();
        final sessionStopController = StreamController<String>.broadcast();
        when(() => mockSignalR.onSessionStarted)
            .thenAnswer((_) => sessionStartController.stream);
        when(() => mockSignalR.onSessionStopped)
            .thenAnswer((_) => sessionStopController.stream);

        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        await notifier.joinAsMusician();

        // Start session
        sessionStartController.add(MetronomeSession(
          sessionId: 'sess-1',
          bandId: 'band-1',
          bpm: 120,
          timeSignature: TimeSignature.common,
          startTimeUs: DateTime.now().microsecondsSinceEpoch,
          conductorId: 'user-1',
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        expect(container.read(metronomeProvider).isPlaying, true);

        // Stop session
        sessionStopController.add('sess-1');
        await Future.delayed(const Duration(milliseconds: 50));

        final state = container.read(metronomeProvider);
        expect(state.isPlaying, false);
        expect(state.session, isNull);

        sessionStartController.close();
        sessionStopController.close();
      });

      test('onParticipantCountChanged updates count', () async {
        final countController = StreamController<int>.broadcast();
        when(() => mockSignalR.onParticipantCountChanged)
            .thenAnswer((_) => countController.stream);

        final container = makeContainer();
        final notifier = container.read(metronomeProvider.notifier);
        await notifier.joinAsMusician();

        countController.add(15);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(container.read(metronomeProvider).connectedClients, 15);

        countController.close();
      });
    });
  });
}
