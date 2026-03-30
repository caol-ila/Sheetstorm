import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

void main() {
  group('TimeSignature', () {
    test('display format is correct', () {
      const ts = TimeSignature(beatsPerMeasure: 4, beatUnit: 4);
      expect(ts.display, '4/4');
    });

    test('standard options are defined', () {
      expect(TimeSignature.standardOptions.length, 4);
      expect(TimeSignature.common.display, '4/4');
      expect(TimeSignature.waltz.display, '3/4');
      expect(TimeSignature.march.display, '2/4');
      expect(TimeSignature.sixEight.display, '6/8');
    });

    test('fromJson creates correct instance', () {
      final json = {'beatsPerMeasure': 3, 'beatUnit': 4};
      final ts = TimeSignature.fromJson(json);
      expect(ts.beatsPerMeasure, 3);
      expect(ts.beatUnit, 4);
    });

    test('toJson produces correct map', () {
      const ts = TimeSignature(beatsPerMeasure: 6, beatUnit: 8);
      final json = ts.toJson();
      expect(json['beatsPerMeasure'], 6);
      expect(json['beatUnit'], 8);
    });

    test('roundtrip fromJson/toJson', () {
      const original = TimeSignature(beatsPerMeasure: 5, beatUnit: 4);
      final restored = TimeSignature.fromJson(original.toJson());
      expect(restored, original);
    });

    test('parse creates from display string', () {
      final ts = TimeSignature.parse('6/8');
      expect(ts.beatsPerMeasure, 6);
      expect(ts.beatUnit, 8);
    });

    test('equality by value', () {
      const a = TimeSignature(beatsPerMeasure: 4, beatUnit: 4);
      const b = TimeSignature(beatsPerMeasure: 4, beatUnit: 4);
      const c = TimeSignature(beatsPerMeasure: 3, beatUnit: 4);
      expect(a, b);
      expect(a, isNot(c));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('MetronomeTransport', () {
    test('fromJson maps correctly', () {
      expect(MetronomeTransport.fromJson('udp'), MetronomeTransport.udp);
      expect(MetronomeTransport.fromJson('websocket'),
          MetronomeTransport.websocket);
      expect(MetronomeTransport.fromJson('none'), MetronomeTransport.none);
    });

    test('fromJson unknown value returns none', () {
      expect(MetronomeTransport.fromJson('bluetooth'), MetronomeTransport.none);
    });

    test('toJson returns string value', () {
      expect(MetronomeTransport.udp.toJson(), 'udp');
      expect(MetronomeTransport.websocket.toJson(), 'websocket');
    });
  });

  group('BeatEvent', () {
    test('creates with required fields', () {
      const beat = BeatEvent(
        beatNumber: 0,
        timestampUs: 1000000,
        measure: 0,
        beatInMeasure: 0,
        isDownbeat: true,
      );
      expect(beat.beatNumber, 0);
      expect(beat.isDownbeat, true);
      expect(beat.measure, 0);
      expect(beat.beatInMeasure, 0);
    });

    test('fromJson creates correct instance', () {
      final json = {
        'beatNumber': 5,
        'timestampUs': 2500000,
        'measure': 1,
        'beatInMeasure': 1,
        'isDownbeat': false,
      };
      final beat = BeatEvent.fromJson(json);
      expect(beat.beatNumber, 5);
      expect(beat.timestampUs, 2500000);
      expect(beat.measure, 1);
      expect(beat.beatInMeasure, 1);
      expect(beat.isDownbeat, false);
    });

    test('toJson produces correct map', () {
      const beat = BeatEvent(
        beatNumber: 3,
        timestampUs: 1500000,
        measure: 0,
        beatInMeasure: 3,
        isDownbeat: false,
      );
      final json = beat.toJson();
      expect(json['beatNumber'], 3);
      expect(json['timestampUs'], 1500000);
      expect(json['beatInMeasure'], 3);
      expect(json['isDownbeat'], false);
    });

    test('roundtrip fromJson/toJson', () {
      const original = BeatEvent(
        beatNumber: 7,
        timestampUs: 3500000,
        measure: 1,
        beatInMeasure: 3,
        isDownbeat: false,
      );
      final restored = BeatEvent.fromJson(original.toJson());
      expect(restored, original);
    });

    test('equality by value', () {
      const a = BeatEvent(
        beatNumber: 0,
        timestampUs: 1000,
        measure: 0,
        beatInMeasure: 0,
        isDownbeat: true,
      );
      const b = BeatEvent(
        beatNumber: 0,
        timestampUs: 1000,
        measure: 0,
        beatInMeasure: 0,
        isDownbeat: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('MetronomeSession', () {
    final sessionJson = {
      'sessionId': 'sess-123',
      'bandId': 'band-456',
      'bpm': 120,
      'timeSignature': {'beatsPerMeasure': 4, 'beatUnit': 4},
      'startTimeUs': 1000000000,
      'conductorId': 'user-789',
      'conductorName': 'Max Müller',
      'connectedClients': 12,
    };

    test('fromJson creates correct instance', () {
      final session = MetronomeSession.fromJson(sessionJson);
      expect(session.sessionId, 'sess-123');
      expect(session.bandId, 'band-456');
      expect(session.bpm, 120);
      expect(session.timeSignature.display, '4/4');
      expect(session.startTimeUs, 1000000000);
      expect(session.conductorId, 'user-789');
      expect(session.conductorName, 'Max Müller');
      expect(session.connectedClients, 12);
    });

    test('toJson produces correct map', () {
      final session = MetronomeSession.fromJson(sessionJson);
      final json = session.toJson();
      expect(json['sessionId'], 'sess-123');
      expect(json['bpm'], 120);
      expect(json['conductorName'], 'Max Müller');
    });

    test('fromJson handles missing optional fields', () {
      final minimalJson = {
        'sessionId': 'sess-1',
        'bandId': 'band-1',
        'bpm': 100,
        'timeSignature': {'beatsPerMeasure': 3, 'beatUnit': 4},
        'startTimeUs': 500000,
        'conductorId': 'user-1',
      };
      final session = MetronomeSession.fromJson(minimalJson);
      expect(session.conductorName, isNull);
      expect(session.connectedClients, 0);
    });

    test('copyWith updates fields', () {
      final session = MetronomeSession.fromJson(sessionJson);
      final updated = session.copyWith(bpm: 140, connectedClients: 15);
      expect(updated.bpm, 140);
      expect(updated.connectedClients, 15);
      expect(updated.sessionId, 'sess-123');
    });

    test('equality by sessionId', () {
      final a = MetronomeSession.fromJson(sessionJson);
      final b = MetronomeSession.fromJson(sessionJson);
      expect(a, b);
    });
  });

  group('MetronomeState', () {
    test('default state has sensible values', () {
      const state = MetronomeState();
      expect(state.isPlaying, false);
      expect(state.bpm, 120);
      expect(state.timeSignature.display, '4/4');
      expect(state.transport, MetronomeTransport.none);
      expect(state.connectionState, MetronomeConnectionState.disconnected);
      expect(state.session, isNull);
      expect(state.currentBeat, isNull);
      expect(state.connectedClients, 0);
      expect(state.isConductor, false);
      expect(state.audioClickEnabled, false);
      expect(state.latencyCompensationMs, 0);
      expect(state.error, isNull);
    });

    test('copyWith updates fields', () {
      const state = MetronomeState();
      final updated = state.copyWith(
        isPlaying: true,
        bpm: 140,
        isConductor: true,
        transport: MetronomeTransport.udp,
      );
      expect(updated.isPlaying, true);
      expect(updated.bpm, 140);
      expect(updated.isConductor, true);
      expect(updated.transport, MetronomeTransport.udp);
      // Unchanged fields preserved
      expect(updated.audioClickEnabled, false);
      expect(updated.latencyCompensationMs, 0);
    });

    test('copyWith can clear nullable fields with null', () {
      final state = MetronomeState(error: 'Some error');
      final cleared = state.copyWith(error: null);
      expect(cleared.error, isNull);
    });

    test('copyWith preserves nullable fields when not specified', () {
      final state = MetronomeState(error: 'Some error');
      final updated = state.copyWith(bpm: 100);
      expect(updated.error, 'Some error');
    });

    test('copyWith can set session to null', () {
      final session = MetronomeSession(
        sessionId: 's1',
        bandId: 'b1',
        bpm: 120,
        timeSignature: TimeSignature.common,
        startTimeUs: 1000,
        conductorId: 'c1',
      );
      final state = MetronomeState(session: session);
      expect(state.session, isNotNull);
      final cleared = state.copyWith(session: null);
      expect(cleared.session, isNull);
    });
  });

  group('ClockSyncState', () {
    test('default state has zero offset', () {
      const state = ClockSyncState();
      expect(state.serverOffsetUs, 0);
      expect(state.roundTripTimeUs, 0);
      expect(state.syncQuality, ClockSyncQuality.unknown);
      expect(state.lastSyncAt, isNull);
    });

    test('copyWith updates fields', () {
      const state = ClockSyncState();
      final now = DateTime.now();
      final updated = state.copyWith(
        serverOffsetUs: 500,
        roundTripTimeUs: 2000,
        syncQuality: ClockSyncQuality.good,
        lastSyncAt: now,
      );
      expect(updated.serverOffsetUs, 500);
      expect(updated.roundTripTimeUs, 2000);
      expect(updated.syncQuality, ClockSyncQuality.good);
      expect(updated.lastSyncAt, now);
    });
  });
}
