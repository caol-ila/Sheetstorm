import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';

// These tests verify the state machine logic conceptually
// Real integration would require the CLI to be built

void main() {
  group('LabelingNotifier state transitions', () {
    test('initial state is idle', () {
      const state = LabelingState();
      expect(state.phase, LabelingPhase.idle);
    });

    test('state transitions to running', () {
      const state = LabelingState();
      final running = state.copyWith(phase: LabelingPhase.running);
      expect(running.phase, LabelingPhase.running);
    });

    test('state updates progress', () {
      const state = LabelingState(phase: LabelingPhase.running);
      final updated = state.copyWith(
        currentProgress: 5,
        totalItems: 10,
        currentFile: 'test.pdf',
      );
      
      expect(updated.currentProgress, 5);
      expect(updated.totalItems, 10);
      expect(updated.currentFile, 'test.pdf');
    });

    test('state accumulates results', () {
      const state = LabelingState(phase: LabelingPhase.running);
      const result = LabelingResult(
        originalPath: 'test.pdf',
        recognizedTitle: 'Test Title',
        confidence: 0.85,
        targetPath: 'target.pdf',
        status: ResultStatus.recognized,
      );

      final updated = state.copyWith(results: [result]);
      expect(updated.results.length, 1);
      expect(updated.results.first.recognizedTitle, 'Test Title');
    });

    test('state transitions to completed', () {
      const state = LabelingState(phase: LabelingPhase.running);
      final completed = state.copyWith(phase: LabelingPhase.completed);
      expect(completed.phase, LabelingPhase.completed);
    });

    test('state can be cancelled', () {
      const state = LabelingState(phase: LabelingPhase.running);
      final cancelled = state.copyWith(phase: LabelingPhase.cancelled);
      expect(cancelled.phase, LabelingPhase.cancelled);
    });

    test('state handles error', () {
      const state = LabelingState(phase: LabelingPhase.running);
      final error = state.copyWith(
        phase: LabelingPhase.error,
        errorMessage: 'Test error',
      );
      
      expect(error.phase, LabelingPhase.error);
      expect(error.errorMessage, 'Test error');
    });
  });

  group('LabelingResult status determination', () {
    test('high confidence is recognized', () {
      final status = LabelingResult.getStatus(0.85, null);
      expect(status, ResultStatus.recognized);
    });

    test('low confidence is flagged', () {
      final status = LabelingResult.getStatus(0.45, null);
      expect(status, ResultStatus.lowConfidence);
    });

    test('error overrides confidence', () {
      final status = LabelingResult.getStatus(0.95, 'Error occurred');
      expect(status, ResultStatus.error);
    });

    test('null confidence is error', () {
      final status = LabelingResult.getStatus(null, null);
      expect(status, ResultStatus.error);
    });
  });
}
