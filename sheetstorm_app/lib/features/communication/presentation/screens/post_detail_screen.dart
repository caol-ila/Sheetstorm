import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/application/post_notifier.dart';
import 'package:sheetstorm/features/communication/data/models/post_models.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/reaction_bar.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/pin_badge.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/comment_thread.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    required this.bandId,
    required this.postId,
    super.key,
  });

  final String bandId;
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postAsync =
        ref.watch(postDetailProvider(widget.bandId, widget.postId));
    final commentsAsync =
        ref.watch(postCommentsProvider(widget.bandId, widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPostMenu(context, postAsync.value),
          ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (post) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPostHeader(post),
                    const SizedBox(height: AppSpacing.md),
                    if (post.isPinned) ...[
                      const PinBadge(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: AppTypography.fontSizeBase,
                      ),
                    ),
                    if (post.attachments.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildAttachments(post.attachments),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ReactionBar(
                      reactions: post.reactions,
                      commentCount: post.commentCount,
                      onReactionTap: (type) => _handleReaction(post, type),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Kommentare',
                      style: TextStyle(
                        fontSize: AppTypography.fontSizeLg,
                        fontWeight: AppTypography.weightBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    commentsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Text('Fehler: $error'),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: Text(
                                'Noch keine Kommentare',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }
                        return CommentThread(comments: comments);
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildCommentInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostHeader(Post post) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final timeAgo = timeago.format(post.createdAt, locale: 'de');

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: post.author.avatarUrl != null
              ? NetworkImage(post.author.avatarUrl!)
              : null,
          child: post.author.avatarUrl == null
              ? Text(post.author.name[0].toUpperCase())
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    post.author.name,
                    style: const TextStyle(
                      fontSize: AppTypography.fontSizeLg,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  if (post.author.role != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${post.author.role}',
                      style: const TextStyle(
                        fontSize: AppTypography.fontSizeBase,
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
      ],
    );
  }

  Widget _buildAttachments(List<Attachment> attachments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: attachments.map((attachment) {
        if (attachment.type == 'image') {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ClipRRect(
              borderRadius: AppSpacing.roundedMd,
              child: Image.network(
                attachment.url,
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return Card(
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: Text(attachment.filename),
            subtitle: Text('${(attachment.sizeBytes / 1024).toStringAsFixed(0)} KB'),
            onTap: () {
              // TODO: Open PDF
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Kommentar hinzufügen...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _submitComment,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _handleReaction(Post post, ReactionType type) {
    final hasReacted = post.reactions[type]?.hasReacted ?? false;
    if (hasReacted) {
      ref
          .read(postDetailProvider(widget.bandId, widget.postId).notifier)
          .removeReaction();
    } else {
      ref
          .read(postDetailProvider(widget.bandId, widget.postId).notifier)
          .addReaction(type);
    }
  }

  void _submitComment() {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    ref
        .read(postCommentsProvider(widget.bandId, widget.postId).notifier)
        .addComment(content: content)
        .then((comment) {
      if (comment != null) {
        _commentController.clear();
      }
    });
  }

  void _showPostMenu(BuildContext context, Post? post) {
    if (post == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(post.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(post.isPinned ? 'Nicht mehr pinnen' : 'Pinnen'),
            onTap: () {
              Navigator.pop(context);
              ref
                  .read(postDetailProvider(widget.bandId, widget.postId).notifier)
                  .togglePin(!post.isPinned);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Bearbeiten'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to edit
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.error),
            title: const Text('Löschen', style: TextStyle(color: AppColors.error)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Show delete confirmation
            },
          ),
        ],
      ),
    );
  }
}
