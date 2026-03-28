import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

class PinBadge extends StatelessWidget {
  const PinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: AppColors.warning),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.push_pin, size: 14, color: AppColors.warning),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Gepinnt',
            style: TextStyle(
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightBold,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
