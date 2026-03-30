import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/application/transport_detector.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

// Spec reference: docs/specs/2026-03-30-ble-broadcast-dirigent.md §5.2
//
// Auto-detection priority:
//   1. BLE available AND conductor session found → TransportType.ble
//   2. Server reachable → TransportType.signalR
//   3. Neither → TransportType.none
//
// TransportDetector accepts injectable callbacks so it can be tested without
// BLE hardware or a real server:
//   - checkBleAvailable:    () async => bool
//   - scanForSession:       (Duration timeout) async => BleSessionInfo?
//   - checkServerReachable: () async => bool

BleSessionInfo _fakeBleSession() => BleSessionInfo(
      sessionKey: 'dGVzdGtleQ==', // base64 "testkey"
      leaderDeviceId: 'leader-device-id',
      expiresAt: DateTime.now().add(const Duration(hours: 4)),
      authenticatedDevices: {'leader-device-id'},
    );

void main() {
  group('TransportDetector', () {
    test('returns ble when BLE is available and session found', () async {
      final detector = TransportDetector(
        checkBleAvailable: () async => true,
        scanForSession: (_) async => _fakeBleSession(),
        checkServerReachable: () async => false,
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.ble));
    });

    test('returns signalR when BLE not available but server reachable', () async {
      final detector = TransportDetector(
        checkBleAvailable: () async => false,
        scanForSession: (_) async => null,
        checkServerReachable: () async => true,
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.signalR));
    });

    test('returns none when neither BLE nor server available', () async {
      final detector = TransportDetector(
        checkBleAvailable: () async => false,
        scanForSession: (_) async => null,
        checkServerReachable: () async => false,
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.none));
    });

    test('prefers BLE over SignalR when both available', () async {
      final detector = TransportDetector(
        checkBleAvailable: () async => true,
        scanForSession: (_) async => _fakeBleSession(),
        checkServerReachable: () async => true, // server also reachable
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.ble),
          reason: 'BLE should take priority when both transports are available');
    });

    test('falls back to SignalR after BLE scan finds no session', () async {
      // BLE hardware available but no conductor advertising
      final detector = TransportDetector(
        checkBleAvailable: () async => true,
        scanForSession: (_) async => null, // scan timeout — no session found
        checkServerReachable: () async => true,
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.signalR));
    });

    test('returns none when BLE available but no session and server unreachable',
        () async {
      final detector = TransportDetector(
        checkBleAvailable: () async => true,
        scanForSession: (_) async => null,
        checkServerReachable: () async => false,
      );

      final result = await detector.detectBestTransport();

      expect(result, equals(TransportType.none));
    });

    test('passes configured scan timeout to scanForSession', () async {
      Duration? capturedTimeout;
      final detector = TransportDetector(
        checkBleAvailable: () async => true,
        scanForSession: (timeout) async {
          capturedTimeout = timeout;
          return null;
        },
        checkServerReachable: () async => false,
      );

      const expectedTimeout = Duration(seconds: 5);
      await detector.detectBestTransport(scanTimeout: expectedTimeout);

      expect(capturedTimeout, equals(expectedTimeout));
    });
  });
}
