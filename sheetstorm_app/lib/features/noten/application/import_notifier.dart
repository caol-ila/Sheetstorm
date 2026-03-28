import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sheetstorm/features/noten/data/models/import_models.dart';
import 'package:sheetstorm/features/noten/data/services/import_service.dart';

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
    this.kapelleId,
  });

  final List<FileUploadProgress> files;
  final ImportZiel ziel;
  final String? uploadId;
  final String? kapelleId;

  double get gesamtFortschritt {
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
      kapelleId: kapelleId,
    );
  }
}

/// Upload done — server is extracting pages from PDFs.
class ImportExtracting extends ImportState {
  const ImportExtracting({
    required this.uploadId,
    required this.dateien,
    this.seiten = const [],
    required this.ziel,
  });

  final String uploadId;
  final List<DateiInfo> dateien;
  final List<SeiteInfo> seiten;
  final ImportZiel ziel;

  double get fortschritt {
    if (dateien.isEmpty) return 0;
    final total = dateien.fold(0, (sum, d) => sum + d.seitenCount);
    final done = dateien.fold(0, (sum, d) => sum + d.seitenExtracted);
    return total == 0 ? 0.1 : done / total; // min 10% so bar shows progress
  }
}

/// Pages ready — user can now assign pages to songs.
class ImportLabeling extends ImportState {
  const ImportLabeling({
    required this.uploadId,
    required this.seiten,
    required this.stuecke,
    required this.ziel,
  });

  final String uploadId;
  final List<SeiteInfo> seiten;
  final List<TempStueck> stuecke;
  final ImportZiel ziel;

  /// Look up a SeiteInfo by ID.
  SeiteInfo? seiteFuer(String seiteId) {
    try {
      return seiten.firstWhere((s) => s.seiteId == seiteId);
    } catch (_) {
      return null;
    }
  }

  ImportLabeling copyWith({
    List<TempStueck>? stuecke,
  }) {
    return ImportLabeling(
      uploadId: uploadId,
      seiten: seiten,
      stuecke: stuecke ?? this.stuecke,
      ziel: ziel,
    );
  }
}

/// User is editing metadata for individual songs.
class ImportEditingMetadata extends ImportState {
  const ImportEditingMetadata({
    required this.uploadId,
    required this.seiten,
    required this.stuecke,
    required this.currentIndex,
    required this.ziel,
  });

  final String uploadId;
  final List<SeiteInfo> seiten;
  final List<TempStueck> stuecke;
  final int currentIndex;
  final ImportZiel ziel;

  TempStueck get currentStueck => stuecke[currentIndex];
  bool get isFirst => currentIndex == 0;
  bool get isLast => currentIndex == stuecke.length - 1;

  ImportEditingMetadata copyWith({
    List<TempStueck>? stuecke,
    int? currentIndex,
  }) {
    return ImportEditingMetadata(
      uploadId: uploadId,
      seiten: seiten,
      stuecke: stuecke ?? this.stuecke,
      currentIndex: currentIndex ?? this.currentIndex,
      ziel: ziel,
    );
  }
}

/// All metadata done — final review before committing.
class ImportSummary extends ImportState {
  const ImportSummary({
    required this.uploadId,
    required this.seiten,
    required this.stuecke,
    required this.ziel,
  });

  final String uploadId;
  final List<SeiteInfo> seiten;
  final List<TempStueck> stuecke;
  final ImportZiel ziel;
}

/// Sending final data to backend.
class ImportCompleting extends ImportState {
  const ImportCompleting();
}

/// Import successfully completed.
class ImportComplete extends ImportState {
  const ImportComplete({required this.stueckeCount});
  final int stueckeCount;
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
    required ImportZiel ziel,
    String? kapelleId,
  }) async {
    final progress = files
        .map((f) => FileUploadProgress(clientId: _uuid.v4(), file: f))
        .toList();

    state = ImportUploading(files: progress, ziel: ziel, kapelleId: kapelleId);

    final service = ref.read(importServiceProvider);
    try {
      final uploadId = await service.uploadFiles(
        files: files,
        ziel: ziel,
        kapelleId: kapelleId,
        onProgress: (p) {
          final current = state;
          if (current is ImportUploading) {
            final updated = current.files
                .map((f) => f.copyWith(
                      progress: p,
                      status: p >= 1.0
                          ? DateiUploadStatus.hochgeladen
                          : DateiUploadStatus.hochladend,
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
                f.copyWith(progress: 1.0, status: DateiUploadStatus.hochgeladen))
            .toList();
        state = current.copyWith(files: uploaded, uploadId: uploadId);
      }

      _startExtractionPolling(uploadId, ziel);
    } on Exception catch (e) {
      state = ImportError(
        message: 'Upload fehlgeschlagen: $e',
        previousState: state,
      );
    }
  }

  // ── Polling for page extraction ────────────────────────────────────────────

  void _startExtractionPolling(String uploadId, ImportZiel ziel) {
    final current = state;
    if (current is ImportUploading) {
      state = ImportExtracting(
        uploadId: uploadId,
        dateien: [],
        ziel: ziel,
      );
    }

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _pollExtractionStatus(uploadId, ziel);
    });
  }

  Future<void> _pollExtractionStatus(String uploadId, ImportZiel ziel) async {
    final service = ref.read(importServiceProvider);
    try {
      final status = await service.getUploadStatus(uploadId);

      if (status.status == UploadBatchStatus.bereitFuerLabeling ||
          status.status == UploadBatchStatus.abgeschlossen) {
        _pollTimer?.cancel();
        _transitionToLabeling(uploadId, status.seiten, ziel);
      } else if (status.status == UploadBatchStatus.fehlgeschlagen) {
        _pollTimer?.cancel();
        state = const ImportError(
          message: 'Seitenextraktion fehlgeschlagen. Bitte erneut versuchen.',
        );
      } else {
        // Still processing — update progress
        final current = state;
        if (current is ImportExtracting) {
          state = ImportExtracting(
            uploadId: uploadId,
            dateien: status.dateien,
            seiten: status.seiten,
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
    List<SeiteInfo> seiten,
    ImportZiel ziel,
  ) {
    // Default: all pages belong to one song
    final erstesStueck = TempStueck(
      tempId: _uuid.v4(),
      seitenIds: seiten.map((s) => s.seiteId).toList(),
    );

    state = ImportLabeling(
      uploadId: uploadId,
      seiten: seiten,
      stuecke: [erstesStueck],
      ziel: ziel,
    );
  }

  // ── Labeling actions ───────────────────────────────────────────────────────

  /// Split the song group at [seiteId] — that page starts a new song.
  void neueStueckGrenzeBei(String seiteId) {
    final current = state;
    if (current is! ImportLabeling) return;

    final stuecke = List<TempStueck>.from(current.stuecke);

    // Find which song contains this page
    for (int si = 0; si < stuecke.length; si++) {
      final stueck = stuecke[si];
      final pageIndex = stueck.seitenIds.indexOf(seiteId);

      if (pageIndex <= 0) continue; // page not found or already first page

      // Split: keep pages before the marker in current song, move rest to new
      final vorher = stueck.seitenIds.sublist(0, pageIndex);
      final nachher = stueck.seitenIds.sublist(pageIndex);

      stuecke[si] = stueck.copyWith(seitenIds: vorher);
      stuecke.insert(
        si + 1,
        TempStueck(tempId: _uuid.v4(), seitenIds: nachher),
      );
      break;
    }

    state = current.copyWith(stuecke: stuecke);
  }

  /// Merge the song at [stueckId] with the preceding song.
  void stueckMitVorherigemVerbinden(String stueckId) {
    final current = state;
    if (current is! ImportLabeling) return;

    final stuecke = List<TempStueck>.from(current.stuecke);
    final idx = stuecke.indexWhere((s) => s.tempId == stueckId);
    if (idx <= 0) return; // already first or not found

    final merged = stuecke[idx - 1].copyWith(
      seitenIds: [...stuecke[idx - 1].seitenIds, ...stuecke[idx].seitenIds],
    );
    stuecke[idx - 1] = merged;
    stuecke.removeAt(idx);

    state = current.copyWith(stuecke: stuecke);
  }

  /// Reorder pages within a song.
  void seiteVerschieben(String stueckId, int oldIndex, int newIndex) {
    final current = state;
    if (current is! ImportLabeling) return;

    final stuecke = List<TempStueck>.from(current.stuecke);
    final idx = stuecke.indexWhere((s) => s.tempId == stueckId);
    if (idx == -1) return;

    final seiten = List<String>.from(stuecke[idx].seitenIds);
    final item = seiten.removeAt(oldIndex);
    seiten.insert(newIndex, item);

    stuecke[idx] = stuecke[idx].copyWith(seitenIds: seiten);
    state = current.copyWith(stuecke: stuecke);
  }

  /// Proceed from labeling to metadata editing.
  void labelingAbschliessen() {
    final current = state;
    if (current is! ImportLabeling) return;

    state = ImportEditingMetadata(
      uploadId: current.uploadId,
      seiten: current.seiten,
      stuecke: current.stuecke,
      currentIndex: 0,
      ziel: current.ziel,
    );
  }

  // ── Metadata editing actions ───────────────────────────────────────────────

  /// Update metadata fields for the current song.
  void metadatenAktualisieren({
    String? titel,
    String? komponist,
    String? arrangeur,
    String? tonart,
    String? taktart,
    String? genre,
    String? stimmeId,
    String? stimmeName,
    Set<String>? felderBestaetigt,
  }) {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final updated = current.currentStueck.copyWith(
      titel: titel,
      komponist: komponist,
      arrangeur: arrangeur,
      tonart: tonart,
      taktart: taktart,
      genre: genre,
      stimmeId: stimmeId,
      stimmeName: stimmeName,
      felderBestaetigt: felderBestaetigt,
    );

    final stuecke = List<TempStueck>.from(current.stuecke);
    stuecke[current.currentIndex] = updated;

    state = current.copyWith(stuecke: stuecke);
  }

  /// Accept an AI suggestion for a specific field.
  void vorschlagAnnehmen(String feld) {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final stueck = current.currentStueck;
    final v = stueck.vorschlaege;
    if (v == null) return;

    String? wert;
    switch (feld) {
      case 'titel':
        wert = v.titel?.wert;
      case 'komponist':
        wert = v.komponist?.wert;
      case 'tonart':
        wert = v.tonart?.wert;
      case 'taktart':
        wert = v.taktart?.wert;
      case 'stimme':
        wert = v.stimme?.wert;
      default:
        return;
    }

    if (wert == null) return;

    final bestaetigt = Set<String>.from(stueck.felderBestaetigt)..add(feld);

    metadatenAktualisieren(
      titel: feld == 'titel' ? wert : stueck.titel,
      komponist: feld == 'komponist' ? wert : stueck.komponist,
      tonart: feld == 'tonart' ? wert : stueck.tonart,
      taktart: feld == 'taktart' ? wert : stueck.taktart,
      felderBestaetigt: bestaetigt,
    );
  }

  /// Navigate to next song in metadata editor.
  void naechstesStueck() {
    final current = state;
    if (current is! ImportEditingMetadata) return;
    if (current.isLast) {
      zuZusammenfassung();
      return;
    }
    state = current.copyWith(currentIndex: current.currentIndex + 1);
  }

  /// Navigate to previous song in metadata editor.
  void vorherigesStueck() {
    final current = state;
    if (current is! ImportEditingMetadata) return;
    if (current.isFirst) return;
    state = current.copyWith(currentIndex: current.currentIndex - 1);
  }

  /// Jump to summary (skip remaining metadata).
  void zuZusammenfassung() {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    state = ImportSummary(
      uploadId: current.uploadId,
      seiten: current.seiten,
      stuecke: current.stuecke,
      ziel: current.ziel,
    );
  }

  // ── Final submission ───────────────────────────────────────────────────────

  /// Submit labeling and metadata to the server.
  Future<void> importAbschliessen() async {
    final current = state;
    if (current is! ImportSummary) return;

    state = const ImportCompleting();

    final service = ref.read(importServiceProvider);
    try {
      // Step 1: submit labeling (page → song grouping)
      final labelingResult = await service.submitLabeling(
        uploadId: current.uploadId,
        stuecke: current.stuecke,
      );

      // Step 2: map server notenblatt IDs back to our temp stuecke
      final idMap = {
        for (final r in labelingResult.stuecke) r.tempId: r.notenblattId,
      };

      final stueckeMitIds = current.stuecke.map((s) {
        final nbId = idMap[s.tempId];
        return nbId != null ? s.copyWith(notenblattId: nbId) : s;
      }).toList();

      // Step 3: save metadata for each song that has a notenblatt_id
      for (final stueck in stueckeMitIds) {
        final nbId = stueck.notenblattId;
        if (nbId != null) {
          await service.saveMetadata(notenblattId: nbId, stueck: stueck);
        }
      }

      state = ImportComplete(stueckeCount: stueckeMitIds.length);
    } on Exception catch (e) {
      state = ImportError(
        message: 'Import fehlgeschlagen: $e',
        previousState: current,
      );
    }
  }

  /// Go back from error to previous state if available.
  void fehlerZuruecksetzen() {
    final current = state;
    if (current is ImportError) {
      state = current.previousState ?? const ImportIdle();
    }
  }

  /// Reset to idle (cancel import).
  void zuruecksetzen() {
    _pollTimer?.cancel();
    state = const ImportIdle();
  }

  // ── Metadata polling ───────────────────────────────────────────────────────

  /// Poll AI metadata for a specific notenblatt and update its TempStueck.
  Future<void> metadatenAbfragen(String stueckTempId) async {
    final current = state;
    if (current is! ImportEditingMetadata) return;

    final stueckIdx =
        current.stuecke.indexWhere((s) => s.tempId == stueckTempId);
    if (stueckIdx == -1) return;

    final stueck = current.stuecke[stueckIdx];
    final nbId = stueck.notenblattId;
    if (nbId == null) return;

    final service = ref.read(importServiceProvider);
    try {
      final result = await service.getMetadataStatus(nbId);
      if (result.status == MetadataJobStatus.fertig &&
          result.vorschlaege != null) {
        final stuecke = List<TempStueck>.from(current.stuecke);
        stuecke[stueckIdx] = stueck.copyWith(
          vorschlaege: result.vorschlaege,
          metadataJobStatus: MetadataJobStatus.fertig,
        );
        state = current.copyWith(stuecke: stuecke);
      }
    } on Exception {
      // AI metadata failures are non-critical — user can still enter manually
    }
  }
}
