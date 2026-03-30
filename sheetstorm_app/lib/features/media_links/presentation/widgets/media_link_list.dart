import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/media_links/application/media_link_notifier.dart';
import 'package:sheetstorm/features/media_links/data/models/media_link_models.dart';
import 'package:sheetstorm/features/media_links/presentation/widgets/listen_button.dart';
import 'package:sheetstorm/features/media_links/presentation/widgets/media_link_editor.dart';

class MediaLinkList extends ConsumerWidget {
  const MediaLinkList({
    required this.kapelleId,
    required this.stueckId,
    this.canEdit = false,
    super.key,
  });

  final String kapelleId;
  final String stueckId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(
      mediaLinkProvider(kapelleId, stueckId),
    );

    return linksAsync.when(
      data: (links) {
        if (links.isEmpty) {
          return _EmptyState(
            canEdit: canEdit,
            onAdd: () => _showAddDialog(context, ref),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Media Links',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...links.map((link) => MediaLinkTile(
                  link: link,
                  canEdit: canEdit,
                  onDelete: canEdit
                      ? () => _deleteLink(context, ref, link.id)
                      : null,
                )),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Link hinzufügen'),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text('Fehler beim Laden der Links: $err'),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: MediaLinkEditor(
          kapelleId: kapelleId,
          stueckId: stueckId,
        ),
      ),
    );
  }

  Future<void> _deleteLink(
    BuildContext context,
    WidgetRef ref,
    String linkId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link entfernen'),
        content: const Text('Möchtest du diesen Link wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final notifier =
          ref.read(mediaLinkProvider(kapelleId, stueckId).notifier);
      await notifier.deleteLink(linkId);
    }
  }
}

class MediaLinkTile extends StatelessWidget {
  const MediaLinkTile({
    required this.link,
    this.canEdit = false,
    this.onDelete,
    super.key,
  });

  final MediaLink link;
  final bool canEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: _buildIcon(),
        title: Text(
          link.titel ?? 'Unbekannter Titel',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          link.formattedDuration.isEmpty
              ? link.plattform.label
              : '${link.plattform.label} · ${link.formattedDuration}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListenButton(url: link.url, platform: link.plattform),
            if (canEdit && onDelete != null) ...[
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Entfernen',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return switch (link.plattform) {
      MediaLinkType.youtube => const Icon(Icons.play_circle, color: Colors.red),
      MediaLinkType.spotify =>
        const Icon(Icons.music_note, color: Colors.green),
      MediaLinkType.soundcloud =>
        const Icon(Icons.cloud, color: Colors.orange),
      _ => const Icon(Icons.link),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.canEdit,
    required this.onAdd,
  });

  final bool canEdit;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.audiotrack,
            size: 48,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Keine Media Links vorhanden',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (canEdit) ...[
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Link hinzufügen'),
            ),
          ],
        ],
      ),
    );
  }
}
