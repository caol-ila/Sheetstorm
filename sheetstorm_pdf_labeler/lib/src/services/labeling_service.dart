import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sheetstorm_pdf_labeler/src/models/labeling_event.dart';

class LabelingService {
  Process? _process;
  StreamSubscription? _subscription;

  Stream<LabelingEvent> run({
    required String source,
    required String target,
    required String pat,
    double confidence = 0.6,
  }) async* {
    final controller = StreamController<LabelingEvent>();

    try {
      final cliPath = _resolveCliPath();
      
      final args = [
        '--source',
        source,
        '--target',
        target,
        '--confidence',
        confidence.toString(),
      ];

      final environment = <String, String>{
        'SHEETSTORM_PAT': pat,
      };

      _process = await Process.start(
        cliPath,
        args,
        environment: environment,
        runInShell: true,
      );

      _subscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;

          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final event = _parseEvent(json);
            if (event != null) {
              controller.add(event);
            }
          } catch (e) {
            controller.add(ErrorEvent(message: 'Parse error: $e'));
          }
        },
        onError: (error) {
          controller.add(ErrorEvent(message: error.toString()));
        },
        onDone: () {
          controller.close();
        },
      );

      yield* controller.stream;
    } catch (e) {
      yield ErrorEvent(message: e.toString());
      yield const DoneEvent(successful: 0, failed: 1, lowConfidence: 0);
    } finally {
      await _cleanup();
    }
  }

  LabelingEvent? _parseEvent(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'progress':
        return ProgressEvent(
          current: json['current'] as int? ?? 0,
          total: json['total'] as int? ?? 0,
          currentFile: json['currentFile'] as String? ?? '',
        );

      case 'result':
        return ResultEvent(
          originalPath: json['originalPath'] as String? ?? '',
          recognizedTitle: json['recognizedTitle'] as String?,
          confidence: (json['confidence'] as num?)?.toDouble(),
          targetPath: json['targetPath'] as String?,
          error: json['error'] as String?,
        );

      case 'error':
        return ErrorEvent(
          message: json['message'] as String? ?? 'Unknown error',
          file: json['file'] as String?,
        );

      case 'done':
        return DoneEvent(
          successful: json['successful'] as int? ?? 0,
          failed: json['failed'] as int? ?? 0,
          lowConfidence: json['lowConfidence'] as int? ?? 0,
        );

      default:
        return null;
    }
  }

  String _resolveCliPath() {
    const cliPathEnv = String.fromEnvironment('CLI_PATH');
    if (cliPathEnv.isNotEmpty) {
      return cliPathEnv;
    }

    // Debug mode: relative path
    final debugPath = p.normalize(p.join(
      Directory.current.path,
      '..',
      'src',
      'Sheetstorm.PdfLabeling.Cli',
      'bin',
      'Debug',
      'net10.0',
      'Sheetstorm.PdfLabeling.Cli.exe',
    ));

    if (File(debugPath).existsSync()) {
      return debugPath;
    }

    // Release mode: adjacent cli folder
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final releasePath = p.join(
      exeDir,
      'cli',
      'Sheetstorm.PdfLabeling.Cli.exe',
    );

    return releasePath;
  }

  void cancel() {
    _process?.stdin.close();
    _process?.kill();
  }

  Future<void> _cleanup() async {
    await _subscription?.cancel();
    _subscription = null;
    _process = null;
  }
}

