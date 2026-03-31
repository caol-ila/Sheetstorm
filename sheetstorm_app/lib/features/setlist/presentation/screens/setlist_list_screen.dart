import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/application/setlist_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';

class SetlistListScreen extends ConsumerStatefulWidget {
  const SetlistListScreen({super.key});

  @override
  ConsumerState<SetlistListScreen> createState() => _SetlistListScreenState();
}

class _SetlistListScreenState extends ConsumerState<SetlistListScreen> {
  final _searchController = TextEditingController();
  SetlistTyp? _filterTyp;
  String _sortierung = 'datum_desc';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(setlistListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Suche',
            onPressed: _showSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Sort bar
          _FilterBar(
            selectedTyp: _filterTyp,
            sortierung: _sortierung,
            onTypChanged: (typ) {
              setState(() => _filterTyp = typ);
              ref.read(setlistListProvider.notifier).filter(
                    typ: typ,
                    sortierung: _sortierung,
                  );
            },
            onSortChanged: (sort) {
              setState(() => _sortierung = sort);
              ref.read(setlistListProvider.notifier).filter(
                    typ: _filterTyp,
                    sortierung: sort,
                  );
            },
          ),
          Expanded(
            child: listState.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                onRetry: () =>
                    ref.read(setlistListProvider.notifier).refresh(),
              ),
              data: (setlists) {
                if (setlists.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(setlistListProvider.notifier)
                      .refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.sm,
                      bottom: 120,
                    ),
                    itemCount: setlists.length,
                    itemBuilder: (context, index) {
                      final setlist = setlists[index];
                      return _SetlistCard(
                        setlist: setlist,
                        onTap: () => context.go(
                          '/app/setlists/${setlist.id}',
                        ),
                        onPlay: () => context.go(
                          '/app/setlists/${setlist.id}/play',
                        ),
                        onDelete: () => _confirmDelete(setlist),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Neue Setlist'),
      ),
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: _SetlistSearchDelegate(ref),
    );
  }

  Future<void> _confirmDelete(Setlist setlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setlist löschen?'),
        content: Text(
          '„${setlist.name}" wirklich löschen?\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final deleted = await ref
          .read(setlistListProvider.notifier)
          .deleteSetlist(setlist.id);
      if (deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('„${setlist.name}" gelöscht'),
            action: SnackBarAction(
              label: 'Rückgängig',
              onPressed: () {
                // Undo not yet supported — re-create would require full data
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    SetlistTyp selectedTyp = SetlistTyp.konzert;

    final result = await showDialog<(String, SetlistTyp)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Neue Setlist erstellen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'z.B. Frühjahrskonzert 2026',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<SetlistTyp>(
                value: selectedTyp,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: SetlistTyp.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() => selectedTyp = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context, (name, selectedTyp));
              },
              child: const Text('Erstellen'),
            ),
          ],
        ),
      ),
    );

    if (result != null && mounted) {
      final setlist = await ref
          .read(setlistListProvider.notifier)
          .createSetlist(name: result.$1, typ: result.$2);
      if (setlist != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setlist „${setlist.name}" erstellt')),
        );
        context.go('/app/setlists/${setlist.id}');
      }
    }
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedTyp,
    required this.sortierung,
    required this.onTypChanged,
    required this.onSortChanged,
  });

  final SetlistTyp? selectedTyp;
  final String sortierung;
  final ValueChanged<SetlistTyp?> onTypChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<SetlistTyp?>(
              value: selectedTyp,
              decoration: const InputDecoration(
                labelText: 'Filtern nach Typ',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Alle')),
                ...SetlistTyp.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    )),
              ],
              onChanged: onTypChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: sortierung,
              decoration: const InputDecoration(
                labelText: 'Sortieren nach',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'datum_desc',
                    child: Text('Datum (neueste)')),
                DropdownMenuItem(
                    value: 'datum_asc',
                    child: Text('Datum (älteste)')),
                DropdownMenuItem(
                    value: 'name_asc', child: Text('Name (A-Z)')),
                DropdownMenuItem(
                    value: 'name_desc', child: Text('Name (Z-A)')),
              ],
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Setlist Card ─────────────────────────────────────────────────────────────

class _SetlistCard extends StatelessWidget {
  const _SetlistCard({
    required this.setlist,
    required this.onTap,
    required this.onPlay,
    required this.onDelete,
  });

  final Setlist setlist;
  final VoidCallback onTap;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  IconData get _typIcon => switch (setlist.typ) {
        SetlistTyp.konzert => Icons.music_note_rounded,
        SetlistTyp.probe => Icons.school_rounded,
        SetlistTyp.marschmusik => Icons.directions_walk_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(setlist.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedMd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(_typIcon, size: 32, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        setlist.name,
                        style: theme.textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            setlist.typ.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (setlist.datum != null) ...[
                            const Text(' · '),
                            Text(
                              setlist.datum!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${setlist.anzahlEintraege} Stücke · ${setlist.formattedDauer}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (setlist.anzahlEintraege > 0)
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled),
                    color: AppColors.primary,
                    iconSize: 36,
                    tooltip: 'Spielen',
                    onPressed: onPlay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Noch keine Setlists',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Erstelle deine erste Setlist für Proben oder Konzerte.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Fehler beim Laden', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

// ─── Search Delegate ──────────────────────────────────────────────────────────

class _SetlistSearchDelegate extends SearchDelegate<String?> {
  _SetlistSearchDelegate(this.ref);
  final WidgetRef ref;

  @override
  String get searchFieldLabel => 'Suche nach Name...';

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty) {
      ref.read(setlistListProvider.notifier).search(query);
    }
    close(context, null);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Gib einen Suchbegriff ein'),
    );
  }
}
