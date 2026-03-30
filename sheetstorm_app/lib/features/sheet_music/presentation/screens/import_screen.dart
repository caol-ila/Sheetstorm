import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/sheet_music/application/import_notifier.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportTarget _ziel = ImportTarget.personal;
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    // Navigate when labeling is ready
    ref.listen<ImportState>(importProvider, (prev, next) {
      if (next is ImportLabeling) {
        context.push(AppRoutes.importLabeling(next.uploadId));
      } else if (next is ImportError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Zurück',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => ref.read(importProvider.notifier).resetError(),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noten importieren'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(importProvider.notifier).reset();
            context.pop();
          },
        ),
      ),
      body: switch (importState) {
        ImportUploading() => _UploadingView(state: importState),
        ImportExtracting() => _ExtractingView(state: importState),
        _ => _SelectionView(
            ziel: _ziel,
            isDragOver: _isDragOver,
            onZielChanged: (z) => setState(() => _ziel = z),
            onFilesSelected: _onFilesSelected,
            onCameraPressed: _onCameraPressed,
            onDragOver: (v) => setState(() => _isDragOver = v),
          ),
      },
    );
  }

  Future<void> _onFilesSelected() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'tiff', 'heic', 'heif'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final files = result.files
        .where((f) => f.bytes != null)
        .map((f) => PickedFileData(name: f.name, bytes: f.bytes!))
        .toList();

    if (!mounted) return;
    await ref.read(importProvider.notifier).upload(
          files: files,
          ziel: _ziel,
        );
  }

  Future<void> _onCameraPressed() async {
    final picker = ImagePicker();
    final images = <PickedFileData>[];

    // Capture multiple pages in a loop
    while (mounted) {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) break;
      final bytes = await image.readAsBytes();
      images.add(PickedFileData(name: image.name, bytes: bytes));

      if (!mounted) break;
      final addMore = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Weitere Seite?'),
          content: Text(
              '${images.length} Seite(n) aufgenommen. Noch eine Seite fotografieren?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Fertig'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Weiter fotografieren'),
            ),
          ],
        ),
      );
      if (addMore != true) break;
    }

    if (images.isEmpty || !mounted) return;
    await ref.read(importProvider.notifier).upload(
          files: images,
          ziel: _ziel,
        );
  }
}

// ─── Selection View ───────────────────────────────────────────────────────────

class _SelectionView extends StatelessWidget {
  const _SelectionView({
    required this.ziel,
    required this.isDragOver,
    required this.onZielChanged,
    required this.onFilesSelected,
    required this.onCameraPressed,
    required this.onDragOver,
  });

  final ImportTarget ziel;
  final bool isDragOver;
  final ValueChanged<ImportTarget> onZielChanged;
  final VoidCallback onFilesSelected;
  final VoidCallback onCameraPressed;
  final ValueChanged<bool> onDragOver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Ziel-Auswahl ─────────────────────────────────────────────────
          _ZielAuswahl(ziel: ziel, onChanged: onZielChanged),

          const SizedBox(height: AppSpacing.lg),

          // ── Upload Zone ───────────────────────────────────────────────────
          DragTarget<Object>(
            onWillAcceptWithDetails: (_) {
              onDragOver(true);
              return true;
            },
            onLeave: (_) => onDragOver(false),
            onAcceptWithDetails: (_) {
              onDragOver(false);
              onFilesSelected();
            },
            builder: (context, candidateData, rejectedData) {
              return AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.standard,
                height: 220,
                decoration: BoxDecoration(
                  color: isDragOver
                      ? AppColors.primary.withOpacity(0.08)
                      : theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                  border: Border.all(
                    color: isDragOver
                        ? AppColors.primary
                        : AppColors.border,
                    width: isDragOver ? 2 : 1.5,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: AppSpacing.roundedLg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDragOver
                          ? Icons.file_download_outlined
                          : Icons.upload_file_outlined,
                      size: 48,
                      color: isDragOver
                          ? AppColors.primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isDragOver
                          ? 'Loslassen zum Hochladen'
                          : 'Noten hochladen',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDragOver ? AppColors.primary : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'PDF, JPG, PNG, HEIC · bis zu 100 MB pro Datei',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Action buttons ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onFilesSelected,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('Datei wählen'),
                ),
              ),
              if (isMobile) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCameraPressed,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ziel-Auswahl ─────────────────────────────────────────────────────────────

class _ZielAuswahl extends StatelessWidget {
  const _ZielAuswahl({required this.ziel, required this.onChanged});

  final ImportTarget ziel;
  final ValueChanged<ImportTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Wohin sollen die Noten?',
            style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<ImportTarget>(
          segments: const [
            ButtonSegment(
              value: ImportTarget.personal,
              label: Text('Persönliche Sammlung'),
              icon: Icon(Icons.person_outline),
            ),
            ButtonSegment(
              value: ImportTarget.band,
              label: Text('Kapelle'),
              icon: Icon(Icons.people_outline),
            ),
          ],
          selected: {ziel},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

// ─── Uploading View ───────────────────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  const _UploadingView({required this.state});

  final ImportUploading state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Hochladen…', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${state.files.length} Datei(en) werden hochgeladen',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Overall progress
          LinearProgressIndicator(value: state.overallProgress),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${(state.overallProgress * 100).toStringAsFixed(0)} %',
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Per-file list
          Expanded(
            child: ListView.separated(
              itemCount: state.files.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final file = state.files[idx];
                return _FileProgressTile(file: file);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FileProgressTile extends StatelessWidget {
  const _FileProgressTile({required this.file});

  final FileUploadProgress file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isError = file.status == FileUploadStatus.failed;
    final isDone = file.status == FileUploadStatus.uploaded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : isDone
                        ? Icons.check_circle_outline
                        : Icons.insert_drive_file_outlined,
                size: 20,
                color: isError
                    ? AppColors.error
                    : isDone
                        ? AppColors.success
                        : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  file.displayName,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isError
                    ? 'Fehler'
                    : isDone
                        ? 'Fertig'
                        : '${(file.progress * 100).toStringAsFixed(0)} %',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isError ? AppColors.error : null,
                ),
              ),
            ],
          ),
          if (!isDone && !isError) ...[
            const SizedBox(height: AppSpacing.xs),
            LinearProgressIndicator(value: file.progress),
          ],
          if (isError && file.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                file.errorMessage!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Extracting View ──────────────────────────────────────────────────────────

class _ExtractingView extends StatelessWidget {
  const _ExtractingView({required this.state});

  final ImportExtracting state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.auto_awesome_outlined, size: 56),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Seiten werden extrahiert…',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Die KI analysiert deine Noten im Hintergrund.\nDu kannst gleich mit dem Labeling beginnen.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          LinearProgressIndicator(value: state.progress),
          if (state.pages.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.pages.length} Seiten erkannt',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
