import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/reaction_bar.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/pin_badge.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.bandId,
    super.key,
  });

  final Post post;
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
          // TODO: Navigate to post detail
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: AppTypography.fontSizeLg,
                  fontWeight: AppTypography.weightBold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: AppTypography.fontSizeBase,
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (post.attachments.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildAttachments(),
              ],
              const SizedBox(height: AppSpacing.md),
              ReactionBar(
                reactions: post.reactions,
                commentCount: post.commentCount,
                onReactionTap: (type) {
                  // TODO: Handle reaction
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final timeAgo = timeago.format(post.createdAt, locale: 'de');

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: post.author.avatarUrl != null
              ? NetworkImage(post.author.avatarUrl!)
              : null,
          child: post.author.avatarUrl == null
              ? Text(post.author.name[0].toUpperCase())
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
                    post.author.name,
                    style: const TextStyle(
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  if (post.author.role != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${post.author.role}',
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
        if (post.isPinned) const PinBadge(),
      ],
    );
  }

  Widget _buildAttachments() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: post.attachments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final attachment = post.attachments[index];
          return ClipRRect(
            borderRadius: AppSpacing.roundedSm,
            child: Container(
              width: 100,
              color: AppColors.surface,
              child: attachment.type == 'image'
                  ? Image.network(
                      attachment.url,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf, size: 32),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            attachment.filename,
                            style: const TextStyle(
                              fontSize: AppTypography.fontSizeXs,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
