import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/noten/application/import_notifier.dart';
import 'package:sheetstorm/features/noten/data/models/import_models.dart';

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
              '${next.stueckeCount} Stück(e) erfolgreich importiert! 🎵',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.bibliothek);
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
        summary.stuecke.fold(0, (sum, s) => sum + s.seitenIds.length);

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
            stueckeCount: summary.stuecke.length,
            seitenCount: totalSeiten,
            ziel: summary.ziel,
          ),

          // ── Song list ───────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: summary.stuecke.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, idx) {
                final stueck = summary.stuecke[idx];
                return _StueckSummaryTile(
                  stueck: stueck,
                  nummer: idx + 1,
                  onBearbeiten: () {
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
                        .importAbschliessen(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      '${summary.stuecke.length} Stück(e) importieren',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                          AppSpacing.touchTargetPlay),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () {
                      ref.read(importProvider.notifier).zuruecksetzen();
                      context.go(AppRoutes.bibliothek);
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
    required this.stueckeCount,
    required this.seitenCount,
    required this.ziel,
  });

  final int stueckeCount;
  final int seitenCount;
  final ImportZiel ziel;

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
                  '$stueckeCount Stück(e) erkannt',
                  style: theme.textTheme.headlineMedium,
                ),
                Text(
                  '$seitenCount Seite(n) · ${ziel == ImportZiel.kapelle ? 'Kapellen-Bibliothek' : 'Persönliche Sammlung'}',
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

class _StueckSummaryTile extends StatelessWidget {
  const _StueckSummaryTile({
    required this.stueck,
    required this.nummer,
    required this.onBearbeiten,
  });

  final TempStueck stueck;
  final int nummer;
  final VoidCallback onBearbeiten;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMetadata = stueck.titel != null ||
        stueck.komponist != null ||
        stueck.tonart != null;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            '$nummer',
            style: TextStyle(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(stueck.displayTitel),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${stueck.seitenIds.length} Seite(n)'),
            if (stueck.komponist != null)
              Text(
                stueck.komponist!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            if (stueck.tonart != null || stueck.taktart != null)
              Text(
                [stueck.tonart, stueck.taktart]
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
              onPressed: onBearbeiten,
            ),
          ],
        ),
      ),
    );
  }
}
