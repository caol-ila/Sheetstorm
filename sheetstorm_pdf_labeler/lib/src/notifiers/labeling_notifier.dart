import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';
import 'package:sheetstorm_pdf_labeler/src/services/labeling_service.dart';

final labelingProvider = StateNotifierProvider<LabelingNotifier, AsyncValue<LabelingState>>(
  (ref) => LabelingNotifier(),
);

class LabelingNotifier extends StateNotifier<AsyncValue<LabelingState>> {
  LabelingNotifier() : _service = LabelingService(), super(const AsyncValue.data(LabelingState()));

  LabelingNotifier.withService(this._service)
      : super(const AsyncValue.data(LabelingState()));

  final LabelingService _service;
  StreamSubscription<LabelingEvent>? _subscription;

  void startLabeling({
    required String source,
    required String target,
    required String pat,
    double confidence = 0.6,
  }) {
    state = const AsyncValue.loading();
    state = AsyncValue.data(LabelingState(
      phase: LabelingPhase.running,
      sourcePath: source,
      targetPath: target,
    ));

    final stream = _service.run(
      source: source,
      target: target,
      pat: pat,
      confidence: confidence,
    );

    _subscription = stream.listen(
      (event) {
        _handleEvent(event);
      },
      onError: (error) {
        state = AsyncValue.data(
          state.value!.copyWith(
            phase: LabelingPhase.error,
            errorMessage: error.toString(),
          ),
        );
      },
      onDone: () {
        if (state.value?.phase == LabelingPhase.running) {
          state = AsyncValue.data(
            state.value!.copyWith(phase: LabelingPhase.completed),
          );
        }
      },
    );
  }

  void _handleEvent(LabelingEvent event) {
    final currentState = state.value;
    if (currentState == null) return;

    switch (event) {
      case ProgressEvent():
        state = AsyncValue.data(
          currentState.copyWith(
            currentProgress: event.current,
            totalItems: event.total,
            currentFile: event.currentFile,
          ),
        );

      case ResultEvent():
        final result = LabelingResult(
          originalPath: event.originalPath,
          recognizedTitle: event.recognizedTitle,
          confidence: event.confidence,
          targetPath: event.targetPath,
          error: event.error,
          status: LabelingResult.getStatus(event.confidence, event.error),
        );

        state = AsyncValue.data(
          currentState.copyWith(
            results: [...currentState.results, result],
          ),
        );

      case ErrorEvent():
        state = AsyncValue.data(
          currentState.copyWith(
            phase: LabelingPhase.error,
            errorMessage: event.message,
          ),
        );

      case DoneEvent():
        state = AsyncValue.data(
          currentState.copyWith(phase: LabelingPhase.completed),
        );
    }
  }

  void cancel() {
    _service.cancel();
    _subscription?.cancel();
    
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(
        currentState.copyWith(phase: LabelingPhase.cancelled),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

