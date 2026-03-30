import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/beat_indicator.dart';

/// Musician view: passive beat receiver with visual indicator.
class MusicianView extends ConsumerWidget {
  const MusicianView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);

    if (!state.isPlaying) {
      return _WaitingState(state: state);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header: connection + BPM info
          _MusicianHeader(state: state),
          const SizedBox(height: 16),

          // Beat indicator (large, centered)
          const Expanded(
            child: Center(
              child: BeatIndicator(),
            ),
          ),
          const SizedBox(height: 16),

          // Audio click toggle
          SwitchListTile(
            title: const Text('Audio-Click (lokal)'),
            secondary: const Icon(Icons.volume_up),
            value: state.audioClickEnabled,
            onChanged: (_) =>
                ref.read(metronomeProvider.notifier).toggleAudioClick(),
          ),

          // Latency compensation
          _LatencyCompensationRow(
            value: state.latencyCompensationMs,
            onChanged: (v) =>
                ref.read(metronomeProvider.notifier).setLatencyCompensation(v),
          ),
        ],
      ),
    );
  }
}

/// Header for musician view showing connection and session info.
class _MusicianHeader extends StatelessWidget {
  final MetronomeState state;

  const _MusicianHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final transportLabel = switch (state.transport) {
      MetronomeTransport.udp => 'UDP',
      MetronomeTransport.websocket => 'WS',
      MetronomeTransport.none => '—',
    };

    return Row(
      children: [
        Icon(
          state.connectionState == MetronomeConnectionState.connected
              ? Icons.wifi
              : Icons.wifi_off,
          size: 16,
          color: state.connectionState == MetronomeConnectionState.connected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        const SizedBox(width: 4),
        Text(
          transportLabel,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        Text(
          '${state.bpm} BPM · ${state.timeSignature.display}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

/// Waiting state when no metronome is active.
class _WaitingState extends StatelessWidget {
  final MetronomeState state;

  const _WaitingState({required this.state});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Kein Metronom aktiv',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Der Dirigent hat noch kein Metronom gestartet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 8),
          Text(
            'Warte auf Dirigent...',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Latency compensation slider row.
class _LatencyCompensationRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _LatencyCompensationRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Latenz: ${value >= 0 ? '+' : ''}${value}ms',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.settings, size: 20),
          onPressed: () => _showSlider(context),
          tooltip: 'Latenz-Kompensation einstellen',
        ),
      ],
    );
  }

  void _showSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latenz-Kompensation',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (ctx, setSliderState) => Column(
                children: [
                  Slider(
                    value: value.toDouble(),
                    min: -100,
                    max: 100,
                    divisions: 40,
                    label: '${value}ms',
                    onChanged: (v) {
                      final rounded = (v / 5).round() * 5;
                      onChanged(rounded);
                      setSliderState(() {});
                    },
                  ),
                  Text(
                    'Aktuell: ${value >= 0 ? '+' : ''}${value} ms',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erhöhe den Wert, wenn du den Beat zu früh siehst.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
