import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/sheet_music/application/import_notifier.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';

/// Final review screen before committing the import.
class ImportSummaryScreen extends ConsumerWidget {
  const ImportSummaryScreen({super.key, required this.uploadId});

  final String uploadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final importState = ref.watch(importProvider);

    ref.listen<ImportState>(importProvider, (_, next) {
      if (next is ImportComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${next.piecesCount} Stück(e) erfolgreich importiert! 🎵',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.library);
      } else if (next is ImportError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    if (importState is ImportCompleting) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              const Text('Import wird abgeschlossen…'),
            ],
          ),
        ),
      );
    }

    if (importState is! ImportSummary) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final summary = importState;
    final totalSeiten =
        summary.pieces.fold(0, (sum, s) => sum + s.pageIds.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import bestätigen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Go back to metadata editing
            ref.read(importProvider.notifier);
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          // ── Summary header ──────────────────────────────────────────────
          _SummaryHeader(
            piecesCount: summary.pieces.length,
            pageCount: totalSeiten,
            ziel: summary.ziel,
          ),

          // ── Song list ───────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: summary.pieces.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final piece = summary.pieces[idx];
                return _PieceSummaryTile(
                  piece: piece,
                  number: idx + 1,
                  onEdit: () {
                    // Go back to edit this specific song
                    // (re-enters metadata editing at the right index)
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),

          // ── Confirm button ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => ref
                        .read(importProvider.notifier)
                        .completeImport(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      '${summary.pieces.length} Stück(e) importieren',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                          AppSpacing.touchTargetPlay),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      ref.read(importProvider.notifier).reset();
                      context.go(AppRoutes.library);
                    },
                    child: const Text('Abbrechen'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.piecesCount,
    required this.pageCount,
    required this.ziel,
  });

  final int piecesCount;
  final int pageCount;
  final ImportTarget ziel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.library_music_outlined, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$piecesCount Stück(e) erkannt',
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  '$pageCount Seite(n) · ${ziel == ImportTarget.band ? 'Kapellen-Bibliothek' : 'Persönliche Sammlung'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PieceSummaryTile extends StatelessWidget {
  const _PieceSummaryTile({
    required this.piece,
    required this.number,
    required this.onEdit,
  });

  final TempPiece piece;
  final int number;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMetadata = piece.title != null ||
        piece.composer != null ||
        piece.musicalKey != null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            '$number',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(piece.displayTitle),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${piece.pageIds.length} Seite(n)'),
            if (piece.composer != null)
              Text(
                piece.composer!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            if (piece.musicalKey != null || piece.timeSignature != null)
              Text(
                [piece.musicalKey, piece.timeSignature]
                    .whereType<String>()
                    .join(' · '),
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasMetadata)
              Tooltip(
                message: 'Keine Metadaten — wird als "Unbekannt" gespeichert',
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                  color: AppColors.warning,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Bearbeiten',
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}
