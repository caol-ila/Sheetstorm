import 'dart:io';
import 'package:csv/csv.dart';
import 'package:sheetstorm_pdf_labeler/src/models/labeling_state.dart';

class CsvExporter {
  static Future<void> exportResults({
    required List<LabelingResult> results,
    required String outputPath,
  }) async {
    final rows = <List<String>>[
      ['Original Path', 'Recognized Title', 'Confidence', 'Status', 'Target Path', 'Error'],
      ...results.map((result) => [
            result.originalPath,
            result.recognizedTitle ?? '',
            result.confidence?.toStringAsFixed(2) ?? '',
            _statusToString(result.status),
            result.targetPath ?? '',
            result.error ?? '',
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final file = File(outputPath);
    await file.writeAsString(csv);
  }

  static String _statusToString(ResultStatus status) {
    switch (status) {
      case ResultStatus.recognized:
        return 'Recognized';
      case ResultStatus.lowConfidence:
        return 'Low Confidence';
      case ResultStatus.error:
        return 'Error';
    }
  }
}
