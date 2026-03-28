import 'dart:io';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/noten/data/models/import_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'import_service.g.dart';

@riverpod
ImportService importService(Ref ref) {
  return ImportService(ref.read(apiClientProvider));
}

class ImportService {
  ImportService(this._dio);

  final Dio _dio;

  /// Uploads one or more files as a multipart batch.
  /// Returns the server-assigned upload_id.
  Future<String> uploadFiles({
    required List<File> files,
    required ImportZiel ziel,
    String? kapelleId,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData();

    for (final file in files) {
      final filename = file.path.split(Platform.pathSeparator).last;
      formData.files.add(MapEntry(
        'files[]',
        await MultipartFile.fromFile(file.path, filename: filename),
      ));
    }

    formData.fields.add(MapEntry('ziel', ziel.name));
    if (kapelleId != null) {
      formData.fields.add(MapEntry('kapelle_id', kapelleId));
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/noten/upload',
      data: formData,
      onSendProgress: (sent, total) {
        if (total > 0) onProgress?.call(sent / total);
      },
    );

    return response.data!['upload_id'] as String;
  }

  /// Polls upload / page-extraction status.
  Future<UploadStatusResponse> getUploadStatus(String uploadId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/noten/upload/$uploadId',
    );
    return _parseUploadStatus(response.data!);
  }

  /// Saves the labeling (page → song grouping).
  Future<LabelingResponse> submitLabeling({
    required String uploadId,
    required List<TempStueck> stuecke,
  }) async {
    final body = {
      'stuecke': stuecke
          .map((s) => {
                'temp_id': s.tempId,
                'seiten_ids': s.seitenIds,
                'reihenfolge':
                    List.generate(s.seitenIds.length, (i) => i + 1),
                'stimme_id': s.stimmeId,
              })
          .toList(),
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/noten/$uploadId/labeling',
      data: body,
    );

    final data = response.data!;
    final items = (data['stuecke'] as List<dynamic>)
        .map((item) => LabelingResultItem(
              tempId: item['temp_id'] as String,
              notenblattId: item['notenblatt_id'] as String,
              status: item['status'] as String,
            ))
        .toList();

    return LabelingResponse(stuecke: items);
  }

  /// Polls AI metadata recognition status for a single Notenblatt.
  Future<MetadataStatusResponse> getMetadataStatus(
    String notenblattId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/noten/$notenblattId/metadata/status',
    );
    return _parseMetadataStatus(response.data!);
  }

  /// Persists user-confirmed metadata for a single Notenblatt.
  Future<void> saveMetadata({
    required String notenblattId,
    required TempStueck stueck,
  }) async {
    await _dio.put<dynamic>(
      '/noten/$notenblattId/metadata',
      data: {
        'titel': stueck.titel,
        'komponist': stueck.komponist,
        'arrangeur': stueck.arrangeur,
        'tonart': stueck.tonart,
        'taktart': stueck.taktart,
        'genre': stueck.genre,
        'felder_bestaetigt': stueck.felderBestaetigt.toList(),
      },
    );
  }

  // ─── Parsers ──────────────────────────────────────────────────────────────

  UploadStatusResponse _parseUploadStatus(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'processing';
    final status = switch (statusStr) {
      'ready_for_labeling' => UploadBatchStatus.bereitFuerLabeling,
      'completed' => UploadBatchStatus.abgeschlossen,
      'failed' => UploadBatchStatus.fehlgeschlagen,
      _ => UploadBatchStatus.verarbeitung,
    };

    final dateienList = (data['dateien'] as List<dynamic>? ?? [])
        .map((d) => DateiInfo(
              dateiId: d['datei_id'] as String,
              dateiname: d['dateiname'] as String? ?? '',
              status: d['status'] as String? ?? 'unknown',
              seitenCount: d['seiten_count'] as int? ?? 0,
              seitenExtracted: d['seiten_extracted'] as int? ?? 0,
            ))
        .toList();

    final seitenList = (data['seiten'] as List<dynamic>? ?? [])
        .map((s) => SeiteInfo(
              seiteId: s['seite_id'] as String,
              dateiId: s['datei_id'] as String,
              seiteNr: s['seite_nr'] as int? ?? 1,
              thumbnailUrl: s['thumbnail_url'] as String?,
              aiStatus: switch (s['ai_status'] as String? ?? 'pending') {
                'processing' => SeiteAiStatus.verarbeitung,
                'done' => SeiteAiStatus.fertig,
                'failed' => SeiteAiStatus.fehlgeschlagen,
                _ => SeiteAiStatus.ausstehend,
              },
            ))
        .toList();

    return UploadStatusResponse(
      uploadId: data['upload_id'] as String,
      status: status,
      dateien: dateienList,
      seiten: seitenList,
    );
  }

  MetadataStatusResponse _parseMetadataStatus(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'queued';
    final status = switch (statusStr) {
      'processing' => MetadataJobStatus.verarbeitung,
      'done' => MetadataJobStatus.fertig,
      'failed' => MetadataJobStatus.fehlgeschlagen,
      _ => MetadataJobStatus.warteschlange,
    };

    MetadataVorschlaege? vorschlaege;
    final v = data['vorschlaege'] as Map<String, dynamic>?;
    if (v != null && status == MetadataJobStatus.fertig) {
      AiVorschlag<String>? parseField(String key) {
        final field = v[key] as Map<String, dynamic>?;
        if (field == null) return null;
        return AiVorschlag<String>(
          wert: field['wert'] as String?,
          konfidenz: (field['konfidenz'] as num?)?.toDouble() ?? 0.0,
        );
      }

      vorschlaege = MetadataVorschlaege(
        titel: parseField('titel'),
        stimme: parseField('stimme'),
        tonart: parseField('tonart'),
        taktart: parseField('taktart'),
        komponist: parseField('komponist'),
      );
    }

    return MetadataStatusResponse(status: status, vorschlaege: vorschlaege);
  }
}
