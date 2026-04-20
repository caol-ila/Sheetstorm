enum LabelingPhase {
  idle,
  running,
  completed,
  error,
  cancelled,
}

class LabelingState {
  final LabelingPhase phase;
  final String? sourcePath;
  final String? targetPath;
  final int currentProgress;
  final int totalItems;
  final String? currentFile;
  final List<LabelingResult> results;
  final String? errorMessage;

  const LabelingState({
    this.phase = LabelingPhase.idle,
    this.sourcePath,
    this.targetPath,
    this.currentProgress = 0,
    this.totalItems = 0,
    this.currentFile,
    this.results = const [],
    this.errorMessage,
  });

  LabelingState copyWith({
    LabelingPhase? phase,
    String? sourcePath,
    String? targetPath,
    int? currentProgress,
    int? totalItems,
    String? currentFile,
    List<LabelingResult>? results,
    String? errorMessage,
  }) {
    return LabelingState(
      phase: phase ?? this.phase,
      sourcePath: sourcePath ?? this.sourcePath,
      targetPath: targetPath ?? this.targetPath,
      currentProgress: currentProgress ?? this.currentProgress,
      totalItems: totalItems ?? this.totalItems,
      currentFile: currentFile ?? this.currentFile,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LabelingResult {
  final String originalPath;
  final String? recognizedTitle;
  final double? confidence;
  final String? targetPath;
  final String? error;
  final ResultStatus status;

  const LabelingResult({
    required this.originalPath,
    this.recognizedTitle,
    this.confidence,
    this.targetPath,
    this.error,
    required this.status,
  });

  static ResultStatus getStatus(double? confidence, String? error) {
    if (error != null) return ResultStatus.error;
    if (confidence == null) return ResultStatus.error;
    if (confidence >= 0.6) return ResultStatus.recognized;
    return ResultStatus.lowConfidence;
  }
}

enum ResultStatus {
  recognized,
  lowConfidence,
  error,
}
