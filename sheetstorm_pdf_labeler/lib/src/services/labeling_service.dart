import 'dart:async';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';

class LabelingService {
  Stream<LabelingEvent> run({
    required String source,
    required String target,
    required String pat,
    double confidence = 0.6,
  }) {
    // RED: Not implemented yet
    throw UnimplementedError('LabelingService.run() not implemented');
  }

  void cancel() {
    throw UnimplementedError('LabelingService.cancel() not implemented');
  }
}
