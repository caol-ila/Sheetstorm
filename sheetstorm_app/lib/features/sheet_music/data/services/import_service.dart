import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';
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
    required List<PickedFileData> files,
    required ImportTarget ziel,
    String? bandId,
    void Function(double progress)? onProgress,
  }) async {
    final formData = FormData();

    for (final file in files) {
      formData.files.add(MapEntry(
        'files[]',
        MultipartFile.fromBytes(file.bytes, filename: file.name),
      ));
    }

    formData.fields.add(MapEntry('ziel', ziel.name));
    if (bandId != null) {
      formData.fields.add(MapEntry('band_id', bandId));
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/sheet-music/upload',
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
      '/sheet-music/upload/$uploadId',
    );
    return _parseUploadStatus(response.data!);
  }

  /// Saves the labeling (page → song grouping).
  Future<LabelingResponse> submitLabeling({
    required String uploadId,
    required List<TempPiece> pieces,
  }) async {
    final body = {
      'pieces': pieces
          .map((s) => {
                'temp_id': s.tempId,
                'page_ids': s.pageIds,
                'reihenfolge':
                    List.generate(s.pageIds.length, (i) => i + 1),
                'voice_id': s.voiceId,
              })
          .toList(),
    };

    final response = await _dio.post<Map<String, dynamic>>(
      '/sheet-music/$uploadId/labeling',
      data: body,
    );

    final data = response.data!;
    final items = (data['pieces'] as List<dynamic>)
        .map((item) => LabelingResultItem(
              tempId: item['temp_id'] as String,
              sheetMusicId: item['sheet_music_id'] as String,
              status: item['status'] as String,
            ))
        .toList();

    return LabelingResponse(pieces: items);
  }

  /// Polls AI metadata recognition status for a single Notenblatt.
  Future<MetadataStatusResponse> getMetadataStatus(
    String sheetMusicId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sheet-music/$sheetMusicId/metadata/status',
    );
    return _parseMetadataStatus(response.data!);
  }

  /// Persists user-confirmed metadata for a single Notenblatt.
  Future<void> saveMetadata({
    required String sheetMusicId,
    required TempPiece piece,
  }) async {
    await _dio.put<dynamic>(
      '/sheet-music/$sheetMusicId/metadata',
      data: {
        'title': piece.title,
        'composer': piece.composer,
        'arranger': piece.arranger,
        'musical_key': piece.musicalKey,
        'time_signature': piece.timeSignature,
        'genre': piece.genre,
        'fields_confirmed': piece.fieldsConfirmed.toList(),
      },
    );
  }

  // ─── Parsers ──────────────────────────────────────────────────────────────

  UploadStatusResponse _parseUploadStatus(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'processing';
    final status = switch (statusStr) {
      'ready_for_labeling' => UploadBatchStatus.readyForLabeling,
      'completed' => UploadBatchStatus.completed,
      'failed' => UploadBatchStatus.failed,
      _ => UploadBatchStatus.processing,
    };

    final dateienList = (data['files'] as List<dynamic>? ?? [])
        .map((d) => FileInfo(
              fileId: d['file_id'] as String,
              fileName: d['file_name'] as String? ?? '',
              status: d['status'] as String? ?? 'unknown',
              pageCount: d['page_count'] as int? ?? 0,
              pagesExtracted: d['pages_extracted'] as int? ?? 0,
            ))
        .toList();

    final seitenList = (data['pages'] as List<dynamic>? ?? [])
        .map((s) => PageInfo(
              pageId: s['page_id'] as String,
              fileId: s['file_id'] as String,
              pageNumber: s['page_number'] as int? ?? 1,
              thumbnailUrl: s['thumbnail_url'] as String?,
              aiStatus: switch (s['ai_status'] as String? ?? 'pending') {
                'processing' => PageAiStatus.processing,
                'done' => PageAiStatus.completed,
                'failed' => PageAiStatus.failed,
                _ => PageAiStatus.pending,
              },
            ))
        .toList();

    return UploadStatusResponse(
      uploadId: data['upload_id'] as String,
      status: status,
      files: dateienList,
      pages: seitenList,
    );
  }

  MetadataStatusResponse _parseMetadataStatus(Map<String, dynamic> data) {
    final statusStr = data['status'] as String? ?? 'queued';
    final status = switch (statusStr) {
      'processing' => MetadataJobStatus.processing,
      'done' => MetadataJobStatus.completed,
      'failed' => MetadataJobStatus.failed,
      _ => MetadataJobStatus.queued,
    };

    MetadataSuggestions? suggestions;
    final v = data['suggestions'] as Map<String, dynamic>?;
    if (v != null && status == MetadataJobStatus.completed) {
      AiSuggestion<String>? parseField(String key) {
        final field = v[key] as Map<String, dynamic>?;
        if (field == null) return null;
        return AiSuggestion<String>(
          value: field['value'] as String?,
          confidence: (field['confidence'] as num?)?.toDouble() ?? 0.0,
        );
      }

      suggestions = MetadataSuggestions(
        title: parseField('title'),
        voice: parseField('stimme'),
        musicalKey: parseField('musical_key'),
        timeSignature: parseField('time_signature'),
        composer: parseField('composer'),
      );
    }

    return MetadataStatusResponse(status: status, suggestions: suggestions);
  }
}
