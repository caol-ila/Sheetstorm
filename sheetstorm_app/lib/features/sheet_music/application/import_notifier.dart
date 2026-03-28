import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';
import 'package:sheetstorm/features/sheet_music/data/services/import_service.dart';

part 'import_notifier.g.dart';

// ─── Import State ─────────────────────────────────────────────────────────────

sealed class ImportState {
  const ImportState();
}

/// Nothing happening — import flow not started.
class ImportIdle extends ImportState {
  const ImportIdle();
}

/// User has picked files and upload is in progress.
class ImportUploading extends ImportState {
  const ImportUploading({
    required this.files,
    required this.ziel,
    this.uploadId,
    this.bandId,
  });

  final List<FileUploadProgress> files;
  final ImportTarget ziel;
  final String? uploadId;
  final String? bandId;

  double get overallProgress {
    if (files.isEmpty) return 0;
    return files.fold(0.0, (sum, f) => sum + f.progress) / files.length;
  }

  ImportUploading copyWith({
    List<FileUploadProgress>? files,
    String? uploadId,
  }) {
    return ImportUploading(
      files: files ?? this.files,
      ziel: ziel,
      uploadId: uploadId ?? this.uploadId,
      bandId: bandId,
    );
  }
}

/// Upload done — server is extracting pages from PDFs.
class ImportExtracting extends ImportState {
  const ImportExtracting({
    required this.uploadId,
    required this.files,
    this.pages = const [],
    required this.ziel,
  });

  final String uploadId;
  final List<FileInfo> files;
  final List<PageInfo> pages;
  final ImportTarget ziel;

  double get progress {
    if (files.isEmpty) return 0;
    final total = files.fold(0, (sum, d) => sum + d.pageCount);
    final done = files.fold(0, (sum, d) => sum + d.pagesExtracted);
    return total == 0 ? 0.1 : done / total; // min 10% so bar shows progress
  }
}

/// Pages ready — user can now assign pages to songs.
class ImportLabeling extends ImportState {
  const ImportLabeling({
    required this.uploadId,
    required this.pages,
    required this.pieces,
    required this.ziel,
  });

  final String uploadId;
  final List<PageInfo> pages;
  final List<TempPiece> pieces;
  final ImportTarget ziel;

  /// Look up a PageInfo by ID.
  PageInfo? pageFor(String pageId) {
    try {
      return pages.firstWhere((s) => s.pageId == pageId);
    } catch (_) {
      return null;
    }
  }

  ImportLabeling copyWith({
    List<TempPiece>? pieces,
  }) {
    return ImportLabeling(
      uploadId: uploadId,
      pages: pages,
      pieces: pieces ?? this.pieces,
      ziel: ziel,
    );
  }
}

/// User is editing metadata for individual songs.
class ImportEditingMetadata extends ImportState {
  const ImportEditingMetadata({
    required this.uploadId,
    required this.pages,
    required this.pieces,
    required this.currentIndex,
    required this.ziel,
  });

  final String uploadId;
  final List<PageInfo> pages;
  final List<TempPiece> pieces;
  final int currentIndex;
  final ImportTarget ziel;

  TempPiece get currentPiece => pieces[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == pieces.length - 1;

  ImportEditingMetadata copyWith({
    List<TempPiece>? pieces,
    int? currentIndex,
  }) {
    return ImportEditingMetadata(
      uploadId: uploadId,
      pages: pages,
      pieces: pieces ?? this.pieces,
      currentIndex: currentIndex ?? this.currentIndex,
      ziel: ziel,
    );
  }
}

/// All metadata done — final review before committing.
class ImportSummary extends ImportState {
  const ImportSummary({
    required this.uploadId,
    required this.pages,
    required this.pieces,
    required this.ziel,
  });

  final String uploadId;
  final List<PageInfo> pages;
  final List<TempPiece> pieces;
  final ImportTarget ziel;
}

/// Sending final data to backend.
class ImportCompleting extends ImportState {
  const ImportCompleting();
}

/// Import successfully completed.
class ImportComplete extends ImportState {
  const ImportComplete({required this.piecesCount});
  final int piecesCount;
}

/// An error occurred.
class ImportError extends ImportState {
  const ImportError({required this.message, this.previousState});
  final String message;
  final ImportState? previousState;
}

// ─── Import Notifier ──────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ImportNotifier extends _$ImportNotifier {
  static const _uuid = Uuid();
  Timer? _pollTimer;

  @override
  ImportState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return const ImportIdle();
  }

  // ── Upload flow ────────────────────────────────────────────────────────────

  /// Begin uploading the given files.
  Future<void> upload({
    required List<File> files,
    required ImportTarget ziel,
    String? bandId,
  }) async {
    final progress = files
        .map((f) => FileUploadProgress(clientId: _uuid.v4(), file: f))
        .toList();

    state = ImportUploading(files: progress, ziel: ziel, bandId: bandId);

    final service = ref.read(importServiceProvider);
    try {
      final uploadId = await service.uploadFiles(
        files: files,
        ziel: ziel,
        bandId: bandId,
        onProgress: (p) {
          final current = state;
          if (current is ImportUploading) {
            final updated = current.files
                .map((f) => f.copyWith(
                      progress: p,
                      status: p >= 1.0
                          ? FileUploadStatus.uploaded
                          : FileUploadStatus.uploading,
                    ))
                .toList();
            // uploadId not yet available during progress; update files only
            state = current.copyWith(files: updated);
          }
        },
      );

      // Upload request accepted — mark all as uploaded, start polling
      final current = state;
      if (current is ImportUploading) {
        final uploaded = current.files
            .map((f) =>
                f.copyWith(progress: 1.0, status: FileUploadStatus.uploaded))
            .toList();
        state = current.copyWith(files: uploaded, uploadId: uploadId);
      }

      _startExtractionPolling(uploadId, ziel);
    } on Exception catch (e) {
      state = ImportError(
        message: 'Upload failed: $e',
        previousState: state,
      );
    }
  }

  // ── Polling for page extraction ────────────────────────────────────────────

  void _startExtractionPolling(String uploadId, ImportTarget ziel) {
    final current = state;
    if (current is ImportUploading) {
      state = ImportExtracting(
        uploadId: uploadId,
        files: [],
        ziel: ziel,
      );
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _pollExtractionStatus(uploadId, ziel);
    });
  }

  Future<void> _pollExtractionStatus(String uploadId, ImportTarget ziel) async {
    final service = ref.read(importServiceProvider);
    try {
      final status = await service.getUploadStatus(uploadId);

      if (status.status == UploadBatchStatus.readyForLabeling ||
          status.status == UploadBatchStatus.completed) {
        _pollTimer?.cancel();
        _transitionToLabeling(uploadId, status.pages, ziel);
      } else if (status.status == UploadBatchStatus.failed) {
        _pollTimer?.cancel();
        state = const ImportError(
          message: 'Page extraction failed. Please try again.',
        );
      } else {
        // Still processing — update progress
        final current = state;
        if (current is ImportExtracting) {
          state = ImportExtracting(
            uploadId: uploadId,
            files: status.files,
            pages: status.pages,
            ziel: ziel,
          );
        }
      }
    } on Exception {
      // Ignore transient network errors during polling
    }
  }

  void _transitionToLabeling(
    String uploadId,
    List<PageInfo> pages,
    ImportTarget ziel,
  ) {
    // Default: all pages belong to one song
    final firstPiece = TempPiece(
      tempId: _uuid.v4(),
      pageIds: pages.map((s) => s.pageId).toList(),
    );

    state = ImportLabeling(
      uploadId: uploadId,
      pages: pages,
      pieces: [firstPiece],
      ziel: ziel,
    );
  }

  // ── Labeling actions ───────────────────────────────────────────────────────

  /// Split the song group at [pageId] — that page starts a new song.
  void newPieceBoundaryAt(String pageId) {
    final current = state;
    if (current is! ImportLabeling) return;

    final pieces = List<TempPiece>.from(current.pieces);

    // Find which song contains this page
    for (int si = 0; si < pieces.length; si++) {
      final piece = pieces[si];
      final pageIndex = piece.pageIds.indexOf(pageId);

      if (pageIndex <= 0) continue; // page not found or already first page

      // Split: keep pages before the marker in current song, move rest to new
      final before = piece.pageIds.sublist(0, pageIndex);
      final after = piece.pageIds.sublist(pageIndex);

      pieces[si] = piece.copyWith(pageIds: before);
      pieces.insert(
        si + 1,
        TempPiece(tempId: _uuid.v4(), pageIds: after),
      );
      break;
    }

    state = current.copyWith(pieces: pieces);
  }

  /// Merge the song at [pieceId] with the preceding song.
  void mergePieceWithPrevious(String pieceId) {
    final current = state;
    if (current is! ImportLabeling) return;

    final pieces = List<TempPiece>.from(current.pieces);
    final idx = pieces.indexWhere((s) => s.tempId == pieceId);
    if (idx <= 0) return; // already first or not found

    final merged = pieces[idx - 1].copyWith(
      pageIds: [...pieces[idx - 1].pageIds, ...pieces[idx].pageIds],
    );
    pieces[idx - 1] = merged;
    pieces.removeAt(idx);

    state = current.copyWith(pieces: pieces);
  }

  /// Reorder pages within a song.
  void movePage(String pieceId, int oldIndex, int newIndex) {
    final current = state;
    if (current is! ImportLabeling) return;

    final pieces = List<TempPiece>.from(current.pieces);
    final idx = pieces.indexWhere((s) => s.tempId == pieceId);
    if (idx == -1) return;

    final pages = List<String>.from(pieces[idx].pageIds);
    final item = pages.removeAt(oldIndex);
    pages.insert(newIndex, item);

    pieces[idx] = pieces[idx].copyWith(pageIds: pages);
    state = current.copyWith(pieces: pieces);
  }

  /// Proceed from labeling to metadata editing.
  void completeLabeling() {
    final current = state;
    if (current is! ImportLabeling) return;

    state = ImportEditingMetadata(
      uploadId: current.uploadId,
      pages: current.pages,
      pieces: current.pieces,
      currentIndex: 0,
      ziel: current.ziel,
    );
  }

  // ── Metadata editing actions ───────────────────────────────────────────────

  /// Update metadata fields for the current song.
  void updateMetadata({
    String? title,
    String? composer,
    String? arranger,
    String? musicalKey,
    String? timeSignature,
    String? genre,
    String? voiceId,
    String? voiceName,
    Set<String>? fieldsConfirmed,
  }) {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final updated = current.currentPiece.copyWith(
      title: title,
      composer: composer,
      arranger: arranger,
      musicalKey: musicalKey,
      timeSignature: timeSignature,
      genre: genre,
      voiceId: voiceId,
      voiceName: voiceName,
      fieldsConfirmed: fieldsConfirmed,
    );

    final pieces = List<TempPiece>.from(current.pieces);
    pieces[current.currentIndex] = updated;

    state = current.copyWith(pieces: pieces);
  }

  /// Accept an AI suggestion for a specific field.
  void acceptSuggestion(String feld) {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final piece = current.currentPiece;
    final v = piece.suggestions;
    if (v == null) return;

    String? value;
    switch (feld) {
      case 'title':
        value = v.title?.value;
      case 'composer':
        value = v.composer?.value;
      case 'musical_key':
        value = v.musicalKey?.value;
      case 'time_signature':
        value = v.timeSignature?.value;
      case 'stimme':
        value = v.voice?.value;
      default:
        return;
    }

    if (value == null) return;

    final confirmed = Set<String>.from(piece.fieldsConfirmed)..add(feld);

    updateMetadata(
      title: feld == 'title' ? value : piece.title,
      composer: feld == 'composer' ? value : piece.composer,
      musicalKey: feld == 'musical_key' ? value : piece.musicalKey,
      timeSignature: feld == 'time_signature' ? value : piece.timeSignature,
      fieldsConfirmed: confirmed,
    );
  }

  /// Navigate to next song in metadata editor.
  void nextPiece() {
    final current = state;
    if (current is! ImportEditingMetadata) return;
    if (current.isLast) {
      goToSummary();
      return;
    }
    state = current.copyWith(currentIndex: current.currentIndex + 1);
  }

  /// Navigate to previous song in metadata editor.
  void previousPiece() {
    final current = state;
    if (current is! ImportEditingMetadata) return;
    if (current.isFirst) return;
    state = current.copyWith(currentIndex: current.currentIndex - 1);
  }

  /// Jump to summary (skip remaining metadata).
  void goToSummary() {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    state = ImportSummary(
      uploadId: current.uploadId,
      pages: current.pages,
      pieces: current.pieces,
      ziel: current.ziel,
    );
  }

  // ── Final submission ───────────────────────────────────────────────────────

  /// Submit labeling and metadata to the server.
  Future<void> completeImport() async {
    final current = state;
    if (current is! ImportSummary) return;

    state = const ImportCompleting();

    final service = ref.read(importServiceProvider);
    try {
      // Step 1: submit labeling (page → song grouping)
      final labelingResult = await service.submitLabeling(
        uploadId: current.uploadId,
        pieces: current.pieces,
      );

      // Step 2: map server notenblatt IDs back to our temp pieces
      final idMap = {
        for (final r in labelingResult.pieces) r.tempId: r.sheetMusicId,
      };

      final stueckeMitIds = current.pieces.map((s) {
        final nbId = idMap[s.tempId];
        return nbId != null ? s.copyWith(sheetMusicId: nbId) : s;
      }).toList();

      // Step 3: save metadata for each song that has a notenblatt_id
      for (final piece in stueckeMitIds) {
        final nbId = piece.sheetMusicId;
        if (nbId != null) {
          await service.saveMetadata(sheetMusicId: nbId, piece: piece);
        }
      }

      state = ImportComplete(piecesCount: stueckeMitIds.length);
    } on Exception catch (e) {
      state = ImportError(
        message: 'Import failed: $e',
        previousState: current,
      );
    }
  }

  /// Go back from error to previous state if available.
  void resetError() {
    final current = state;
    if (current is ImportError) {
      state = current.previousState ?? const ImportIdle();
    }
  }

  /// Reset to idle (cancel import).
  void reset() {
    _pollTimer?.cancel();
    state = const ImportIdle();
  }

  // ── Metadata polling ───────────────────────────────────────────────────────

  /// Poll AI metadata for a specific notenblatt and update its TempPiece.
  Future<void> fetchMetadata(String pieceTempId) async {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final pieceIdx =
        current.pieces.indexWhere((s) => s.tempId == pieceTempId);
    if (pieceIdx == -1) return;

    final piece = current.pieces[pieceIdx];
    final nbId = piece.sheetMusicId;
    if (nbId == null) return;

    final service = ref.read(importServiceProvider);
    try {
      final result = await service.getMetadataStatus(nbId);
      if (result.status == MetadataJobStatus.completed &&
          result.suggestions != null) {
        final pieces = List<TempPiece>.from(current.pieces);
        pieces[pieceIdx] = piece.copyWith(
          suggestions: result.suggestions,
          metadataJobStatus: MetadataJobStatus.completed,
        );
        state = current.copyWith(pieces: pieces);
      }
    } on Exception {
      // AI metadata failures are non-critical — user can still enter manually
    }
  }
}
