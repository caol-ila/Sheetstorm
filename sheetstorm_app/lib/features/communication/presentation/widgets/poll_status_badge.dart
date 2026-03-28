import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';

class PollStatusBadge extends StatelessWidget {
  const PollStatusBadge({
    required this.status,
    super.key,
  });

  final PollStatus status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == PollStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: (isActive ? AppColors.success : AppColors.textSecondary)
            .withOpacity(0.1),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: AppTypography.fontSizeXs,
          fontWeight: AppTypography.weightBold,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}
