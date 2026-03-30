import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/communication/application/poll_notifier.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/poll_status_badge.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/poll_option_tile.dart';
import 'package:timeago/timeago.dart' as timeago;

class PollDetailScreen extends ConsumerStatefulWidget {
  const PollDetailScreen({
    required this.bandId,
    required this.pollId,
    super.key,
  });

  final String bandId;
  final String pollId;

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  final Set<String> _selectedOptions = {};

  @override
  Widget build(BuildContext context) {
    final pollAsync =
        ref.watch(pollDetailProvider(widget.bandId, widget.pollId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Umfrage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showPollMenu(context, pollAsync.value),
          ),
        ],
      ),
      body: pollAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Fehler: $error')),
        data: (poll) {
          if (poll.hasVoted && _selectedOptions.isEmpty) {
            _selectedOptions.addAll(
              poll.options.where((o) => o.hasVoted).map((o) => o.id),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPollHeader(poll),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          const Icon(Icons.poll, size: 24, color: AppColors.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              poll.question,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: AppTypography.weightBold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildPollInfo(poll),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildOptions(poll),
                    ],
                  ),
                ),
              ),
              if (!poll.hasVoted &&
                  poll.status == PollStatus.active &&
                  _selectedOptions.isNotEmpty)
                _buildVoteButton(poll),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPollHeader(Poll poll) {
    timeago.setLocaleMessages('de', timeago.DeMessages());
    final timeAgo = timeago.format(poll.createdAt, locale: 'de');

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: poll.author.avatarUrl != null
              ? NetworkImage(poll.author.avatarUrl!)
              : null,
          child: poll.author.avatarUrl == null
              ? Text(poll.author.name[0].toUpperCase())
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
                    poll.author.name,
                    style: const TextStyle(
                      fontSize: AppTypography.fontSizeLg,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  if (poll.author.role != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '· ${poll.author.role}',
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
        PollStatusBadge(status: poll.status),
      ],
    );
  }

  Widget _buildPollInfo(Poll poll) {
    final timeRemaining = poll.timeRemaining;
    final items = <Widget>[];

    items.add(_buildInfoChip(
      Icons.people,
      '${poll.participantCount} Teilnehmer',
    ));

    if (timeRemaining != null && timeRemaining > Duration.zero) {
      final days = timeRemaining.inDays;
      final hours = timeRemaining.inHours % 24;
      String text;
      if (days > 0) {
        text = '$days ${days == 1 ? 'Tag' : 'Tage'} übrig';
      } else if (hours > 0) {
        text = '$hours ${hours == 1 ? 'Stunde' : 'Stunden'} übrig';
      } else {
        text = 'Endet bald';
      }
      items.add(_buildInfoChip(Icons.timer, text));
    }

    if (poll.isAnonymous) {
      items.add(_buildInfoChip(Icons.visibility_off, 'Anonym'));
    }

    if (poll.isMultiSelect) {
      items.add(_buildInfoChip(Icons.check_box, 'Mehrfachauswahl'));
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      backgroundColor: AppColors.surface,
      labelStyle: const TextStyle(fontSize: AppTypography.fontSizeSm),
    );
  }

  Widget _buildOptions(Poll poll) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: poll.options.map((option) {
        return PollOptionTile(
          option: option,
          poll: poll,
          isSelected: _selectedOptions.contains(option.id),
          onTap: poll.hasVoted || poll.status == PollStatus.ended
              ? null
              : () => _toggleOption(poll, option.id),
        );
      }).toList(),
    );
  }

  Widget _buildVoteButton(Poll poll) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ElevatedButton(
        onPressed: _submitVote,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
        ),
        child: const Text('Abstimmen'),
      ),
    );
  }

  void _toggleOption(Poll poll, String optionId) {
    setState(() {
      if (poll.isMultiSelect) {
        if (_selectedOptions.contains(optionId)) {
          _selectedOptions.remove(optionId);
        } else {
          _selectedOptions.add(optionId);
        }
      } else {
        _selectedOptions.clear();
        _selectedOptions.add(optionId);
      }
    });
  }

  void _submitVote() {
    ref
        .read(pollDetailProvider(widget.bandId, widget.pollId).notifier)
        .vote(_selectedOptions.toList())
        .then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stimme erfolgreich abgegeben')),
        );
      }
    });
  }

  void _showPollMenu(BuildContext context, Poll? poll) {
    if (poll == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (poll.hasVoted && poll.status == PollStatus.active)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Stimme ändern'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedOptions.clear();
                });
              },
            ),
          if (poll.status == PollStatus.active)
            ListTile(
              leading: const Icon(Icons.stop),
              title: const Text('Umfrage beenden'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(pollDetailProvider(widget.bandId, widget.pollId)
                        .notifier)
                    .closePoll();
              },
            ),
        ],
      ),
    );
  }
}
