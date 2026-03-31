import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/application/setlist_player_notifier.dart';

class SetlistPlayerScreen extends ConsumerStatefulWidget {
  const SetlistPlayerScreen({super.key, required this.setlistId});
  final String setlistId;

  @override
  ConsumerState<SetlistPlayerScreen> createState() =>
      _SetlistPlayerScreenState();
}

class _SetlistPlayerScreenState extends ConsumerState<SetlistPlayerScreen> {
  bool _overlayVisible = true;

  @override
  void initState() {
    super.initState();
    // Start playing once the widget is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(setlistPlayerProvider(widget.setlistId).notifier)
          .startPlaying();
    });
    // Auto-hide overlay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final playerState =
        ref.watch(setlistPlayerProvider(widget.setlistId));
    final theme = Theme.of(context);

    // Immersive mode for player
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        ref
            .read(setlistPlayerProvider(widget.setlistId).notifier)
            .stop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () => setState(() => _overlayVisible = !_overlayVisible),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main content area
              _buildMainContent(playerState, theme),

              // Top overlay
              if (_overlayVisible)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopOverlay(
                    playerState: playerState,
                    onBack: () {
                      SystemChrome.setEnabledSystemUIMode(
                          SystemUiMode.edgeToEdge);
                      ref
                          .read(setlistPlayerProvider(
                                  widget.setlistId)
                              .notifier)
                          .stop();
                      context.go('/app/setlists/${widget.setlistId}');
                    },
                    onNavigate: () => _showNavigationSheet(
                        context, playerState),
                  ),
                ),

              // Bottom overlay
              if (_overlayVisible &&
                  playerState.status == PlayerStatus.playing)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomOverlay(
                    playerState: playerState,
                    setlistId: widget.setlistId,
                  ),
                ),

              // End overlay
              if (playerState.status == PlayerStatus.finished)
                _EndOverlay(
                  setlistId: widget.setlistId,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
      SetlistPlayerState playerState, ThemeData theme) {
    if (playerState.status == PlayerStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (playerState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              playerState.error!,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    final current = playerState.currentStueck;
    if (current == null) {
      return const Center(
        child: Text(
          'Keine spielbaren Stücke',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Sheet music display (placeholder — real implementation uses pdfrx)
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            current.titel,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          if (current.stimme != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              current.stimme!.name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (current.seiten.isNotEmpty)
            Expanded(
              child: PageView.builder(
                itemCount: current.seiten.length,
                itemBuilder: (context, pageIndex) {
                  return Container(
                    margin: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppSpacing.roundedMd,
                    ),
                    child: Center(
                      child: Text(
                        'Seite ${pageIndex + 1}',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Icon(
                  Icons.music_note,
                  size: 120,
                  color: Colors.white24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNavigationSheet(
      BuildContext context, SetlistPlayerState playerState) {
    final items = playerState.playableItems;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Setlist-Navigation',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isCurrent =
                      index == playerState.currentIndex;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? AppColors.primary
                          : AppColors.surface,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent
                              ? AppColors.onPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      item.titel,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: item.stimme != null
                        ? Text(item.stimme!.name)
                        : null,
                    selected: isCurrent,
                    onTap: () {
                      ref
                          .read(setlistPlayerProvider(
                                  widget.setlistId)
                              .notifier)
                          .jumpTo(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Overlay ──────────────────────────────────────────────────────────────

class _TopOverlay extends StatelessWidget {
  const _TopOverlay({
    required this.playerState,
    required this.onBack,
    required this.onNavigate,
  });

  final SetlistPlayerState playerState;
  final VoidCallback onBack;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Zurück',
                onPressed: onBack,
              ),
              const Spacer(),
              if (playerState.totalPlayable > 0)
                GestureDetector(
                  onTap: onNavigate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      playerState.progressLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Overlay ───────────────────────────────────────────────────────────

class _BottomOverlay extends ConsumerWidget {
  const _BottomOverlay({
    required this.playerState,
    required this.setlistId,
  });

  final SetlistPlayerState playerState;
  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier =
        ref.read(setlistPlayerProvider(setlistId).notifier);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous
              IconButton(
                icon: const Icon(Icons.skip_previous,
                    color: Colors.white, size: 36),
                tooltip: 'Vorheriges Stück',
                onPressed:
                    playerState.isFirst ? null : notifier.previous,
              ),
              // Play/Pause
              IconButton(
                icon: Icon(
                  playerState.status == PlayerStatus.paused
                      ? Icons.play_circle_filled
                      : Icons.pause_circle_filled,
                  color: Colors.white,
                  size: AppSpacing.touchTargetPlay,
                ),
                tooltip: playerState.status == PlayerStatus.paused
                    ? 'Wiedergabe starten'
                    : 'Wiedergabe pausieren',
                onPressed: notifier.togglePause,
              ),
              // Next
              IconButton(
                icon: const Icon(Icons.skip_next,
                    color: Colors.white, size: 36),
                tooltip: 'Nächstes Stück',
                onPressed: playerState.isLast ? null : notifier.next,
              ),
              // Auto-advance toggle
              IconButton(
                icon: Icon(
                  Icons.fast_forward,
                  color: playerState.autoAdvance
                      ? AppColors.primary
                      : Colors.white54,
                  size: 28,
                ),
                tooltip: 'Auto-Weiter',
                onPressed: notifier.toggleAutoAdvance,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── End Overlay ──────────────────────────────────────────────────────────────

class _EndOverlay extends ConsumerWidget {
  const _EndOverlay({required this.setlistId});
  final String setlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 80,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Ende der Setlist',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () {
                SystemChrome.setEnabledSystemUIMode(
                    SystemUiMode.edgeToEdge);
                ref
                    .read(setlistPlayerProvider(setlistId)
                        .notifier)
                    .stop();
                context.go('/app/setlists/$setlistId');
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Zurück zur Setlist'),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => ref
                  .read(
                      setlistPlayerProvider(setlistId).notifier)
                  .restart(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              icon: const Icon(Icons.replay),
              label: const Text('Nochmal abspielen'),
            ),
          ],
        ),
      ),
    );
  }
}
