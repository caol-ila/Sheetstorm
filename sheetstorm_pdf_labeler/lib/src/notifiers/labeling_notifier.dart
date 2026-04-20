import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';

final labelingProvider = StateNotifierProvider<LabelingNotifier, AsyncValue<LabelingState>>(
  (ref) => LabelingNotifier(),
);

class LabelingNotifier extends StateNotifier<AsyncValue<LabelingState>> {
  LabelingNotifier() : super(const AsyncValue.data(LabelingState()));

  void startLabeling({
    required String source,
    required String target,
    required String pat,
    double confidence = 0.6,
  }) {
    // RED: Not implemented yet
    throw UnimplementedError('LabelingNotifier.startLabeling() not implemented');
  }

  void cancel() {
    throw UnimplementedError('LabelingNotifier.cancel() not implemented');
  }
}
