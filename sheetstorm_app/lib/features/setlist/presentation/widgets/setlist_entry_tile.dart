import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/features/setlist/presentation/widgets/placeholder_entry.dart';

/// Tile widget for a single setlist entry (song, placeholder, or pause).
class SetlistEntryTile extends StatelessWidget {
  const SetlistEntryTile({
    super.key,
    required this.entry,
    this.showDragHandle = false,
    this.showTiming = false,
    this.isWide = false,
    this.onDelete,
    this.onTap,
  });

  final SetlistEntry entry;
  final bool showDragHandle;
  final bool showTiming;
  final bool isWide;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (entry.isPause) {
      return PlaceholderEntry(entry: entry, showTiming: showTiming);
    }

    final theme = Theme.of(context);

    Widget tile = ListTile(
      leading: _buildLeading(theme),
      title: Text(
        entry.displayTitle,
        style: theme.textTheme.titleMedium?.copyWith(
          fontStyle: entry.isPlatzhalter ? FontStyle.italic : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(theme),
      trailing: _buildTrailing(theme),
      onTap: onTap,
      contentPadding: EdgeInsets.only(
        left: showDragHandle ? 0 : AppSpacing.md,
        right: AppSpacing.md,
      ),
    );

    if (showDragHandle) {
      tile = Row(
        children: [
          ReorderableDragStartListener(
            index: entry.position - 1,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.drag_handle, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: tile),
        ],
      );
    }

    return tile;
  }

  Widget _buildLeading(ThemeData theme) {
    if (entry.isStueck) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          '${entry.position}',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Platzhalter
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.warning.withValues(alpha: 0.1),
      child: const Icon(Icons.push_pin, size: 18, color: AppColors.warning),
    );
  }

  Widget? _buildSubtitle(ThemeData theme) {
    final parts = <String>[];

    if (entry.displaySubtitle != null) {
      parts.add(entry.displaySubtitle!);
    }

    if (entry.isPlatzhalter) {
      parts.add('(Platzhalter)');
    }

    if (showTiming && entry.geschaetzteDauerSekunden != null) {
      final m = entry.geschaetzteDauerSekunden! ~/ 60;
      final s = entry.geschaetzteDauerSekunden! % 60;
      parts.add(s > 0 ? '${m}:${s.toString().padLeft(2, '0')}' : '${m}min');
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' · '),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget? _buildTrailing(ThemeData theme) {
    final children = <Widget>[];

    if (showTiming &&
        entry.startzeitBerechnet != null &&
        entry.endzeitBerechnet != null) {
      children.add(
        Text(
          '${entry.startzeitBerechnet} – ${entry.endzeitBerechnet}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    if (onDelete != null) {
      children.add(
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          color: AppColors.textSecondary,
          tooltip: 'Aus Setlist entfernen',
          onPressed: onDelete,
        ),
      );
    }

    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
