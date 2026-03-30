import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/application/setlist_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/features/setlist/presentation/widgets/setlist_entry_tile.dart';
import 'package:sheetstorm/features/setlist/presentation/widgets/timing_bar.dart';

class SetlistBuilderScreen extends ConsumerStatefulWidget {
  const SetlistBuilderScreen({super.key, required this.setlistId});
  final String setlistId;

  @override
  ConsumerState<SetlistBuilderScreen> createState() =>
      _SetlistBuilderScreenState();
}

class _SetlistBuilderScreenState extends ConsumerState<SetlistBuilderScreen> {
  bool _showTiming = false;

  @override
  Widget build(BuildContext context) {
    final detailState =
        ref.watch(setlistDetailProvider(widget.setlistId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.go('/app/setlists/${widget.setlistId}'),
        ),
        title: detailState.whenOrNull(
          data: (setlist) => Text(setlist.name),
        ),
        actions: [
          // Timing toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Timing',
                style: theme.textTheme.labelSmall,
              ),
              Switch(
                value: _showTiming,
                onChanged: (v) => setState(() => _showTiming = v),
              ),
            ],
          ),
        ],
      ),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Fehler: $e'),
        ),
        data: (setlist) => _BuilderBody(
          setlist: setlist,
          setlistId: widget.setlistId,
          showTiming: _showTiming,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 480;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            _showAddStueckDialog(context),
                        icon: const Icon(Icons.music_note),
                        label: const Text('+ Stück'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showAddPlatzhalterDialog(context),
                        icon: const Icon(Icons.push_pin),
                        label: const Text('+ Platzhalter'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showAddPauseDialog(context),
                        icon: const Icon(Icons.pause_circle),
                        label: const Text('+ Pause'),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showAddStueckDialog(context),
                    style: FilledButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(AppSpacing.touchTargetMin),
                    ),
                    icon: const Icon(Icons.music_note),
                    label: const Text('Stück hinzufügen'),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showAddPlatzhalterDialog(context),
                          icon: const Icon(Icons.push_pin, size: 18),
                          label: const Text('Platzhalter'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showAddPauseDialog(context),
                          icon:
                              const Icon(Icons.pause_circle, size: 18),
                          label: const Text('Pause'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _showAddStueckDialog(BuildContext context) async {
    // Stub search/pick dialog — in production, this searches the library
    final stueckIdController = TextEditingController();

    final stueckId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppSpacing.roundedFull,
                  ),
                ),
              ),
              Text(
                'Stück hinzufügen',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: stueckIdController,
                decoration: const InputDecoration(
                  labelText: 'Suche nach Titel...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Expanded(
                child: Center(
                  child: Text('Alle Noten durchsuchen'),
                ),
              ),
              FilledButton(
                onPressed: () {
                  final id = stueckIdController.text.trim();
                  if (id.isNotEmpty) Navigator.pop(context, id);
                },
                style: FilledButton.styleFrom(
                  minimumSize:
                      const Size.fromHeight(AppSpacing.touchTargetMin),
                ),
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
        ),
      ),
    );

    if (stueckId != null && mounted) {
      await ref
          .read(setlistDetailProvider(widget.setlistId).notifier)
          .addStueck(stueckId: stueckId);
    }
  }

  Future<void> _showAddPlatzhalterDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final composerController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Platzhalter hinzufügen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: composerController,
              decoration: const InputDecoration(
                  labelText: 'Komponist (optional)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                  labelText: 'Notizen (optional)'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref
          .read(setlistDetailProvider(widget.setlistId).notifier)
          .addPlatzhalter(
            titel: titleController.text.trim(),
            komponist: composerController.text.trim().isNotEmpty
                ? composerController.text.trim()
                : null,
            notizen: notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
          );
    }
  }

  Future<void> _showAddPauseDialog(BuildContext context) async {
    final minutesController = TextEditingController(text: '15');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause hinzufügen'),
        content: TextField(
          controller: minutesController,
          decoration: const InputDecoration(
            labelText: 'Dauer (Minuten)',
            suffixText: 'min',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final minutes =
          int.tryParse(minutesController.text.trim()) ?? 15;
      await ref
          .read(setlistDetailProvider(widget.setlistId).notifier)
          .addPause(dauerSekunden: minutes * 60);
    }
  }
}

// ─── Builder Body ─────────────────────────────────────────────────────────────

class _BuilderBody extends ConsumerWidget {
  const _BuilderBody({
    required this.setlist,
    required this.setlistId,
    required this.showTiming,
  });

  final Setlist setlist;
  final String setlistId;
  final bool showTiming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (setlist.eintraege.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Noch keine Stücke.'),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Füge Stücke, Platzhalter oder Pausen hinzu.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (showTiming)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TimingBar(entries: setlist.eintraege),
          ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: setlist.eintraege.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final entries = List<SetlistEntry>.from(setlist.eintraege);
              final item = entries.removeAt(oldIndex);
              entries.insert(newIndex, item);
              ref
                  .read(
                      setlistDetailProvider(setlistId).notifier)
                  .reorderEntries(entries);
            },
            itemBuilder: (context, index) {
              final entry = setlist.eintraege[index];
              return SetlistEntryTile(
                key: ValueKey(entry.id),
                entry: entry,
                showDragHandle: true,
                showTiming: showTiming,
                onDelete: () {
                  ref
                      .read(setlistDetailProvider(setlistId)
                          .notifier)
                      .deleteEntry(entry.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
