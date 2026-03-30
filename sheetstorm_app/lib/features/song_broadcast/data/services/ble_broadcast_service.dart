// BLE broadcast transport implementing IBroadcastTransport.
//
// Conductor (Dirigent) mode: BLE Peripheral — advertises the Sheetstorm GATT
//   service and sends notifications to connected musician devices.
//
// Musician mode: BLE Central — scans for the Sheetstorm service, connects,
//   and subscribes to characteristic notifications.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sheetstorm/features/song_broadcast/data/models/ble_message_codec.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/ble_security_service.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_transport.dart';

part 'ble_broadcast_service.g.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
BleBroadcastService bleBroadcastService(Ref ref) {
  final service = BleBroadcastService();
  ref.onDispose(service.dispose);
  return service;
}

// ─── GATT UUIDs ───────────────────────────────────────────────────────────────

// ─── BLE Broadcast Service ────────────────────────────────────────────────────

class BleBroadcastService implements IBroadcastTransport {
  // Sheetstorm GATT service + characteristic UUIDs (prefix "SS" = 0x5353)
  static final serviceUuid =
      Guid('53530001-0000-1000-8000-00805f9b34fb');
  static final songCharUuid =
      Guid('53530002-0000-1000-8000-00805f9b34fb');
  static final metronomeCharUuid =
      Guid('53530003-0000-1000-8000-00805f9b34fb');
  static final annotationCharUuid =
      Guid('53530004-0000-1000-8000-00805f9b34fb');
  static final sessionControlCharUuid =
      Guid('53530005-0000-1000-8000-00805f9b34fb');
  static final securityCharUuid =
      Guid('53530006-0000-1000-8000-00805f9b34fb');

  // Internal state
  BleSessionInfo? _sessionInfo;
  BleSecurityService? _security;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _songChar;
  BluetoothCharacteristic? _metronomeChar;
  BluetoothCharacteristic? _annotationChar;
  BluetoothCharacteristic? _sessionControlChar;

  final BleMessageCodec _codec = BleMessageCodec();
  int _sequenceNumber = 0;
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  TransportConnectionState _connectionState =
      TransportConnectionState.disconnected;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  // ─── Stream controllers ──────────────────────────────────────────────────

  final _songChangedController =
      StreamController<SongChangedPayload>.broadcast();
  final _metronomeController =
      StreamController<MetronomeBeatPayload>.broadcast();
  final _annotationController =
      StreamController<AnnotationInvalidationPayload>.broadcast();
  final _sessionControlController =
      StreamController<SessionControlPayload>.broadcast();
  final _connectionStateController =
      StreamController<TransportConnectionState>.broadcast();

  // ─── IBroadcastTransport ─────────────────────────────────────────────────

  @override
  TransportType get transportType => TransportType.ble;

  @override
  TransportConnectionState get connectionState => _connectionState;

  @override
  Stream<SongChangedPayload> get onSongChanged =>
      _songChangedController.stream;

  @override
  Stream<MetronomeBeatPayload> get onMetronomeBeat =>
      _metronomeController.stream;

  @override
  Stream<AnnotationInvalidationPayload> get onAnnotationInvalidated =>
      _annotationController.stream;

  @override
  Stream<SessionControlPayload> get onSessionControl =>
      _sessionControlController.stream;

  @override
  Stream<TransportConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  // ─── Connect (Musician / Central mode) ───────────────────────────────────

  @override
  Future<void> connect([BleSessionInfo? sessionInfo]) async {
    if (sessionInfo == null) {
      throw ArgumentError('BLE transport requires a valid BleSessionInfo.');
    }
    _sessionInfo = sessionInfo;
    _security = BleSecurityService(
      sessionKey: base64Decode(sessionInfo.sessionKey),
      leaderDeviceId: sessionInfo.leaderDeviceId,
    );
    await scanAndConnect(const Duration(seconds: 10));
  }

  /// Scans for the Sheetstorm GATT service and connects as a musician (Central).
  Future<void> scanAndConnect(Duration timeout) async {
    _setConnectionState(TransportConnectionState.connecting);

    try {
      final completer = Completer<BluetoothDevice>();

      final scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.advertisementData.serviceUuids.contains(serviceUuid) &&
              !completer.isCompleted) {
            completer.complete(r.device);
          }
        }
      });

      await FlutterBluePlus.startScan(
        withServices: [serviceUuid],
        timeout: timeout,
      );

      final device = await completer.future.timeout(
        timeout,
        onTimeout: () {
          scanSub.cancel();
          throw TimeoutException('Kein BLE-Dirigent in Reichweite gefunden.');
        },
      );

      await scanSub.cancel();
      await FlutterBluePlus.stopScan();

      await connectAsCentral(_sessionInfo!, device: device);
    } catch (e) {
      _setConnectionState(TransportConnectionState.disconnected);
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BLE] Scan/connect error: $e');
      }
      rethrow;
    }
  }

  /// Connects to a specific [device] as a musician (Central / GATT client).
  Future<void> connectAsCentral(
    BleSessionInfo sessionInfo, {
    BluetoothDevice? device,
  }) async {
    final target = device ?? _connectedDevice;
    if (target == null) return;

    await target.connect(autoConnect: false);
    _connectedDevice = target;

    _subscriptions.add(
      target.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _setConnectionState(TransportConnectionState.disconnected);
          _attemptReconnect();
        }
      }),
    );

    final services = await target.discoverServices();
    final ssService = services.firstWhere(
      (s) => s.uuid == serviceUuid,
      orElse: () => throw StateError('Sheetstorm GATT-Service nicht gefunden.'),
    );

    for (final char in ssService.characteristics) {
      if (char.uuid == songCharUuid) {
        _songChar = char;
        await char.setNotifyValue(true);
        _subscriptions.add(
          char.onValueReceived.listen(_onSongCharValue),
        );
      } else if (char.uuid == metronomeCharUuid) {
        _metronomeChar = char;
        await char.setNotifyValue(true);
        _subscriptions.add(
          char.onValueReceived.listen(_onMetronomeCharValue),
        );
      } else if (char.uuid == annotationCharUuid) {
        _annotationChar = char;
        await char.setNotifyValue(true);
        _subscriptions.add(
          char.onValueReceived.listen(_onAnnotationCharValue),
        );
      } else if (char.uuid == sessionControlCharUuid) {
        _sessionControlChar = char;
        await char.setNotifyValue(true);
        _subscriptions.add(
          char.onValueReceived.listen(_onSessionControlCharValue),
        );
      }
    }

    _setConnectionState(TransportConnectionState.connected);
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  @override
  Future<void> disconnect() async {
    _cancelSubscriptions();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _songChar = null;
    _metronomeChar = null;
    _annotationChar = null;
    _sessionControlChar = null;
    await stopPeripheral();
    _setConnectionState(TransportConnectionState.disconnected);
  }

  // ─── Conductor send actions ───────────────────────────────────────────────

  @override
  Future<void> sendSongChanged(String stueckId, String stueckTitel) async {
    final payload = _codec.encodeSongChanged(stueckId, stueckTitel, _nextSeq());
    await _writeToChar(_songChar, payload);
  }

  @override
  Future<void> sendMetronomeBeat(MetronomeBeatPayload beat) async {
    final payload = _codec.encodeMetronomeBeat(beat, _nextSeq());
    await _writeToChar(_metronomeChar, payload);
  }

  @override
  Future<void> sendAnnotationInvalidation(
    AnnotationInvalidationPayload payload,
  ) async {
    final bytes =
        _codec.encodeAnnotationInvalidation(payload, _nextSeq());
    await _writeToChar(_annotationChar, bytes);
  }

  @override
  Future<void> sendSessionControl(SessionControlType type) async {
    final payload = _codec.encodeSessionControl(type, _nextSeq());
    await _writeToChar(_sessionControlChar, payload);
  }

  // ─── Peripheral mode (Conductor / GATT server) ───────────────────────────

  /// Starts BLE advertising as a conductor (Peripheral mode).
  /// Note: Full GATT server characteristics require native platform support.
  Future<void> startAsPeripheral(BleSessionInfo sessionInfo) async {
    _sessionInfo = sessionInfo;
    _security = BleSecurityService(
      sessionKey: base64Decode(sessionInfo.sessionKey),
      leaderDeviceId: sessionInfo.leaderDeviceId,
    );

    final advertiseData = AdvertiseData(
      serviceUuid: '53530001-0000-1000-8000-00805f9b34fb',
      includeDeviceName: false,
      localName: 'SS-Dirigent',
    );

    await _peripheral.start(advertiseData: advertiseData);
    _setConnectionState(TransportConnectionState.connected);
  }

  Future<void> stopPeripheral() async {
    try {
      if (await _peripheral.isAdvertising) {
        await _peripheral.stop();
      }
    } catch (_) {
      // Ignore stop errors
    }
  }

  // ─── Characteristic value handlers ───────────────────────────────────────

  void _onSongCharValue(List<int> raw) {
    try {
      final msg = _codec.decode(Uint8List.fromList(raw));
      final (stueckId, stueckTitel) = _codec.decodeSongChanged(msg.payload);
      _songChangedController.add(SongChangedPayload(
        sessionId: _sessionInfo?.leaderDeviceId ?? '',
        stueckId: stueckId,
        stueckTitel: stueckTitel,
        timestamp: DateTime.fromMillisecondsSinceEpoch(msg.timestamp * 1000),
      ));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BLE] Song char decode error: $e');
      }
    }
  }

  void _onMetronomeCharValue(List<int> raw) {
    try {
      final msg = _codec.decode(Uint8List.fromList(raw));
      final beat = MetronomeBeatPayload.fromBytes(msg.payload);
      _metronomeController.add(beat);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BLE] Metronome char decode error: $e');
      }
    }
  }

  void _onAnnotationCharValue(List<int> raw) {
    try {
      final msg = _codec.decode(Uint8List.fromList(raw));
      final payload = _codec.decodeAnnotationInvalidation(msg.payload);
      _annotationController.add(payload);
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BLE] Annotation char decode error: $e');
      }
    }
  }

  void _onSessionControlCharValue(List<int> raw) {
    try {
      final msg = _codec.decode(Uint8List.fromList(raw));
      final type = _codec.decodeSessionControl(msg.messageType);
      _sessionControlController.add(SessionControlPayload(
        type: type,
        timestamp: DateTime.fromMillisecondsSinceEpoch(msg.timestamp * 1000),
      ));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[BLE] Session control char decode error: $e');
      }
    }
  }

  // ─── Reconnect ────────────────────────────────────────────────────────────

  void _attemptReconnect() {
    if (_connectionState == TransportConnectionState.disconnected &&
        _sessionInfo != null) {
      _setConnectionState(TransportConnectionState.reconnecting);
      Future.delayed(const Duration(seconds: 2), () async {
        if (_connectionState == TransportConnectionState.reconnecting) {
          try {
            await scanAndConnect(const Duration(seconds: 5));
          } catch (_) {
            _setConnectionState(TransportConnectionState.disconnected);
          }
        }
      });
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  int _nextSeq() {
    _sequenceNumber = (_sequenceNumber + 1) & 0xFFFF;
    return _sequenceNumber;
  }

  Future<void> _writeToChar(
    BluetoothCharacteristic? char,
    Uint8List data,
  ) async {
    if (char == null) return;
    final signed = _security?.signAndAppend(data) ?? data;
    await char.write(signed, withoutResponse: true);
  }

  void _setConnectionState(TransportConnectionState newState) {
    if (_connectionState == newState) return;
    _connectionState = newState;
    _connectionStateController.add(newState);
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void dispose() {
    _cancelSubscriptions();
    _songChangedController.close();
    _metronomeController.close();
    _annotationController.close();
    _sessionControlController.close();
    _connectionStateController.close();
  }
}
