import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/auth/data/services/token_storage.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';

/// Verifiziert korrekte Ressourcenfreigabe von BroadcastSignalRService (CR#8).
///
/// Problem: dispose() existierte und schloss alle StreamController korrekt,
/// wurde aber nie aufgerufen, weil der Riverpod-Provider kein
/// ref.onDispose() registriert hatte. Das ist ein Memory-Leak.
void main() {
  group('BroadcastSignalRService dispose', () {
    BroadcastSignalRService buildService() =>
        BroadcastSignalRService(tokenStorage: TokenStorage());

    test('dispose() schließt den onSessionStarted-Stream', () async {
      final service = buildService();
      final done = Completer<void>();

      service.onSessionStarted.listen(null, onDone: done.complete);
      service.dispose();

      await expectLater(done.future, completes);
    });

    test('dispose() schließt den onSongChanged-Stream', () async {
      final service = buildService();
      final done = Completer<void>();

      service.onSongChanged.listen(null, onDone: done.complete);
      service.dispose();

      await expectLater(done.future, completes);
    });

    test('dispose() schließt den onSessionEnded-Stream', () async {
      final service = buildService();
      final done = Completer<void>();

      service.onSessionEnded.listen(null, onDone: done.complete);
      service.dispose();

      await expectLater(done.future, completes);
    });

    test('dispose() schließt den onConnectionCountUpdated-Stream', () async {
      final service = buildService();
      final done = Completer<void>();

      service.onConnectionCountUpdated.listen(null, onDone: done.complete);
      service.dispose();

      await expectLater(done.future, completes);
    });

    test('dispose() schließt den onConnectionStateChanged-Stream', () async {
      final service = buildService();
      final done = Completer<void>();

      service.onConnectionStateChanged.listen(null, onDone: done.complete);
      service.dispose();

      await expectLater(done.future, completes);
    });

    test('dispose() kann sicher mehrfach aufgerufen werden (idempotent)', () {
      final service = buildService();

      expect(() {
        service.dispose();
        service.dispose();
      }, returnsNormally);
    });

    test('disconnect() schließt Streams NICHT — nur dispose() darf das', () async {
      final service = buildService();

      var streamClosed = false;
      service.onConnectionStateChanged.listen(
        null,
        onDone: () => streamClosed = true,
      );

      // disconnect() ohne aktive Verbindung soll nicht crashen
      await service.disconnect();

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(streamClosed, isFalse,
          reason: 'disconnect() darf StreamController NICHT schließen; nur dispose()');

      service.dispose();
    });
  });
}
