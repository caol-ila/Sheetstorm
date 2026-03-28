import 'dart:io';

import 'package:equatable/equatable.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ImportZiel { kapelle, persoenlich }

enum DateiUploadStatus { ausstehend, hochladend, hochgeladen, fehlgeschlagen }

enum SeiteAiStatus { ausstehend, verarbeitung, fertig, fehlgeschlagen }

enum UploadBatchStatus {
  verarbeitung,
  bereitFuerLabeling,
  abgeschlossen,
  fehlgeschlagen,
}

enum MetadataJobStatus { warteschlange, verarbeitung, fertig, fehlgeschlagen }

enum KonfidenzStufe { hoch, mittel, niedrig, unbekannt }

KonfidenzStufe _stufeVonKonfidenz(double konfidenz) {
  if (konfidenz >= 0.8) return KonfidenzStufe.hoch;
  if (konfidenz >= 0.5) return KonfidenzStufe.mittel;
  if (konfidenz > 0.0) return KonfidenzStufe.niedrig;
  return KonfidenzStufe.unbekannt;
}

// ─── Upload Progress ──────────────────────────────────────────────────────────

class FileUploadProgress extends Equatable {
  const FileUploadProgress({
    required this.clientId,
    required this.file,
    this.progress = 0.0,
    this.status = DateiUploadStatus.ausstehend,
    this.errorMessage,
    this.dateiId,
  });

  final String clientId;
  final File file;
  final double progress;
  final DateiUploadStatus status;
  final String? errorMessage;
  final String? dateiId;

  String get displayName => file.path.split(Platform.pathSeparator).last;

  FileUploadProgress copyWith({
    double? progress,
    DateiUploadStatus? status,
    String? errorMessage,
    String? dateiId,
  }) {
    return FileUploadProgress(
      clientId: clientId,
      file: file,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      dateiId: dateiId ?? this.dateiId,
    );
  }

  @override
  List<Object?> get props =>
      [clientId, progress, status, errorMessage, dateiId];
}

// ─── Upload Batch ─────────────────────────────────────────────────────────────

class DateiInfo extends Equatable {
  const DateiInfo({
    required this.dateiId,
    required this.dateiname,
    required this.status,
    this.seitenCount = 0,
    this.seitenExtracted = 0,
  });

  final String dateiId;
  final String dateiname;
  final String status;
  final int seitenCount;
  final int seitenExtracted;

  @override
  List<Object?> get props =>
      [dateiId, dateiname, status, seitenCount, seitenExtracted];
}

class SeiteInfo extends Equatable {
  const SeiteInfo({
    required this.seiteId,
    required this.dateiId,
    required this.seiteNr,
    this.thumbnailUrl,
    this.aiStatus = SeiteAiStatus.ausstehend,
  });

  final String seiteId;
  final String dateiId;
  final int seiteNr;
  final String? thumbnailUrl;
  final SeiteAiStatus aiStatus;

  @override
  List<Object?> get props =>
      [seiteId, dateiId, seiteNr, thumbnailUrl, aiStatus];
}

class UploadStatusResponse extends Equatable {
  const UploadStatusResponse({
    required this.uploadId,
    required this.status,
    required this.dateien,
    this.seiten = const [],
  });

  final String uploadId;
  final UploadBatchStatus status;
  final List<DateiInfo> dateien;
  final List<SeiteInfo> seiten;

  double get extraktionsFortschritt {
    if (dateien.isEmpty) return 0;
    final total = dateien.fold(0, (sum, d) => sum + d.seitenCount);
    final done = dateien.fold(0, (sum, d) => sum + d.seitenExtracted);
    return total == 0 ? 0 : done / total;
  }

  @override
  List<Object?> get props => [uploadId, status, dateien, seiten];
}

// ─── AI Metadata ──────────────────────────────────────────────────────────────

class AiVorschlag<T> extends Equatable {
  const AiVorschlag({this.wert, required this.konfidenz});

  final T? wert;
  final double konfidenz;

  KonfidenzStufe get stufe => _stufeVonKonfidenz(konfidenz);

  @override
  List<Object?> get props => [wert, konfidenz];
}

class MetadataVorschlaege extends Equatable {
  const MetadataVorschlaege({
    this.titel,
    this.stimme,
    this.tonart,
    this.taktart,
    this.komponist,
  });

  final AiVorschlag<String>? titel;
  final AiVorschlag<String>? stimme;
  final AiVorschlag<String>? tonart;
  final AiVorschlag<String>? taktart;
  final AiVorschlag<String>? komponist;

  @override
  List<Object?> get props => [titel, stimme, tonart, taktart, komponist];
}

// ─── Temporary Song (during labeling) ────────────────────────────────────────

class TempStueck extends Equatable {
  const TempStueck({
    required this.tempId,
    required this.seitenIds,
    this.titel,
    this.komponist,
    this.arrangeur,
    this.tonart,
    this.taktart,
    this.genre,
    this.stimmeId,
    this.stimmeName,
    this.vorschlaege,
    this.felderBestaetigt = const {},
    this.notenblattId,
    this.metadataJobStatus,
  });

  final String tempId;
  final List<String> seitenIds;
  final String? titel;
  final String? komponist;
  final String? arrangeur;
  final String? tonart;
  final String? taktart;
  final String? genre;
  final String? stimmeId;
  final String? stimmeName;
  final MetadataVorschlaege? vorschlaege;
  final Set<String> felderBestaetigt;
  final String? notenblattId;
  final MetadataJobStatus? metadataJobStatus;

  String get displayTitel =>
      titel?.isNotEmpty == true ? titel! : 'Unbenanntes Stück';

  TempStueck copyWith({
    List<String>? seitenIds,
    String? titel,
    String? komponist,
    String? arrangeur,
    String? tonart,
    String? taktart,
    String? genre,
    String? stimmeId,
    String? stimmeName,
    MetadataVorschlaege? vorschlaege,
    Set<String>? felderBestaetigt,
    String? notenblattId,
    MetadataJobStatus? metadataJobStatus,
  }) {
    return TempStueck(
      tempId: tempId,
      seitenIds: seitenIds ?? this.seitenIds,
      titel: titel ?? this.titel,
      komponist: komponist ?? this.komponist,
      arrangeur: arrangeur ?? this.arrangeur,
      tonart: tonart ?? this.tonart,
      taktart: taktart ?? this.taktart,
      genre: genre ?? this.genre,
      stimmeId: stimmeId ?? this.stimmeId,
      stimmeName: stimmeName ?? this.stimmeName,
      vorschlaege: vorschlaege ?? this.vorschlaege,
      felderBestaetigt: felderBestaetigt ?? this.felderBestaetigt,
      notenblattId: notenblattId ?? this.notenblattId,
      metadataJobStatus: metadataJobStatus ?? this.metadataJobStatus,
    );
  }

  @override
  List<Object?> get props => [
        tempId,
        seitenIds,
        titel,
        komponist,
        arrangeur,
        tonart,
        taktart,
        genre,
        stimmeId,
        stimmeName,
        vorschlaege,
        felderBestaetigt,
        notenblattId,
        metadataJobStatus,
      ];
}

// ─── API Response helpers ─────────────────────────────────────────────────────

class LabelingResultItem {
  LabelingResultItem({
    required this.tempId,
    required this.notenblattId,
    required this.status,
  });

  final String tempId;
  final String notenblattId;
  final String status;
}

class LabelingResponse {
  LabelingResponse({required this.stuecke});
  final List<LabelingResultItem> stuecke;
}

class MetadataStatusResponse {
  MetadataStatusResponse({required this.status, this.vorschlaege});
  final MetadataJobStatus status;
  final MetadataVorschlaege? vorschlaege;
}
