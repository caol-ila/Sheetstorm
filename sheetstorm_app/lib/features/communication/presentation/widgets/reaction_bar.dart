import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';

class ReactionBar extends StatelessWidget {
  const ReactionBar({
    required this.reactions,
    required this.commentCount,
    required this.onReactionTap,
    super.key,
  });

  final Map<ReactionType, Reaction> reactions;
  final int commentCount;
  final void Function(ReactionType) onReactionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...ReactionType.values.map((type) {
          final reaction = reactions[type];
          final count = reaction?.count ?? 0;
          final hasReacted = reaction?.hasReacted ?? false;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: InkWell(
              borderRadius: AppSpacing.roundedSm,
              onTap: () => onReactionTap(type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: hasReacted
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: AppSpacing.roundedSm,
                  border: Border.all(
                    color: hasReacted ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      type.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (count > 0) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: AppTypography.fontSizeSm,
                          fontWeight: hasReacted
                              ? AppTypography.weightBold
                              : AppTypography.weightNormal,
                          color:
                              hasReacted ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        if (commentCount > 0)
          Row(
            children: [
              const Icon(
                Icons.comment_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                commentCount.toString(),
                style: const TextStyle(
                  fontSize: AppTypography.fontSizeSm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
