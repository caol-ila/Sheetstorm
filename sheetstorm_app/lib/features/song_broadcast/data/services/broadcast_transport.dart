// Transport abstraction layer for BLE and SignalR broadcast transports.

import 'package:sheetstorm/features/song_broadcast/data/models/ble_models.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';

/// Common interface for all broadcast transports (BLE + SignalR).
///
/// The [connect] parameter [sessionInfo] is required for BLE but may be null
/// for SignalR (which uses JWT from secure storage instead).
abstract class IBroadcastTransport {
  Future<void> connect([BleSessionInfo? sessionInfo]);
  Future<void> disconnect();

  // ─── Conductor actions ─────────────────────────────────────────────────────

  Future<void> sendSongChanged(String stueckId, String stueckTitel);
  Future<void> sendMetronomeBeat(MetronomeBeatPayload beat);
  Future<void> sendAnnotationInvalidation(AnnotationInvalidationPayload payload);
  Future<void> sendSessionControl(SessionControlType type);

  // ─── Event streams (musician side) ────────────────────────────────────────

  Stream<SongChangedPayload> get onSongChanged;
  Stream<MetronomeBeatPayload> get onMetronomeBeat;
  Stream<AnnotationInvalidationPayload> get onAnnotationInvalidated;
  Stream<SessionControlPayload> get onSessionControl;
  Stream<TransportConnectionState> get onConnectionStateChanged;

  TransportConnectionState get connectionState;
  TransportType get transportType;
}
