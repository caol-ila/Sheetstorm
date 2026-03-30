import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/broadcast_song_card.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/broadcast_status_indicator.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/connected_musicians_counter.dart';

/// Conductor view for managing a broadcast session.
class BroadcastControlScreen extends ConsumerStatefulWidget {
  const BroadcastControlScreen({super.key, required this.bandId});
  final String bandId;

  @override
  ConsumerState<BroadcastControlScreen> createState() =>
      _BroadcastControlScreenState();
}

class _BroadcastControlScreenState
    extends ConsumerState<BroadcastControlScreen> {
  @override
  void initState() {
    super.initState();
    final broadcastState = ref.read(broadcastProvider);
    if (!broadcastState.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final broadcastState = ref.watch(broadcastProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Broadcast-Session'),
        actions: [
          if (broadcastState.isConductor)
            TextButton(
              onPressed: () => _confirmEndSession(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Beenden'),
            ),
        ],
      ),
      body: _buildBody(broadcastState, theme),
    );
  }

  Widget _buildBody(BroadcastState broadcastState, ThemeData theme) {
    if (broadcastState.mode == BroadcastMode.connecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Broadcast wird gestartet…'),
          ],
        ),
      );
    }

    if (broadcastState.mode == BroadcastMode.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              broadcastState.error ?? 'Unbekannter Fehler',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () =>
                  ref.read(broadcastProvider.notifier).startSession(),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (!broadcastState.isActive) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.podcasts, size: 64, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Broadcast starten',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _showStartDialog,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Broadcast-Session starten'),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(AppSpacing.touchTargetMin),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 720;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left sidebar — connection info
              SizedBox(
                width: 280,
                child: _ConnectionPanel(broadcastState: broadcastState),
              ),
              const VerticalDivider(width: 1),
              // Main content — current song + setlist
              Expanded(
                child: _MainContent(broadcastState: broadcastState),
              ),
            ],
          );
        }

        // Single column for phone
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConnectionSummary(broadcastState: broadcastState),
              const SizedBox(height: AppSpacing.md),
              if (broadcastState.currentSong != null)
                BroadcastSongCard(
                  songTitle: broadcastState.currentSong!.stueckTitel,
                  connectedCount: broadcastState.connectedCount,
                ),
              const SizedBox(height: AppSpacing.md),
              // Placeholder for setlist items
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Wähle ein Stück aus der Setlist um es an alle '
                    'Musiker zu senden.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showStartDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast-Session starten'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wähle Setlist (optional):'),
            SizedBox(height: AppSpacing.sm),
            Text('Ohne Setlist (freie Auswahl)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Starten'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await ref.read(broadcastProvider.notifier).startSession();
    }
  }

  Future<void> _confirmEndSession(BuildContext context) async {
    final broadcastState = ref.read(broadcastProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session beenden?'),
        content: Text(
          'Die Broadcast-Session wird für alle '
          '${broadcastState.connectedCount} Musiker beendet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Beenden'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(broadcastProvider.notifier).endSession();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Broadcast-Session beendet'),
          ),
        );
        context.pop();
      }
    }
  }
}

// ─── Connection Panel (sidebar) ───────────────────────────────────────────────

class _ConnectionPanel extends StatelessWidget {
  const _ConnectionPanel({required this.broadcastState});
  final BroadcastState broadcastState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Status indicator
        BroadcastStatusIndicator(
          connectionState: broadcastState.connectionState,
        ),
        const SizedBox(height: AppSpacing.md),

        // Connected count
        ConnectedMusiciansCounter(
          count: broadcastState.connectedCount,
          size: CounterSize.large,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Musicians list
        Text(
          'Verbundene Musiker',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),

        if (broadcastState.connectedMusicians.isEmpty)
          Text(
            'Noch keine Musiker verbunden.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          )
        else
          ...broadcastState.connectedMusicians.map(
            (musician) => ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(musician.status.value),
                radius: 16,
                child: Text(
                  musician.name.isNotEmpty ? musician.name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                ),
              ),
              title: Text(musician.name),
              subtitle: Text(musician.instrument ?? ''),
              dense: true,
            ),
          ),
      ],
    );
  }

  Color _statusColor(String status) => switch (status) {
        'ready' => AppColors.success,
        'loading' => AppColors.warning,
        'error' => AppColors.error,
        _ => AppColors.textSecondary,
      };
}

// ─── Connection Summary (phone) ───────────────────────────────────────────────

class _ConnectionSummary extends StatelessWidget {
  const _ConnectionSummary({required this.broadcastState});
  final BroadcastState broadcastState;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            BroadcastStatusIndicator(
              connectionState: broadcastState.connectionState,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verbindungs-Status'),
                  Text(
                    '✓ Alle bereit (${broadcastState.connectedCount}/${broadcastState.connectedCount})',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ConnectedMusiciansCounter(
              count: broadcastState.connectedCount,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Main Content (wide) ──────────────────────────────────────────────────────

class _MainContent extends StatelessWidget {
  const _MainContent({required this.broadcastState});
  final BroadcastState broadcastState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (broadcastState.currentSong != null) ...[
          Text('Aktuelles Stück:', style: theme.textTheme.labelSmall),
          const SizedBox(height: AppSpacing.sm),
          BroadcastSongCard(
            songTitle: broadcastState.currentSong!.stueckTitel,
            connectedCount: broadcastState.connectedCount,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(
          'Setlist',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Wähle ein Stück aus der Setlist um es an alle '
              'Musiker zu senden.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
