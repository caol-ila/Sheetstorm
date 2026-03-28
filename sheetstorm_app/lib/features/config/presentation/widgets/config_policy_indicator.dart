/// Policy indicator widget — 🔒 lock icon + tooltip — Issue #35
///
/// Shows when a setting is locked by Kapelle admin policy.

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

class ConfigPolicyIndicator extends StatelessWidget {
  const ConfigPolicyIndicator({
    super.key,
    this.explanation,
  });

  final String? explanation;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: explanation ?? 'Von deiner Kapelle festgelegt',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: AppSpacing.roundedSm,
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock,
              size: 16,
              color: AppColors.warning,
              semanticLabel: 'Gesperrt',
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Von Kapelle festgelegt',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  color: AppColors.warning,
                  fontWeight: AppTypography.weightMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full policy explanation block shown when a setting is locked.
class ConfigPolicyExplanation extends StatelessWidget {
  const ConfigPolicyExplanation({
    super.key,
    this.adminKontakt,
  });

  final String? adminKontakt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.05),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.warning.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock, size: 20, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Erzwungene Einstellung',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Diese Einstellung wurde von deiner Kapelle festgelegt und kann nicht geändert werden.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (adminKontakt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kontaktiere $adminKontakt um Änderungen anzufragen.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
