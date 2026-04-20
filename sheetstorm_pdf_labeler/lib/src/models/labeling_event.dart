sealed class LabelingEvent {
  const LabelingEvent();
}

class ProgressEvent extends LabelingEvent {
  final int current;
  final int total;
  final String currentFile;

  const ProgressEvent({
    required this.current,
    required this.total,
    required this.currentFile,
  });
}

class ResultEvent extends LabelingEvent {
  final String originalPath;
  final String? recognizedTitle;
  final double? confidence;
  final String? targetPath;
  final String? error;

  const ResultEvent({
    required this.originalPath,
    this.recognizedTitle,
    this.confidence,
    this.targetPath,
    this.error,
  });
}

class ErrorEvent extends LabelingEvent {
  final String message;
  final String? file;

  const ErrorEvent({required this.message, this.file});
}

class DoneEvent extends LabelingEvent {
  final int successful;
  final int failed;
  final int lowConfidence;

  const DoneEvent({
    required this.successful,
    required this.failed,
    required this.lowConfidence,
  });
}
