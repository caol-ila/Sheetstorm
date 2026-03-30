import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/application/setlist_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/features/setlist/presentation/widgets/setlist_entry_tile.dart';
import 'package:sheetstorm/features/setlist/presentation/widgets/timing_bar.dart';

class SetlistDetailScreen extends ConsumerWidget {
  const SetlistDetailScreen({super.key, required this.setlistId});
  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(setlistDetailProvider(setlistId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/app/setlists'),
        ),
        title: detailState.whenOrNull(
          data: (setlist) => Text(setlist.name),
        ),
        actions: [
          if (detailState.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Bearbeiten',
              onPressed: () => context.go(
                '/app/setlists/$setlistId/edit',
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (action) =>
                  _handleAction(action, context, ref, detailState.value!),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplizieren'),
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text('Löschen',
                        style: TextStyle(color: AppColors.error)),
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Diese Setlist existiert nicht mehr'),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => context.go('/app/setlists'),
                child: const Text('Zurück'),
              ),
            ],
          ),
        ),
        data: (setlist) => _DetailBody(
          setlist: setlist,
          setlistId: setlistId,
        ),
      ),
      bottomNavigationBar: detailState.whenOrNull(
        data: (setlist) => setlist.eintraege.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: () => context.go(
                      '/app/setlists/$setlistId/play',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(AppSpacing.touchTargetMin),
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Setlist spielen'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    BuildContext context,
    WidgetRef ref,
    Setlist setlist,
  ) async {
    switch (action) {
      case 'duplicate':
        final duplicate = await ref
            .read(setlistListProvider.notifier)
            .duplicateSetlist(setlist.id, name: '${setlist.name} (Kopie)');
        if (duplicate != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Setlist dupliziert')),
          );
          context.go('/app/setlists/${duplicate.id}');
        }
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Setlist löschen?'),
            content: Text(
              '„${setlist.name}" wirklich löschen?\n'
              'Diese Aktion kann nicht rückgängig gemacht werden.\n'
              'Verknüpfte Termine zeigen dann „Setlist gelöscht".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await ref
              .read(setlistListProvider.notifier)
              .deleteSetlist(setlist.id);
          if (context.mounted) context.go('/app/setlists');
        }
    }
  }
}

// ─── Detail Body ──────────────────────────────────────────────────────────────

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.setlist, required this.setlistId});
  final Setlist setlist;
  final String setlistId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        return CustomScrollView(
          slivers: [
            // Metadata header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata chips
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Chip(
                          avatar: Icon(
                            _typIcon(setlist.typ),
                            size: 18,
                          ),
                          label: Text(setlist.typ.label),
                        ),
                        if (setlist.datum != null)
                          Chip(
                            avatar: const Icon(Icons.calendar_today,
                                size: 18),
                            label: Text(setlist.datum!),
                          ),
                        Chip(
                          avatar: const Icon(Icons.music_note, size: 18),
                          label: Text(
                              '${setlist.anzahlEintraege} Stücke'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.timer, size: 18),
                          label: Text(setlist.formattedDauer),
                        ),
                      ],
                    ),
                    if (setlist.beschreibung != null &&
                        setlist.beschreibung!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        setlist.beschreibung!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Timing bar
            if (setlist.eintraege.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: TimingBar(entries: setlist.eintraege),
                ),
              ),

            // Entry list
            if (setlist.eintraege.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.playlist_add,
                          size: 48,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Noch keine Stücke.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Wechsle in den Bearbeitungsmodus um Stücke hinzuzufügen.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = setlist.eintraege[index];
                    return SetlistEntryTile(
                      entry: entry,
                      showDragHandle: false,
                      showTiming: true,
                      isWide: isWide,
                    );
                  },
                  childCount: setlist.eintraege.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        );
      },
    );
  }

  IconData _typIcon(SetlistTyp typ) => switch (typ) {
        SetlistTyp.konzert => Icons.music_note_rounded,
        SetlistTyp.probe => Icons.school_rounded,
        SetlistTyp.marschmusik => Icons.directions_walk_rounded,
      };
}
