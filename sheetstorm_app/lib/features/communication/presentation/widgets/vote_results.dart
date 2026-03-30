import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';

class VoteResults extends StatelessWidget {
  const VoteResults({
    required this.poll,
    super.key,
  });

  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final canShowResults = poll.showResultsAfterVoting || 
                          poll.hasVoted || 
                          poll.status == PollStatus.ended;

    if (!canShowResults) {
      return const Text(
        'Ergebnisse werden nach der Abstimmung angezeigt',
        style: TextStyle(
          fontSize: AppTypography.fontSizeSm,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: poll.options.map((option) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (option.hasVoted)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  if (option.hasVoted) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeBase,
                        fontWeight: option.hasVoted
                            ? AppTypography.weightBold
                            : AppTypography.weightNormal,
                      ),
                    ),
                  ),
                  Text(
                    '${option.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeSm,
                      fontWeight: option.hasVoted
                          ? AppTypography.weightBold
                          : AppTypography.weightNormal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: AppSpacing.roundedSm,
                child: LinearProgressIndicator(
                  value: option.percentage / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    option.hasVoted ? AppColors.primary : AppColors.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
