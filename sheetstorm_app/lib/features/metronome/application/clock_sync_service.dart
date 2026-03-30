import 'dart:math';

import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';

/// NTP-like clock synchronization service.
///
/// Calculates the offset between client and server clocks using
/// the standard NTP algorithm: offset = ((T2 - T1) + (T3 - T4)) / 2
///
/// Maintains a sliding window of measurements and uses median filtering
/// with outlier rejection for accuracy.
class ClockSyncService {
  final List<_SyncMeasurement> _measurements = [];
  static const _maxMeasurements = 10;

  ClockSyncState _state = const ClockSyncState();
  ClockSyncState get state => _state;

  int get measurementCount => _measurements.length;

  /// Calculate offset and round-trip time from a single sync exchange.
  SyncResult calculateOffset({
    required int clientSendTimeUs,
    required int serverRecvTimeUs,
    required int serverSendTimeUs,
    required int clientRecvTimeUs,
  }) {
    final roundTripUs =
        (clientRecvTimeUs - clientSendTimeUs) - (serverSendTimeUs - serverRecvTimeUs);
    final offsetUs =
        ((serverRecvTimeUs - clientSendTimeUs) + (serverSendTimeUs - clientRecvTimeUs)) ~/
            2;
    return SyncResult(offsetUs: offsetUs, roundTripUs: roundTripUs);
  }

  /// Add a measurement to the sliding window and update state.
  void addMeasurement({required int offsetUs, required int roundTripUs}) {
    _measurements.add(_SyncMeasurement(offsetUs: offsetUs, roundTripUs: roundTripUs));

    // Keep sliding window
    if (_measurements.length > _maxMeasurements) {
      _measurements.removeAt(0);
    }

    _updateState();
  }

  /// Reset all measurements.
  void reset() {
    _measurements.clear();
    _state = const ClockSyncState();
  }

  void _updateState() {
    if (_measurements.isEmpty) {
      _state = const ClockSyncState();
      return;
    }

    final filtered = _rejectOutliers(_measurements);
    final offsets = filtered.map((m) => m.offsetUs).toList()..sort();
    final rtts = filtered.map((m) => m.roundTripUs).toList()..sort();

    final medianOffset = _median(offsets);
    final medianRtt = _median(rtts);

    final quality = _classifyQuality(medianRtt);

    _state = ClockSyncState(
      serverOffsetUs: medianOffset,
      roundTripTimeUs: medianRtt,
      syncQuality: quality,
      lastSyncAt: DateTime.now(),
    );
  }

  List<_SyncMeasurement> _rejectOutliers(List<_SyncMeasurement> measurements) {
    if (measurements.length < 4) return measurements;

    final offsets = measurements.map((m) => m.offsetUs.toDouble()).toList();
    final mean = offsets.reduce((a, b) => a + b) / offsets.length;
    final variance =
        offsets.map((o) => (o - mean) * (o - mean)).reduce((a, b) => a + b) /
            offsets.length;
    final stdDev = sqrt(variance);

    if (stdDev == 0) return measurements;

    return measurements
        .where((m) => (m.offsetUs - mean).abs() <= 2 * stdDev)
        .toList();
  }

  int _median(List<int> sorted) {
    if (sorted.isEmpty) return 0;
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) ~/ 2;
  }

  ClockSyncQuality _classifyQuality(int rttUs) {
    if (rttUs < 5000) return ClockSyncQuality.good;
    if (rttUs < 20000) return ClockSyncQuality.acceptable;
    return ClockSyncQuality.poor;
  }
}

/// Result of a single clock sync measurement.
class SyncResult {
  final int offsetUs;
  final int roundTripUs;

  const SyncResult({required this.offsetUs, required this.roundTripUs});
}

class _SyncMeasurement {
  final int offsetUs;
  final int roundTripUs;

  const _SyncMeasurement({required this.offsetUs, required this.roundTripUs});
}
