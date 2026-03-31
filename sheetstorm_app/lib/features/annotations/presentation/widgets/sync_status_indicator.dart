import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_op_model.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';

/// Compact sync status indicator for the annotation overlay.
/// Shows connection state as icon + optional pending-ops badge.
/// UX-Spec §5.1: 20×20 px, top-right of Spielmodus overlay.
class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(annotationSyncNotifierProvider);

    final (icon, color, label) = _resolve(syncState.status);
    final pendingCount = syncState.pendingOpsCount;

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (pendingCount > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$pendingCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _resolve(AnnotationSyncStatus status) =>
      switch (status) {
        AnnotationSyncStatus.connected => (
            Icons.sync,
            const Color(0xFF16A34A),
            'Annotationen synchronisiert',
          ),
        AnnotationSyncStatus.syncing => (
            Icons.sync,
            const Color(0xFFF59E0B),
            'Annotationen werden synchronisiert',
          ),
        AnnotationSyncStatus.connecting => (
            Icons.sync,
            const Color(0xFFF59E0B),
            'Verbindung wird hergestellt',
          ),
        AnnotationSyncStatus.error => (
            Icons.sync_problem,
            const Color(0xFFDC2626),
            'Annotationen offline',
          ),
        AnnotationSyncStatus.disconnected => (
            Icons.sync_disabled,
            const Color(0xFF6B7280),
            'Sync nicht verbunden',
          ),
      };
}
