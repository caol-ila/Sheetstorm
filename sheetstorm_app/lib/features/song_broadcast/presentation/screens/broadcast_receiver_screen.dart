import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/data/models/broadcast_models.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/broadcast_status_indicator.dart';

/// Musician view for receiving broadcast song changes.
class BroadcastReceiverScreen extends ConsumerStatefulWidget {
  const BroadcastReceiverScreen({super.key, required this.bandId});
  final String bandId;

  @override
  ConsumerState<BroadcastReceiverScreen> createState() =>
      _BroadcastReceiverScreenState();
}

class _BroadcastReceiverScreenState
    extends ConsumerState<BroadcastReceiverScreen> {
  @override
  Widget build(BuildContext context) {
    final broadcastState = ref.watch(broadcastProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast'),
        actions: [
          if (broadcastState.isActive)
            BroadcastStatusIndicator(
              connectionState: broadcastState.connectionState,
              compact: true,
            ),
        ],
      ),
      body: _buildBody(broadcastState, theme),
    );
  }

  Widget _buildBody(BroadcastState broadcastState, ThemeData theme) {
    // Idle — check for active session
    if (broadcastState.mode == BroadcastMode.idle) {
      return _IdleView(bandId: widget.bandId);
    }

    // Connecting
    if (broadcastState.mode == BroadcastMode.connecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text('Verbinde mit Broadcast…'),
          ],
        ),
      );
    }

    // Error
    if (broadcastState.mode == BroadcastMode.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                broadcastState.error ??
                    'Broadcast-Verbindung getrennt',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Die Verbindung zur Broadcast-Session wurde getrennt.\n'
                'Möchtest du erneut beitreten?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => ref
                        .read(broadcastProvider.notifier)
                        .endSession(),
                    child: const Text('Später'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FilledButton(
                    onPressed: () => ref
                        .read(broadcastProvider.notifier)
                        .joinSession(),
                    child: const Text('Erneut beitreten'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Receiving — active session
    return _ReceivingView(broadcastState: broadcastState);
  }
}

// ─── Idle View ────────────────────────────────────────────────────────────────

class _IdleView extends ConsumerStatefulWidget {
  const _IdleView({required this.bandId});
  final String bandId;

  @override
  ConsumerState<_IdleView> createState() => _IdleViewState();
}

class _IdleViewState extends ConsumerState<_IdleView> {
  BroadcastSession? _activeSession;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkForSession();
  }

  Future<void> _checkForSession() async {
    try {
      final session = await ref
          .read(broadcastProvider.notifier)
          .checkForActiveSession();
      if (mounted) {
        setState(() {
          _activeSession = session;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeSession == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.podcasts,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Kein aktiver Broadcast',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Wenn der Dirigent einen Broadcast startet, '
                'erscheint hier eine Benachrichtigung.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _checkForSession,
                icon: const Icon(Icons.refresh),
                label: const Text('Aktualisieren'),
              ),
            ],
          ),
        ),
      );
    }

    // Active session found — show join banner
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.podcasts,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '📡 Broadcast aktiv',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_activeSession!.dirigentName != null)
                  Text(
                    'Dirigent: ${_activeSession!.dirigentName}',
                    style: theme.textTheme.bodyLarge,
                  ),
                Text(
                  '${_activeSession!.verbundeneMusiker} Musiker verbunden',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).maybePop(),
                      child: const Text('Später'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(broadcastProvider.notifier)
                          .joinSession(),
                      icon: const Icon(Icons.login),
                      label: const Text('Beitreten'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Receiving View ───────────────────────────────────────────────────────────

class _ReceivingView extends ConsumerWidget {
  const _ReceivingView({required this.broadcastState});
  final BroadcastState broadcastState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentSong = broadcastState.currentSong;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BroadcastStatusIndicator(
                        connectionState:
                            broadcastState.connectionState,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Broadcast-Session'),
                            Text(
                              'Status: Verbunden ✓',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              'Musiker: ${broadcastState.connectedCount} verbunden',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _confirmLeave(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Session verlassen'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Current song
          if (currentSong != null) ...[
            Card(
              color: AppColors.primary.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const Text('🎵 Neues Stück empfangen'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      currentSong.stueckTitel,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: Navigate to performance mode for this piece
                      },
                      icon: const Icon(Icons.music_note),
                      label: const Text('Noten-Ansicht'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                            AppSpacing.touchTargetMin),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.headphones,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Warte auf Stück vom Dirigenten…',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session verlassen?'),
        content: const Text(
          'Du erhältst keine weiteren Stück-Updates vom Dirigenten.',
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
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(broadcastProvider.notifier)
          .leaveSession();
    }
  }
}
