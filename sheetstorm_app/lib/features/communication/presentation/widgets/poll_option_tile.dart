import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';

class PollOptionTile extends StatelessWidget {
  const PollOptionTile({
    required this.option,
    required this.poll,
    required this.isSelected,
    this.onTap,
    super.key,
  });

  final PollOption option;
  final Poll poll;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canShowResults = poll.showResultsAfterVoting ||
        poll.hasVoted ||
        poll.status == PollStatus.ended;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: AppSpacing.roundedMd,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onTap != null) ...[
                    Icon(
                      poll.isMultiSelect
                          ? (isSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank)
                          : (isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked),
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ] else if (option.hasVoted) ...[
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeBase,
                        fontWeight: isSelected || option.hasVoted
                            ? AppTypography.weightBold
                            : AppTypography.weightNormal,
                      ),
                    ),
                  ),
                  if (canShowResults)
                    Text(
                      '${option.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeBase,
                        fontWeight: option.hasVoted
                            ? AppTypography.weightBold
                            : AppTypography.weightNormal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              if (canShowResults) ...[
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: AppSpacing.roundedSm,
                  child: LinearProgressIndicator(
                    value: option.percentage / 100,
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      option.hasVoted
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${option.voteCount} ${option.voteCount == 1 ? 'Stimme' : 'Stimmen'}',
                  style: const TextStyle(
                    fontSize: AppTypography.fontSizeXs,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
