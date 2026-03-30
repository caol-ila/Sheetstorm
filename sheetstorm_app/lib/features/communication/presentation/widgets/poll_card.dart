import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/poll_status_badge.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/vote_results.dart';
import 'package:timeago/timeago.dart' as timeago;

class PollCard extends StatelessWidget {
  const PollCard({
    required this.poll,
    required this.bandId,
    super.key,
  });

  final Poll poll;
  final String bandId;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
      ),
      child: InkWell(
        borderRadius: AppSpacing.roundedMd,
        onTap: () {
          // TODO: Navigate to poll detail
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.poll, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      poll.question,
                      style: const TextStyle(
                        fontSize: AppTypography.fontSizeLg,
                        fontWeight: AppTypography.weightBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              VoteResults(poll: poll),
              const SizedBox(height: AppSpacing.md),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final timeAgo = timeago.format(poll.createdAt, locale: 'de');

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: poll.author.avatarUrl != null
              ? NetworkImage(poll.author.avatarUrl!)
              : null,
          child: poll.author.avatarUrl == null
              ? Text(poll.author.name[0].toUpperCase())
              : null,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    poll.author.name,
                    style: const TextStyle(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  if (poll.author.role != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${poll.author.role}',
                      style: const TextStyle(
                        fontSize: AppTypography.fontSizeSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                timeAgo,
                style: const TextStyle(
                  fontSize: AppTypography.fontSizeSm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        PollStatusBadge(status: poll.status),
      ],
    );
  }

  Widget _buildFooter() {
    final timeRemaining = poll.timeRemaining;
    String footerText = '${poll.participantCount} Teilnehmer';

    if (poll.hasVoted) {
      footerText = '✓ Du hast abgestimmt · $footerText';
    }

    if (timeRemaining != null && timeRemaining > Duration.zero) {
      final days = timeRemaining.inDays;
      final hours = timeRemaining.inHours % 24;
      if (days > 0) {
        footerText += ' · $days ${days == 1 ? 'Tag' : 'Tage'} übrig';
      } else if (hours > 0) {
        footerText += ' · $hours ${hours == 1 ? 'Stunde' : 'Stunden'} übrig';
      } else {
        footerText += ' · Endet bald';
      }
    }

    return Text(
      footerText,
      style: const TextStyle(
        fontSize: AppTypography.fontSizeSm,
        color: AppColors.textSecondary,
      ),
    );
  }
}
