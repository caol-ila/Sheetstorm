import 'dart:io';

import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ImportTarget { band, personal }

enum FileUploadStatus { pending, uploading, uploaded, failed }

enum PageAiStatus { pending, processing, completed, failed }

enum UploadBatchStatus {
  processing,
  readyForLabeling,
  completed,
  failed,
}

enum MetadataJobStatus { queued, processing, completed, failed }

enum ConfidenceLevel { high, medium, low, unknown }

ConfidenceLevel _levelFromConfidence(double confidence) {
  if (confidence >= 0.8) return ConfidenceLevel.high;
  if (confidence >= 0.5) return ConfidenceLevel.medium;
  if (confidence > 0.0) return ConfidenceLevel.low;
  return ConfidenceLevel.unknown;
}

// ─── Upload Progress ──────────────────────────────────────────────────────────

class FileUploadProgress extends Equatable {
  const FileUploadProgress({
    required this.clientId,
    required this.file,
    this.progress = 0.0,
    this.status = FileUploadStatus.pending,
    this.errorMessage,
    this.fileId,
  });

  final String clientId;
  final File file;
  final double progress;
  final FileUploadStatus status;
  final String? errorMessage;
  final String? fileId;

  String get displayName => file.path.split(Platform.pathSeparator).last;

  FileUploadProgress copyWith({
    double? progress,
    FileUploadStatus? status,
    String? errorMessage,
    String? fileId,
  }) {
    return FileUploadProgress(
      clientId: clientId,
      file: file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      fileId: fileId ?? this.fileId,
    );
  }

  @override
  List<Object?> get props =>
      [clientId, progress, status, errorMessage, fileId];
}

// ─── Upload Batch ─────────────────────────────────────────────────────────────

class FileInfo extends Equatable {
  const FileInfo({
    required this.fileId,
    required this.fileName,
    required this.status,
    this.pageCount = 0,
    this.pagesExtracted = 0,
  });

  final String fileId;
  final String fileName;
  final String status;
  final int pageCount;
  final int pagesExtracted;

  @override
  List<Object?> get props =>
      [fileId, fileName, status, pageCount, pagesExtracted];
}

class PageInfo extends Equatable {
  const PageInfo({
    required this.pageId,
    required this.fileId,
    required this.pageNumber,
    this.thumbnailUrl,
    this.aiStatus = PageAiStatus.pending,
  });

  final String pageId;
  final String fileId;
  final int pageNumber;
  final String? thumbnailUrl;
  final PageAiStatus aiStatus;

  @override
  List<Object?> get props =>
      [pageId, fileId, pageNumber, thumbnailUrl, aiStatus];
}

class UploadStatusResponse extends Equatable {
  const UploadStatusResponse({
    required this.uploadId,
    required this.status,
    required this.files,
    this.pages = const [],
  });

  final String uploadId;
  final UploadBatchStatus status;
  final List<FileInfo> files;
  final List<PageInfo> pages;

  double get extractionProgress {
    if (files.isEmpty) return 0;
    final total = files.fold(0, (sum, d) => sum + d.pageCount);
    final done = files.fold(0, (sum, d) => sum + d.pagesExtracted);
    return total == 0 ? 0 : done / total;
  }

  @override
  List<Object?> get props => [uploadId, status, files, pages];
}

// ─── AI Metadata ──────────────────────────────────────────────────────────────

class AiSuggestion<T> extends Equatable {
  const AiSuggestion({this.value, required this.confidence});

  final T? value;
  final double confidence;

  ConfidenceLevel get level => _levelFromConfidence(confidence);

  @override
  List<Object?> get props => [value, confidence];
}

class MetadataSuggestions extends Equatable {
  const MetadataSuggestions({
    this.title,
    this.voice,
    this.musicalKey,
    this.timeSignature,
    this.composer,
  });

  final AiSuggestion<String>? title;
  final AiSuggestion<String>? voice;
  final AiSuggestion<String>? musicalKey;
  final AiSuggestion<String>? timeSignature;
  final AiSuggestion<String>? composer;

  @override
  List<Object?> get props => [title, voice, musicalKey, timeSignature, composer];
}

// ─── Temporary Song (during labeling) ────────────────────────────────────────

class TempPiece extends Equatable {
  const TempPiece({
    required this.tempId,
    required this.pageIds,
    this.title,
    this.composer,
    this.arranger,
    this.musicalKey,
    this.timeSignature,
    this.genre,
    this.voiceId,
    this.voiceName,
    this.suggestions,
    this.fieldsConfirmed = const {},
    this.sheetMusicId,
    this.metadataJobStatus,
  });

  final String tempId;
  final List<String> pageIds;
  final String? title;
  final String? composer;
  final String? arranger;
  final String? musicalKey;
  final String? timeSignature;
  final String? genre;
  final String? voiceId;
  final String? voiceName;
  final MetadataSuggestions? suggestions;
  final Set<String> fieldsConfirmed;
  final String? sheetMusicId;
  final MetadataJobStatus? metadataJobStatus;

  String get displayTitle =>
      title?.isNotEmpty == true ? title! : 'Unbenanntes Stück';

  TempPiece copyWith({
    List<String>? pageIds,
    String? title,
    String? composer,
    String? arranger,
    String? musicalKey,
    String? timeSignature,
    String? genre,
    String? voiceId,
    String? voiceName,
    MetadataSuggestions? suggestions,
    Set<String>? fieldsConfirmed,
    String? sheetMusicId,
    MetadataJobStatus? metadataJobStatus,
  }) {
    return TempPiece(
      tempId: tempId,
      pageIds: pageIds ?? this.pageIds,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      arranger: arranger ?? this.arranger,
      musicalKey: musicalKey ?? this.musicalKey,
      timeSignature: timeSignature ?? this.timeSignature,
      genre: genre ?? this.genre,
      voiceId: voiceId ?? this.voiceId,
      voiceName: voiceName ?? this.voiceName,
      suggestions: suggestions ?? this.suggestions,
      fieldsConfirmed: fieldsConfirmed ?? this.fieldsConfirmed,
      sheetMusicId: sheetMusicId ?? this.sheetMusicId,
      metadataJobStatus: metadataJobStatus ?? this.metadataJobStatus,
    );
  }

  @override
  List<Object?> get props => [
        tempId,
        pageIds,
        title,
        composer,
        arranger,
        musicalKey,
        timeSignature,
        genre,
        voiceId,
        voiceName,
        suggestions,
        fieldsConfirmed,
        sheetMusicId,
        metadataJobStatus,
      ];
}

// ─── API Response helpers ─────────────────────────────────────────────────────

class LabelingResultItem {
  LabelingResultItem({
    required this.tempId,
    required this.sheetMusicId,
    required this.status,
  });

  final String tempId;
  final String sheetMusicId;
  final String status;
}

class LabelingResponse {
  LabelingResponse({required this.pieces});
  final List<LabelingResultItem> pieces;
}

class MetadataStatusResponse {
  MetadataStatusResponse({required this.status, this.suggestions});
  final MetadataJobStatus status;
  final MetadataSuggestions? suggestions;
}
