import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/communication/application/post_notifier.dart';
import 'package:sheetstorm/features/communication/application/poll_notifier.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/post_card.dart';
import 'package:sheetstorm/features/communication/presentation/widgets/poll_card.dart';

class BoardScreen extends ConsumerStatefulWidget {
  const BoardScreen({super.key});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final activeBandId = ref.watch(activeBandProvider);

    if (activeBandId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Board')),
        body: const Center(
          child: Text('Bitte wähle zunächst eine Kapelle aus'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _refresh(activeBandId),
              child: _buildContent(activeBandId),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(_selectedTab == 0 ? 'Neuer Post' : 'Neue Umfrage'),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _buildTabChip('Alle', 0),
          const SizedBox(width: AppSpacing.sm),
          _buildTabChip('Pinned', 1),
          const SizedBox(width: AppSpacing.sm),
          _buildTabChip('Umfragen', 2),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _selectedTab == index;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTab = index;
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildContent(String bandId) {
    if (_selectedTab == 2) {
      return _buildPollList(bandId);
    }

    final pinnedOnly = _selectedTab == 1;
    return _buildPostList(bandId, pinnedOnly: pinnedOnly);
  }

  Widget _buildPostList(String bandId, {bool? pinnedOnly}) {
    final postsAsync =
        ref.watch(postListProvider(bandId, pinnedOnly: pinnedOnly));

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text('Fehler beim Laden: $error'),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => _refresh(bandId),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  pinnedOnly == true ? Icons.push_pin : Icons.article,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  pinnedOnly == true
                      ? 'Keine gepinnten Posts'
                      : 'Noch keine Posts',
                  style: const TextStyle(
                    fontSize: AppTypography.fontSizeLg,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: posts.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(post: post, bandId: bandId);
          },
        );
      },
    );
  }

  Widget _buildPollList(String bandId) {
    final pollsAsync = ref.watch(pollListProvider(bandId));

    return pollsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Fehler beim Laden: $error'),
      ),
      data: (polls) {
        if (polls.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.poll,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Noch keine Umfragen',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeLg,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        final activePolls = polls.where((p) => p.status.name == 'active').toList();
        final endedPolls = polls.where((p) => p.status.name == 'ended').toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (activePolls.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'AKTIVE UMFRAGEN',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeSm,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...activePolls.map((poll) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PollCard(poll: poll, bandId: bandId),
                  )),
            ],
            if (endedPolls.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(
                  top: AppSpacing.lg,
                  bottom: AppSpacing.sm,
                ),
                child: Text(
                  'BEENDETE UMFRAGEN',
                  style: TextStyle(
                    fontSize: AppTypography.fontSizeSm,
                    fontWeight: AppTypography.weightBold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ...endedPolls.map((poll) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PollCard(poll: poll, bandId: bandId),
                  )),
            ],
          ],
        );
      },
    );
  }

  Future<void> _refresh(String bandId) async {
    if (_selectedTab == 2) {
      ref.invalidate(pollListProvider(bandId));
    } else {
      final pinnedOnly = _selectedTab == 1;
      ref.invalidate(postListProvider(bandId, pinnedOnly: pinnedOnly));
    }
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.article),
              title: const Text('Neuer Post'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create post screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.poll),
              title: const Text('Neue Umfrage'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to create poll screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
