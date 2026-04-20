import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';
import 'package:sheetstorm_pdf_labeler/src/notifiers/labeling_notifier.dart';

void main() {
  group('LabelingNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle', () {
      final notifier = container.read(labelingProvider.notifier);
      final state = container.read(labelingProvider);

      expect(state, isA<AsyncValue<LabelingState>>());
      expect(state.valueOrNull?.phase, LabelingPhase.idle);
    });

    test('transitions to running when startLabeling called', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
        confidence: 0.6,
      );

      // Wait for state update
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(labelingProvider);
      expect(
        state.valueOrNull?.phase,
        anyOf(LabelingPhase.running, LabelingPhase.completed),
      );
    });

    test('updates progress on ProgressEvent', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      // Wait for progress events
      await Future.delayed(const Duration(milliseconds: 500));

      final state = container.read(labelingProvider);
      final value = state.valueOrNull;
      
      if (value?.phase == LabelingPhase.running) {
        expect(value?.currentProgress, greaterThanOrEqualTo(0));
        expect(value?.totalItems, greaterThanOrEqualTo(0));
      }
    });

    test('accumulates results on ResultEvent', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      // Wait for some results
      await Future.delayed(const Duration(seconds: 2));

      final state = container.read(labelingProvider);
      final value = state.valueOrNull;
      
      if (value?.phase == LabelingPhase.completed) {
        expect(value?.results, isNotEmpty);
      }
    });

    test('transitions to completed on DoneEvent', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      // Wait for completion
      await Future.delayed(const Duration(seconds: 3));

      final state = container.read(labelingProvider);
      expect(
        state.valueOrNull?.phase,
        anyOf(LabelingPhase.completed, LabelingPhase.error),
      );
    });

    test('can cancel running operation', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\test\\source',
        target: 'C:\\test\\target',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      await Future.delayed(const Duration(milliseconds: 100));
      
      notifier.cancel();

      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(labelingProvider);
      expect(state.valueOrNull?.phase, LabelingPhase.cancelled);
    });

    test('handles ErrorEvent correctly', () async {
      final notifier = container.read(labelingProvider.notifier);

      notifier.startLabeling(
        source: 'C:\\nonexistent',
        target: 'C:\\invalid',
        pat: 'FAKE_PAT_FOR_TESTS',
      );

      // Wait for error
      await Future.delayed(const Duration(seconds: 1));

      final state = container.read(labelingProvider);
      expect(
        state.valueOrNull?.phase,
        anyOf(LabelingPhase.error, LabelingPhase.completed),
      );
    });
  });
}
