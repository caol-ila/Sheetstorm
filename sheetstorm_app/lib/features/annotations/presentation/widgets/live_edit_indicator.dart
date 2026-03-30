import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotations/sync/annotation_sync_notifier.dart';

/// Shows active editors ("Max zeichnet...") and conflict banners.
/// UX-Spec §6.3: 24px banner, below sheet music, above bottom nav.
class LiveEditIndicator extends ConsumerWidget {
  const LiveEditIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(annotationSyncNotifierProvider);
    final editors = syncState.activeEditors;
    final conflict = syncState.lastConflict;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Active editors banners
        for (final entry in editors.entries)
          _EditorBanner(userName: entry.key),

        // Conflict banner (LWW resolved)
        if (conflict != null) _ConflictBanner(conflict: conflict),
      ],
    );
  }
}

class _EditorBanner extends StatelessWidget {
  const _EditorBanner({required this.userName});
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$userName zeichnet gerade',
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(60),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit, size: 12),
            const SizedBox(width: 4),
            Text(
              '$userName zeichnet\u2026',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConflictBanner extends StatelessWidget {
  const _ConflictBanner({required this.conflict});
  final ConflictInfo conflict;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Änderung von ${conflict.winnerUserId} wurde übernommen',
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.only(top: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          border: Border.all(color: const Color(0xFFF59E0B)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 14, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(
              'Änderung von ${conflict.winnerUserId} wurde übernommen',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF92400E),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
