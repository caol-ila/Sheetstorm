// Transport auto-detection: scans for BLE session, falls back to SignalR.

import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_broadcast_service.dart';

part 'transport_detector.g.dart';

@riverpod
class TransportDetector extends _$TransportDetector {
  @override
  TransportType build() => TransportType.none;

  /// Detects the best available transport in priority order:
  /// BLE (if adapter on + session visible) → SignalR → none.
  Future<TransportType> detectBestTransport() async {
    state = TransportType.none;

    try {
      final isSupported = await FlutterBluePlus.isSupported;
      if (!isSupported) return _setAndReturn(TransportType.signalR);

      final adapterState = FlutterBluePlus.adapterStateNow;
      if (adapterState != BluetoothAdapterState.on) {
        return _setAndReturn(TransportType.signalR);
      }

      // Scan for the Sheetstorm BLE service (3-second window)
      final bleFound = await _scanForBleSession();
      if (bleFound) return _setAndReturn(TransportType.ble);
    } catch (_) {
      // BLE unavailable or permission denied — fall through to SignalR
    }

    return _setAndReturn(TransportType.signalR);
  }

  Future<bool> _scanForBleSession() async {
    final completer = Completer<bool>();
    StreamSubscription<List<ScanResult>>? sub;

    sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.advertisementData.serviceUuids
            .contains(BleBroadcastService.serviceUuid)) {
          if (!completer.isCompleted) completer.complete(true);
          sub?.cancel();
          return;
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        withServices: [BleBroadcastService.serviceUuid],
        timeout: const Duration(seconds: 3),
      );
    } catch (_) {
      await sub.cancel();
      return false;
    }

    final found = await Future.any([
      completer.future,
      Future.delayed(const Duration(seconds: 3), () => false),
    ]);

    await sub.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    return found;
  }

  TransportType _setAndReturn(TransportType type) {
    state = type;
    return type;
  }
}
