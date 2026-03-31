import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/metronome/application/clock_sync_service.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

void main() {
  group('ClockSyncService', () {
    late ClockSyncService service;

    setUp(() {
      service = ClockSyncService();
    });

    group('calculateOffset', () {
      test('returns correct offset for zero-latency case', () {
        // T1=100, T2=100, T3=100, T4=100 → offset=0, rtt=0
        final result = service.calculateOffset(
          clientSendTimeUs: 100,
          serverRecvTimeUs: 100,
          serverSendTimeUs: 100,
          clientRecvTimeUs: 100,
        );
        expect(result.offsetUs, 0);
        expect(result.roundTripUs, 0);
      });

      test('returns correct offset when server is ahead', () {
        // T1=1000, T2=1500, T3=1500, T4=2000
        // RTT = (2000-1000) - (1500-1500) = 1000
        // offset = ((1500-1000) + (1500-2000)) / 2 = (500 + (-500)) / 2 = 0
        final result = service.calculateOffset(
          clientSendTimeUs: 1000,
          serverRecvTimeUs: 1500,
          serverSendTimeUs: 1500,
          clientRecvTimeUs: 2000,
        );
        expect(result.roundTripUs, 1000);
        expect(result.offsetUs, 0);
      });

      test('detects server clock ahead', () {
        // T1=0, T2=5000, T3=5000, T4=1000
        // RTT = (1000-0) - (5000-5000) = 1000
        // offset = ((5000-0) + (5000-1000)) / 2 = (5000 + 4000) / 2 = 4500
        final result = service.calculateOffset(
          clientSendTimeUs: 0,
          serverRecvTimeUs: 5000,
          serverSendTimeUs: 5000,
          clientRecvTimeUs: 1000,
        );
        expect(result.roundTripUs, 1000);
        expect(result.offsetUs, 4500);
      });

      test('detects server clock behind', () {
        // T1=5000, T2=1000, T3=1000, T4=6000
        // RTT = (6000-5000) - (1000-1000) = 1000
        // offset = ((1000-5000) + (1000-6000)) / 2 = (-4000 + (-5000)) / 2 = -4500
        final result = service.calculateOffset(
          clientSendTimeUs: 5000,
          serverRecvTimeUs: 1000,
          serverSendTimeUs: 1000,
          clientRecvTimeUs: 6000,
        );
        expect(result.roundTripUs, 1000);
        expect(result.offsetUs, -4500);
      });
    });

    group('addMeasurement', () {
      test('first measurement updates state', () {
        service.addMeasurement(offsetUs: 500, roundTripUs: 1000);
        final state = service.state;
        expect(state.serverOffsetUs, 500);
        expect(state.roundTripTimeUs, 1000);
      });

      test('median of multiple measurements', () {
        service.addMeasurement(offsetUs: 100, roundTripUs: 200);
        service.addMeasurement(offsetUs: 300, roundTripUs: 600);
        service.addMeasurement(offsetUs: 200, roundTripUs: 400);
        final state = service.state;
        // Median of [100, 200, 300] = 200
        expect(state.serverOffsetUs, 200);
      });

      test('outlier rejection beyond 2 sigma', () {
        // Add 5 normal measurements + 1 outlier
        service.addMeasurement(offsetUs: 100, roundTripUs: 200);
        service.addMeasurement(offsetUs: 102, roundTripUs: 204);
        service.addMeasurement(offsetUs: 98, roundTripUs: 196);
        service.addMeasurement(offsetUs: 101, roundTripUs: 202);
        service.addMeasurement(offsetUs: 99, roundTripUs: 198);
        // Outlier — should be rejected
        service.addMeasurement(offsetUs: 50000, roundTripUs: 100000);
        final state = service.state;
        // Should still be ~100, not skewed by outlier
        expect(state.serverOffsetUs, lessThan(200));
      });

      test('keeps sliding window of max 10 measurements', () {
        for (var i = 0; i < 15; i++) {
          service.addMeasurement(offsetUs: i * 100, roundTripUs: 200);
        }
        expect(service.measurementCount, lessThanOrEqualTo(10));
      });
    });

    group('syncQuality', () {
      test('unknown when no measurements', () {
        expect(service.state.syncQuality, ClockSyncQuality.unknown);
      });

      test('good when RTT < 5ms', () {
        service.addMeasurement(offsetUs: 100, roundTripUs: 3000);
        expect(service.state.syncQuality, ClockSyncQuality.good);
      });

      test('acceptable when RTT 5-20ms', () {
        service.addMeasurement(offsetUs: 100, roundTripUs: 10000);
        expect(service.state.syncQuality, ClockSyncQuality.acceptable);
      });

      test('poor when RTT > 20ms', () {
        service.addMeasurement(offsetUs: 100, roundTripUs: 25000);
        expect(service.state.syncQuality, ClockSyncQuality.poor);
      });
    });

    group('reset', () {
      test('clears all measurements', () {
        service.addMeasurement(offsetUs: 100, roundTripUs: 200);
        service.reset();
        expect(service.state.syncQuality, ClockSyncQuality.unknown);
        expect(service.state.serverOffsetUs, 0);
        expect(service.measurementCount, 0);
      });
    });
  });
}
