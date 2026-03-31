import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_service.dart';

void main() {
  // ─── AnnotationRestService ───────────────────────────────────────────────

  group('AnnotationRestService — URL-Bau', () {
    test('buildAnnotationsUrl enthält bandId und piecePageId', () {
      final url = AnnotationRestService.buildAnnotationsUrl(
        'band-123',
        'page-456',
      );
      expect(url, '/api/bands/band-123/annotations/page-456');
    });

    test('buildElementsUrl enthält annotationId', () {
      final url = AnnotationRestService.buildElementsUrl(
        'band-123',
        'annot-789',
      );
      expect(url, '/api/bands/band-123/annotations/annot-789/elements');
    });

    test('buildElementUrl enthält elementId', () {
      final url = AnnotationRestService.buildElementUrl(
        'band-123',
        'annot-789',
        'elem-42',
      );
      expect(
          url, '/api/bands/band-123/annotations/annot-789/elements/elem-42');
    });

    test('buildSyncUrl enthält piecePageId', () {
      final url = AnnotationRestService.buildSyncUrl(
        'band-123',
        'page-456',
      );
      expect(url, '/api/bands/band-123/annotations/page-456/sync');
    });
  });

  // ─── AnnotationSignalRService — Message Framing ──────────────────────────

  group('AnnotationSignalRService — Message Framing', () {
    test('formatInvocation erzeugt korrektes SignalR-Format', () {
      final msg = AnnotationSignalRService.formatInvocation(
        'JoinAnnotationGroup',
        ['band-1', 'page-1', 'Voice', 'voice-1'],
      );
      expect(msg, contains('"type":1'));
      expect(msg, contains('"target":"JoinAnnotationGroup"'));
      expect(msg, contains('"arguments":["band-1","page-1","Voice","voice-1"]'));
      expect(msg, endsWith('\u001e'));
    });

    test('formatHandshake erzeugt JSON-Handshake', () {
      final msg = AnnotationSignalRService.formatHandshake();
      expect(msg, contains('"protocol":"json"'));
      expect(msg, contains('"version":1'));
      expect(msg, endsWith('\u001e'));
    });

    test('parseMessages splittet nach Record Separator', () {
      final raw = '{"type":1}\u001e{"type":6}\u001e';
      final messages = AnnotationSignalRService.parseMessages(raw);
      expect(messages, hasLength(2));
    });

    test('parseMessages ignoriert leere Segmente', () {
      final raw = '{"type":1}\u001e\u001e';
      final messages = AnnotationSignalRService.parseMessages(raw);
      expect(messages, hasLength(1));
    });

    test('buildWsUrl konvertiert http zu ws', () {
      final url = AnnotationSignalRService.buildWsUrl(
        'http://localhost:5000',
        'test-token',
      );
      expect(url, startsWith('ws://'));
      expect(url, contains('/hubs/annotation-sync'));
      expect(url, contains('access_token=test-token'));
    });

    test('buildWsUrl konvertiert https zu wss', () {
      final url = AnnotationSignalRService.buildWsUrl(
        'https://api.example.com',
        'my-token',
      );
      expect(url, startsWith('wss://'));
    });
  });

  // ─── Hub Group Names ─────────────────────────────────────────────────────

  group('Hub Group Names', () {
    test('voiceGroupName enthält bandId, voiceId, piecePageId', () {
      final name = AnnotationSignalRService.voiceGroupName(
        'band-1',
        'voice-2',
        'page-3',
      );
      expect(name, 'annotation-voice-band-1-voice-2-page-3');
    });

    test('orchestraGroupName enthält bandId und piecePageId', () {
      final name = AnnotationSignalRService.orchestraGroupName(
        'band-1',
        'page-3',
      );
      expect(name, 'annotation-orchestra-band-1-page-3');
    });
  });

  // ─── Server Event Parsing ────────────────────────────────────────────────

  group('Server Event Parsing', () {
    test('parseServerEvent erkennt OnElementAdded', () {
      final msg = {
        'type': 1,
        'target': 'OnElementAdded',
        'arguments': [
          {
            'id': 'elem-1',
            'annotationId': 'annot-1',
            'tool': 'pencil',
            'level': 'voice',
            'pageIndex': 0,
            'bbox': {'x': 0, 'y': 0, 'width': 0.1, 'height': 0.1},
            'opacity': 1.0,
            'strokeWidth': 3.0,
            'version': 1,
            'isDeleted': false,
            'userId': 'user-1',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'changedAt': '2026-01-01T00:00:00.000Z',
          }
        ],
      };
      final event = AnnotationSignalRService.parseServerEvent(msg);
      expect(event, isNotNull);
      expect(event!.type, ServerEventType.elementAdded);
      expect(event.element, isNotNull);
      expect(event.element!.id, 'elem-1');
    });

    test('parseServerEvent erkennt OnElementUpdated', () {
      final msg = {
        'type': 1,
        'target': 'OnElementUpdated',
        'arguments': [
          {
            'id': 'elem-1',
            'annotationId': 'annot-1',
            'tool': 'pencil',
            'level': 'voice',
            'pageIndex': 0,
            'bbox': {'x': 0, 'y': 0, 'width': 0.1, 'height': 0.1},
            'opacity': 1.0,
            'strokeWidth': 3.0,
            'version': 2,
            'isDeleted': false,
            'userId': 'user-1',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'changedAt': '2026-01-01T00:00:05.000Z',
          }
        ],
      };
      final event = AnnotationSignalRService.parseServerEvent(msg);
      expect(event!.type, ServerEventType.elementUpdated);
    });

    test('parseServerEvent erkennt OnElementDeleted', () {
      final msg = {
        'type': 1,
        'target': 'OnElementDeleted',
        'arguments': ['elem-1', 'annot-1'],
      };
      final event = AnnotationSignalRService.parseServerEvent(msg);
      expect(event!.type, ServerEventType.elementDeleted);
      expect(event.elementId, 'elem-1');
      expect(event.annotationId, 'annot-1');
    });

    test('parseServerEvent gibt null für Ping', () {
      final msg = {'type': 6};
      final event = AnnotationSignalRService.parseServerEvent(msg);
      expect(event, isNull);
    });

    test('parseServerEvent gibt null für unbekanntes Target', () {
      final msg = {'type': 1, 'target': 'UnknownMethod', 'arguments': []};
      final event = AnnotationSignalRService.parseServerEvent(msg);
      expect(event, isNull);
    });
  });

  // ─── Reconnect Policy ────────────────────────────────────────────────────

  group('Reconnect Policy', () {
    test('backoff-Delays folgen exponentiellem Schema', () {
      expect(AnnotationSignalRService.reconnectDelays, [
        const Duration(seconds: 1),
        const Duration(seconds: 3),
        const Duration(seconds: 10),
        const Duration(seconds: 30),
      ]);
    });

    test('maxReconnectAttempts ist 4', () {
      expect(AnnotationSignalRService.maxReconnectAttempts, 4);
    });
  });
}
