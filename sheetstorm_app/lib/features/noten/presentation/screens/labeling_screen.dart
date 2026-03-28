import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/noten/application/import_notifier.dart';
import 'package:sheetstorm/features/noten/data/models/import_models.dart';

/// Two-mode labeling screen:
/// - Overview (grid): all pages grouped by song, visual separators
/// - Sequential (page-by-page): one page at a time with two action buttons
class LabelingScreen extends ConsumerStatefulWidget {
  const LabelingScreen({super.key, required this.uploadId});

  final String uploadId;

  @override
  ConsumerState<LabelingScreen> createState() => _LabelingScreenState();
}

class _LabelingScreenState extends ConsumerState<LabelingScreen> {
  bool _sequentialMode = false;
  int _sequentialIndex = 0;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    // Navigate when metadata editing starts
    ref.listen<ImportState>(importProvider, (_, next) {
      if (next is ImportEditingMetadata) {
        context.push(
          AppRoutes.importMetadata(next.uploadId, next.currentIndex.toString()),
        );
      }
    });

    if (importState is! ImportLabeling) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final labeling = importState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stücke zuordnen'),
        actions: [
          // Toggle between overview and sequential mode
          IconButton(
            icon: Icon(
              _sequentialMode
                  ? Icons.grid_view_outlined
                  : Icons.view_carousel_outlined,
            ),
            tooltip: _sequentialMode ? 'Übersicht' : 'Seite für Seite',
            onPressed: () => setState(() {
              _sequentialMode = !_sequentialMode;
              _sequentialIndex = 0;
            }),
          ),
          TextButton(
            onPressed: () => ref
                .read(importProvider.notifier)
                .labelingAbschliessen(),
            child: const Text('Weiter'),
          ),
        ],
      ),
      body: _sequentialMode
          ? _SequentialView(
              labeling: labeling,
              currentIndex: _sequentialIndex,
              onNext: () => setState(() {
                if (_sequentialIndex < labeling.seiten.length - 1) {
                  _sequentialIndex++;
                }
              }),
              onPrev: () => setState(() {
                if (_sequentialIndex > 0) _sequentialIndex--;
              }),
              onNeuesStueck: (seiteId) {
                ref
                    .read(importProvider.notifier)
                    .neueStueckGrenzeBei(seiteId);
              },
              onGleichesStueck: () {
                // Page stays in current group — just advance
                if (_sequentialIndex < labeling.seiten.length - 1) {
                  setState(() => _sequentialIndex++);
                } else {
                  ref
                      .read(importProvider.notifier)
                      .labelingAbschliessen();
                }
              },
            )
          : _OverviewView(labeling: labeling),
      bottomNavigationBar: _sequentialMode
          ? null
          : _OverviewBottomBar(stueckeCount: labeling.stuecke.length),
    );
  }
}

// ─── Sequential Mode ──────────────────────────────────────────────────────────

class _SequentialView extends StatelessWidget {
  const _SequentialView({
    required this.labeling,
    required this.currentIndex,
    required this.onNext,
    required this.onPrev,
    required this.onNeuesStueck,
    required this.onGleichesStueck,
  });

  final ImportLabeling labeling;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final ValueChanged<String> onNeuesStueck;
  final VoidCallback onGleichesStueck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seite = labeling.seiten[currentIndex];
    final total = labeling.seiten.length;

    // Find which song this page belongs to
    final stueckIdx = _stueckIndexFuerSeite(seite.seiteId, labeling.stuecke);
    final isFirstInStueck = stueckIdx != null &&
        labeling.stuecke[stueckIdx].seitenIds.first == seite.seiteId;

    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(value: (currentIndex + 1) / total),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seite ${currentIndex + 1} von $total',
                style: theme.textTheme.bodyMedium,
              ),
              if (stueckIdx != null)
                _StueckBadge(
                  nummer: stueckIdx + 1,
                  titel: labeling.stuecke[stueckIdx].displayTitel,
                ),
            ],
          ),
        ),

        // Page thumbnail
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.7, // portrait sheet music
                child: _SeiteVorschau(
                  seite: seite,
                  isFirstInStueck: isFirstInStueck,
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "New song starts here" — shown only when page is NOT first of a song
              if (!isFirstInStueck)
                OutlinedButton.icon(
                  onPressed: () => onNeuesStueck(seite.seiteId),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Neues Stück beginnt hier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: (stueckIdx != null && stueckIdx > 0)
                      ? () => onNeuesStueck(seite.seiteId)
                      : null,
                  icon: const Icon(Icons.merge_outlined),
                  label: const Text('Mit vorherigem Stück verbinden'),
                ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: currentIndex < labeling.seiten.length - 1
                    ? onGleichesStueck
                    : () {},
                icon: Icon(
                  currentIndex < labeling.seiten.length - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                ),
                label: Text(
                  currentIndex < labeling.seiten.length - 1
                      ? 'Gleiches Stück — weiter'
                      : 'Fertig',
                ),
              ),
            ],
          ),
        ),

        // Navigation arrows
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.outlined(
                onPressed: currentIndex > 0 ? onPrev : null,
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Vorherige Seite',
              ),
              Text('${currentIndex + 1} / $total',
                  style: theme.textTheme.bodyMedium),
              IconButton.outlined(
                onPressed:
                    currentIndex < total - 1 ? onNext : null,
                icon: const Icon(Icons.arrow_forward),
                tooltip: 'Nächste Seite',
              ),
            ],
          ),
        ),
      ],
    );
  }

  int? _stueckIndexFuerSeite(String seiteId, List<TempStueck> stuecke) {
    for (int i = 0; i < stuecke.length; i++) {
      if (stuecke[i].seitenIds.contains(seiteId)) return i;
    }
    return null;
  }
}

// ─── Overview Mode ────────────────────────────────────────────────────────────

class _OverviewView extends ConsumerWidget {
  const _OverviewView({required this.labeling});

  final ImportLabeling labeling;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: labeling.stuecke.length,
      itemBuilder: (context, stueckIdx) {
        final stueck = labeling.stuecke[stueckIdx];
        final seiten = stueck.seitenIds
            .map((id) => labeling.seiteFuer(id))
            .whereType<SeiteInfo>()
            .toList();

        return _StueckCard(
          stueck: stueck,
          seiten: seiten,
          stueckNummer: stueckIdx + 1,
          canMergeWithPrev: stueckIdx > 0,
          onMergeWithPrev: () => ref
              .read(importProvider.notifier)
              .stueckMitVorherigemVerbinden(stueck.tempId),
          onSeiteReorder: (oldIdx, newIdx) {
            ref
                .read(importProvider.notifier)
                .seiteVerschieben(stueck.tempId, oldIdx, newIdx);
          },
          onSeiteToNewStueck: (seiteId) {
            ref
                .read(importProvider.notifier)
                .neueStueckGrenzeBei(seiteId);
          },
        );
      },
    );
  }
}

class _StueckCard extends StatefulWidget {
  const _StueckCard({
    required this.stueck,
    required this.seiten,
    required this.stueckNummer,
    required this.canMergeWithPrev,
    required this.onMergeWithPrev,
    required this.onSeiteReorder,
    required this.onSeiteToNewStueck,
  });

  final TempStueck stueck;
  final List<SeiteInfo> seiten;
  final int stueckNummer;
  final bool canMergeWithPrev;
  final VoidCallback onMergeWithPrev;
  final void Function(int oldIdx, int newIdx) onSeiteReorder;
  final ValueChanged<String> onSeiteToNewStueck;

  @override
  State<_StueckCard> createState() => _StueckCardState();
}

class _StueckCardState extends State<_StueckCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // ── Song header ────────────────────────────────────────────────────
        Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '${widget.stueckNummer}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.stueck.displayTitel,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${widget.seiten.length} Seite(n)',
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.canMergeWithPrev)
                      IconButton(
                        icon: const Icon(Icons.merge_outlined),
                        tooltip: 'Mit vorherigem Stück verbinden',
                        onPressed: widget.onMergeWithPrev,
                      ),
                    IconButton(
                      icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                  ],
                ),
              ),

              // ── Page thumbnails (reorderable) ───────────────────────────
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
                  child: SizedBox(
                    height: 120,
                    child: ReorderableListView.builder(
                      scrollDirection: Axis.horizontal,
                      buildDefaultDragHandles: false,
                      itemCount: widget.seiten.length,
                      onReorder: widget.onSeiteReorder,
                      itemBuilder: (context, idx) {
                        final seite = widget.seiten[idx];
                        return ReorderableDragStartListener(
                          key: ValueKey(seite.seiteId),
                          index: idx,
                          child: GestureDetector(
                            onLongPress: () =>
                                _showSeiteOptions(context, seite),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              child: _SeiteVorschau(
                                seite: seite,
                                isFirstInStueck: idx == 0,
                                compact: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── Divider between songs ──────────────────────────────────────────
        if (widget.stueckNummer > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: Text(
                    '↓ Stück ${widget.stueckNummer + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _showSeiteOptions(BuildContext context, SeiteInfo seite) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Neues Stück ab hier'),
              subtitle: const Text('Seite wird zum Beginn eines neuen Stücks'),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onSeiteToNewStueck(seite.seiteId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBottomBar extends StatelessWidget {
  const _OverviewBottomBar({required this.stueckeCount});

  final int stueckeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '$stueckeCount Stück(e) erkannt — Halte eine Seite gedrückt für Optionen',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SeiteVorschau extends StatelessWidget {
  const _SeiteVorschau({
    required this.seite,
    this.isFirstInStueck = false,
    this.compact = false,
  });

  final SeiteInfo seite;
  final bool isFirstInStueck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = compact ? 80.0 : double.infinity;

    return Stack(
      children: [
        Container(
          width: compact ? size : null,
          height: compact ? size : null,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: AppSpacing.roundedMd,
            border: isFirstInStueck
                ? Border.all(
                    color: AppColors.primary,
                    width: 2,
                  )
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: seite.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: seite.thumbnailUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_outlined),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.description_outlined),
                      if (!compact) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Seite ${seite.seiteNr}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        // "New song" indicator badge
        if (isFirstInStueck)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppSpacing.roundedSm,
              ),
              child: Text(
                '♪ Stück',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onPrimary,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        // Page number
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Text(
              '${seite.seiteNr}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StueckBadge extends StatelessWidget {
  const _StueckBadge({required this.nummer, required this.titel});

  final int nummer;
  final String titel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Text(
        'Stück $nummer',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
