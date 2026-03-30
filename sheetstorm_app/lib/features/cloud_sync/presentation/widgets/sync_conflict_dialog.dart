import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';

/// Dialog explaining a sync conflict and its LWW resolution.
///
/// The conflict is already resolved server-side (Last-Write-Wins).
/// This dialog informs the user and lets them dismiss it.
class SyncConflictDialog extends StatelessWidget {
  const SyncConflictDialog({
    super.key,
    required this.conflict,
    required this.onDismiss,
  });

  final SyncConflict conflict;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final resolutionLabel = conflict.resolvedWith == 'server'
        ? 'Server-Version'
        : 'Lokale Version';

    return AlertDialog(
      title: const Text('Synchronisationskonflikt'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konflikt für ${conflict.entityType} wurde automatisch gelöst.',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Last-Write-Wins: $resolutionLabel wurde verwendet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Betroffenes Objekt: ${conflict.entityId}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.fontSizeXs,
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: const Size(88, AppSpacing.touchTargetMin),
          ),
          onPressed: onDismiss,
          child: const Text('Verstanden'),
        ),
      ],
    );
  }
}
