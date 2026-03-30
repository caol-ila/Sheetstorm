import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentThread extends StatelessWidget {
  const CommentThread({
    required this.comments,
    super.key,
  });

  final List<Comment> comments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: comments.map((comment) => _CommentTile(comment: comment)).toList(),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final timeAgo = timeago.format(comment.createdAt, locale: 'de');

    if (comment.isDeleted) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.roundedMd,
          ),
          child: const Text(
            'Kommentar gelöscht',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.roundedMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.author.avatarUrl != null
                      ? NetworkImage(comment.author.avatarUrl!)
                      : null,
                  child: comment.author.avatarUrl == null
                      ? Text(comment.author.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.name,
                        style: const TextStyle(
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: AppTypography.fontSizeXs,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              comment.content,
              style: const TextStyle(fontSize: AppTypography.fontSizeBase),
            ),
            if (comment.imageUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppSpacing.roundedSm,
                child: Image.network(
                  comment.imageUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
