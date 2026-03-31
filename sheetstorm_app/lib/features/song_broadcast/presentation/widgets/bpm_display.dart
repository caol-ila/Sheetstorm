import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Large, tappable BPM display with ±1 and ±5 adjustment buttons.
class BpmDisplay extends StatelessWidget {
  const BpmDisplay({
    super.key,
    required this.bpm,
    this.onTap,
    this.onBpmChanged,
  });

  final int bpm;
  final VoidCallback? onTap; // tap tempo
  final ValueChanged<int>? onBpmChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Large BPM number — tap for tap tempo
        GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetPlay * 3,
              minHeight: AppSpacing.touchTargetPlay * 2,
            ),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.roundedLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$bpm',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.weightBold,
                    fontSize: AppTypography.fontSize3xl,
                  ),
                ),
                Text(
                  'BPM  •  Tippen = Tap Tempo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Adjustment row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              label: '−5',
              onTap: () => onBpmChanged?.call(bpm - 5),
              onLongPress: () => onBpmChanged?.call(bpm - 10),
            ),
            const SizedBox(width: AppSpacing.sm),
            _AdjustButton(
              label: '−1',
              onTap: () => onBpmChanged?.call(bpm - 1),
              onLongPress: () => onBpmChanged?.call(bpm - 5),
            ),
            const SizedBox(width: AppSpacing.xl),
            _AdjustButton(
              label: '+1',
              onTap: () => onBpmChanged?.call(bpm + 1),
              onLongPress: () => onBpmChanged?.call(bpm + 5),
              isPrimary: true,
            ),
            const SizedBox(width: AppSpacing.sm),
            _AdjustButton(
              label: '+5',
              onTap: () => onBpmChanged?.call(bpm + 5),
              onLongPress: () => onBpmChanged?.call(bpm + 10),
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.label,
    this.onTap,
    this.onLongPress,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTargetMin,
          minHeight: AppSpacing.touchTargetMin,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: isPrimary ? AppColors.primary : AppColors.border,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTypography.fontSizeBase,
            fontWeight: AppTypography.weightBold,
            color: isPrimary ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
