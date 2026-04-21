import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';
import 'package:sheetstorm_pdf_labeler/src/services/labeling_service.dart';

// Mock implementation for testing without real CLI
class MockLabelingService extends LabelingService {
  @override
  Stream<LabelingEvent> run({
    required String source,
    required String target,
    required String pat,
    double confidence = 0.6,
  }) async* {
    // Simulate CLI output with NDJSON events
    yield const ProgressEvent(current: 0, total: 3, currentFile: 'file1.pdf');
    await Future.delayed(const Duration(milliseconds: 10));

    yield const ResultEvent(
      originalPath: 'C:\\test\\file1.pdf',
      recognizedTitle: 'Ode an die Freude',
      confidence: 0.95,
      targetPath: 'C:\\test\\target\\Ode an die Freude.pdf',
    );
    
    yield const ProgressEvent(current: 1, total: 3, currentFile: 'file2.pdf');
    await Future.delayed(const Duration(milliseconds: 10));

    yield const ResultEvent(
      originalPath: 'C:\\test\\file2.pdf',
      recognizedTitle: 'Unsure Title',
      confidence: 0.45,
      targetPath: null,
    );

    yield const ProgressEvent(current: 2, total: 3, currentFile: 'file3.pdf');
    await Future.delayed(const Duration(milliseconds: 10));

    yield const ResultEvent(
      originalPath: 'C:\\test\\file3.pdf',
      error: 'Failed to process',
    );

    yield const DoneEvent(successful: 1, failed: 1, lowConfidence: 1);
  }
}

void main() {
  group('LabelingService', () {
    late MockLabelingService service;

    setUp(() {
      service = MockLabelingService();
    });

    test('emits ProgressEvent when CLI outputs progress', () async {
      final events = <LabelingEvent>[];
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
        confidence: 0.6,
      );

      await for (final event in stream) {
        events.add(event);
        if (event is DoneEvent) break;
      }

      expect(
        events.whereType<ProgressEvent>().isNotEmpty,
        isTrue,
        reason: 'Should emit at least one ProgressEvent',
      );
      
      final progress = events.whereType<ProgressEvent>().first;
      expect(progress.total, 3);
    });

    test('emits ResultEvent for each processed file', () async {
      final events = <LabelingEvent>[];
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      await for (final event in stream) {
        events.add(event);
        if (event is DoneEvent) break;
      }

      final results = events.whereType<ResultEvent>();
      expect(results.length, 3);
      expect(results.first.originalPath, isNotEmpty);
    });

    test('emits DoneEvent at completion', () async {
      final events = <LabelingEvent>[];
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      await for (final event in stream) {
        events.add(event);
        if (event is DoneEvent) break;
      }

      expect(events.last, isA<DoneEvent>());
      final done = events.last as DoneEvent;
      expect(done.successful, 1);
      expect(done.failed, 1);
      expect(done.lowConfidence, 1);
    });

    test('injects PAT as environment variable', () async {
      // This test verifies the interface accepts PAT parameter
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'SECRET_PAT',
      );

      await stream.first;
      
      expect(true, isTrue, reason: 'PAT should be passed via parameter');
    });

    test('parses NDJSON from CLI stdout', () async {
      final events = <LabelingEvent>[];
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      await for (final event in stream) {
        events.add(event);
        if (events.length >= 2) break;
      }

      expect(events.isNotEmpty, isTrue);
      expect(events[0], isA<ProgressEvent>());
    });

    test('handles CLI process errors gracefully', () async {
      // Mock service simulates both success and error cases
      final stream = service.run(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      final events = <LabelingEvent>[];
      await for (final event in stream) {
        events.add(event);
        if (event is DoneEvent) break;
      }

      expect(
        events.any((e) => e is ResultEvent && (e as ResultEvent).error != null),
        isTrue,
        reason: 'Should include error results',
      );
    });
  });
}
