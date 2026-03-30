import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';

/// Visual widget for pause and placeholder entries in a setlist.
class PlaceholderEntry extends StatelessWidget {
  const PlaceholderEntry({
    super.key,
    required this.entry,
    this.showTiming = false,
  });

  final SetlistEntry entry;
  final bool showTiming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPause = entry.isPause;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isPause
            ? AppColors.surface
            : AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(
          color: isPause ? AppColors.border : AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPause
                  ? AppColors.textSecondary.withValues(alpha: 0.1)
                  : AppColors.warning.withValues(alpha: 0.15),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Icon(
              isPause ? Icons.pause_circle_outline : Icons.push_pin_outlined,
              size: 20,
              color:
                  isPause ? AppColors.textSecondary : AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.displayTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: isPause
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                if (entry.displaySubtitle != null)
                  Text(
                    entry.displaySubtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (!isPause && entry.isPlatzhalter)
                  Text(
                    '(Platzhalter)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
          ),

          // Timing
          if (showTiming &&
              entry.startzeitBerechnet != null &&
              entry.endzeitBerechnet != null)
            Text(
              '${entry.startzeitBerechnet} – ${entry.endzeitBerechnet}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
