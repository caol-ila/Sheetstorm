import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/sheet_music/application/import_notifier.dart';
import 'package:sheetstorm/features/sheet_music/data/models/import_models.dart';

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
                .completeLabeling(),
            child: const Text('Weiter'),
          ),
        ],
      ),
      body: _sequentialMode
          ? _SequentialView(
              labeling: labeling,
              currentIndex: _sequentialIndex,
              onNext: () => setState(() {
                if (_sequentialIndex < labeling.pages.length - 1) {
                  _sequentialIndex++;
                }
              }),
              onPrev: () => setState(() {
                if (_sequentialIndex > 0) _sequentialIndex--;
              }),
              onNewPiece: (pageId) {
                ref
                    .read(importProvider.notifier)
                    .newPieceBoundaryAt(pageId);
              },
              onSamePiece: () {
                // Page stays in current group — just advance
                if (_sequentialIndex < labeling.pages.length - 1) {
                  setState(() => _sequentialIndex++);
                } else {
                  ref
                      .read(importProvider.notifier)
                      .completeLabeling();
                }
              },
            )
          : _OverviewView(labeling: labeling),
      bottomNavigationBar: _sequentialMode
          ? null
          : _OverviewBottomBar(piecesCount: labeling.pieces.length),
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
    required this.onNewPiece,
    required this.onSamePiece,
  });

  final ImportLabeling labeling;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final ValueChanged<String> onNewPiece;
  final VoidCallback onSamePiece;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final page = labeling.pages[currentIndex];
    final total = labeling.pages.length;

    // Find which song this page belongs to
    final pieceIdx = _pieceIndexForPage(page.pageId, labeling.pieces);
    final isFirstInPiece = pieceIdx != null &&
        labeling.pieces[pieceIdx].pageIds.first == page.pageId;

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
              if (pieceIdx != null)
                _PieceBadge(
                  number: pieceIdx + 1,
                  title: labeling.pieces[pieceIdx].displayTitle,
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
                  page: page,
                  isFirstInPiece: isFirstInPiece,
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
              if (!isFirstInPiece)
                OutlinedButton.icon(
                  onPressed: () => onNewPiece(page.pageId),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Neues Stück beginnt hier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: (pieceIdx != null && pieceIdx > 0)
                      ? () => onNewPiece(page.pageId)
                      : null,
                  icon: const Icon(Icons.merge_outlined),
                  label: const Text('Mit vorherigem Stück verbinden'),
                ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed: currentIndex < labeling.pages.length - 1
                    ? onSamePiece
                    : () {},
                icon: Icon(
                  currentIndex < labeling.pages.length - 1
                      ? Icons.arrow_forward
                      : Icons.check,
                ),
                label: Text(
                  currentIndex < labeling.pages.length - 1
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

  int? _pieceIndexForPage(String pageId, List<TempPiece> pieces) {
    for (int i = 0; i < pieces.length; i++) {
      if (pieces[i].pageIds.contains(pageId)) return i;
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
      itemCount: labeling.pieces.length,
      itemBuilder: (context, pieceIdx) {
        final piece = labeling.pieces[pieceIdx];
        final pages = piece.pageIds
            .map((id) => labeling.pageFor(id))
            .whereType<PageInfo>()
            .toList();

        return _PieceCard(
          piece: piece,
          pages: pages,
          pieceNumber: pieceIdx + 1,
          canMergeWithPrev: pieceIdx > 0,
          onMergeWithPrev: () => ref
              .read(importProvider.notifier)
              .mergePieceWithPrevious(piece.tempId),
          onPageReorder: (oldIdx, newIdx) {
            ref
                .read(importProvider.notifier)
                .movePage(piece.tempId, oldIdx, newIdx);
          },
          onPageToNewPiece: (pageId) {
            ref
                .read(importProvider.notifier)
                .newPieceBoundaryAt(pageId);
          },
        );
      },
    );
  }
}

class _PieceCard extends StatefulWidget {
  const _PieceCard({
    required this.piece,
    required this.pages,
    required this.pieceNumber,
    required this.canMergeWithPrev,
    required this.onMergeWithPrev,
    required this.onPageReorder,
    required this.onPageToNewPiece,
  });

  final TempPiece piece;
  final List<PageInfo> pages;
  final int pieceNumber;
  final bool canMergeWithPrev;
  final VoidCallback onMergeWithPrev;
  final void Function(int oldIdx, int newIdx) onPageReorder;
  final ValueChanged<String> onPageToNewPiece;

  @override
  State<_PieceCard> createState() => _PieceCardState();
}

class _PieceCardState extends State<_PieceCard> {
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
                    '${widget.pieceNumber}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  widget.piece.displayTitle,
                  style: theme.textTheme.titleMedium,
                ),
                subtitle: Text(
                  '${widget.pages.length} Seite(n)',
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
                      itemCount: widget.pages.length,
                      onReorder: widget.onPageReorder,
                      itemBuilder: (context, idx) {
                        final page = widget.pages[idx];
                        return ReorderableDragStartListener(
                          key: ValueKey(page.pageId),
                          index: idx,
                          child: GestureDetector(
                            onLongPress: () =>
                                _showSeiteOptions(context, page),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.xs),
                              child: _SeiteVorschau(
                                page: page,
                                isFirstInPiece: idx == 0,
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
        if (widget.pieceNumber > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm),
                  child: Text(
                    '↓ Stück ${widget.pieceNumber + 1}',
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

  Future<void> _showSeiteOptions(BuildContext context, PageInfo page) async {
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
                widget.onPageToNewPiece(page.pageId);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBottomBar extends StatelessWidget {
  const _OverviewBottomBar({required this.piecesCount});

  final int piecesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          '$piecesCount Stück(e) erkannt — Halte eine Seite gedrückt für Optionen',
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
    required this.page,
    this.isFirstInPiece = false,
    this.compact = false,
  });

  final PageInfo page;
  final bool isFirstInPiece;
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
            border: isFirstInPiece
                ? Border.all(
                    color: AppColors.primary,
                    width: 2,
                  )
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: page.thumbnailUrl != null
              ? CachedNetworkImage(
                  imageUrl: page.thumbnailUrl!,
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
                          'Seite ${page.pageNumber}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        // "New song" indicator badge
        if (isFirstInPiece)
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
              '${page.pageNumber}',
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

class _PieceBadge extends StatelessWidget {
  const _PieceBadge({required this.number, required this.title});

  final int number;
  final String title;

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
        'Stück $number',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
