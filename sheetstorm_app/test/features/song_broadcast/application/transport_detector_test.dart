// Tests for TransportDetector Riverpod provider.
//
// Spec: docs/specs/2026-03-30-ble-broadcast-dirigent.md §5.2
//
// TransportDetector is a @riverpod class that auto-detects whether to use
// BLE (primary) or SignalR (fallback) based on hardware availability.
//
// NOTE: Full BLE detection tests require physical BLE hardware and cannot run
// in a standard CI/simulator environment. Hardware-dependent tests are marked.
//
// In the test environment (no BLE hardware):
//   - FlutterBluePlus.isSupported → false → detectBestTransport returns signalR
//   - The initial provider state is always TransportType.none

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/song_broadcast/application/transport_detector.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TransportDetector — provider state', () {
    test('initial state is TransportType.none', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(transportDetectorProvider);
      expect(state, equals(TransportType.none));
    });

    test('provider is accessible via transportDetectorProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(transportDetectorProvider), isA<TransportType>());
    });

    test('detectBestTransport() updates provider state (non-none result)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(transportDetectorProvider.notifier)
          .detectBestTransport();

      // After detection: state should be either ble or signalR — not none.
      // (In test env without BLE hardware, expects signalR.)
      final state = container.read(transportDetectorProvider);
      expect(state, isNot(equals(TransportType.none)));
    });

    test('detectBestTransport() in test environment (no BLE) returns signalR',
        () async {
      // Without real BLE hardware, FlutterBluePlus.isSupported is false or
      // throws — the implementation catches this and falls back to signalR.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container
          .read(transportDetectorProvider.notifier)
          .detectBestTransport();

      // In a test/simulator environment without BLE adapter, signalR is expected.
      // This test documents the fallback behaviour.
      expect(result, equals(TransportType.signalR));
    });

    test('multiple calls to detectBestTransport reflect latest result', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(transportDetectorProvider.notifier)
          .detectBestTransport();
      final first = container.read(transportDetectorProvider);

      await container
          .read(transportDetectorProvider.notifier)
          .detectBestTransport();
      final second = container.read(transportDetectorProvider);

      // Both calls should produce the same result in a stable environment
      expect(second, equals(first));
    });
  });

  // ─── TransportType enum ─────────────────────────────────────────────────────

  group('TransportType enum', () {
    test('has values: ble, signalR, none', () {
      expect(TransportType.values, containsAll([
        TransportType.ble,
        TransportType.signalR,
        TransportType.none,
      ]));
    });

    test('ble is preferred over signalR (ordinal ordering)', () {
      // BLE (index 0) precedes signalR (index 1) in priority — this drives
      // the preference logic in detectBestTransport.
      expect(
        TransportType.values.indexOf(TransportType.ble),
        lessThan(TransportType.values.indexOf(TransportType.signalR)),
      );
    });
  });
}
