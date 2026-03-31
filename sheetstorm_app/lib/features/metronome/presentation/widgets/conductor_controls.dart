import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';
import 'package:sheetstorm/features/metronome/data/models/metronome_models.dart';
import 'package:sheetstorm/features/metronome/presentation/widgets/bpm_picker.dart';

/// Conductor view with BPM controls, time signature selector, and start/stop.
class ConductorControls extends ConsumerWidget {
  const ConductorControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(metronomeProvider);
    final notifier = ref.read(metronomeProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Connection badge
          _ConnectionBadge(state: state),
          const SizedBox(height: 24),

          // BPM Picker
          const BpmPicker(),
          const SizedBox(height: 24),

          // Time signature selector
          _TimeSignatureSelector(
            selected: state.timeSignature,
            onChanged: notifier.setTimeSignature,
          ),
          const SizedBox(height: 16),

          // Audio click toggle
          SwitchListTile(
            title: const Text('Audio-Click'),
            secondary: const Icon(Icons.volume_up),
            value: state.audioClickEnabled,
            onChanged: (_) => notifier.toggleAudioClick(),
          ),
          const SizedBox(height: 16),

          // Mini beat indicator (when playing)
          if (state.isPlaying) ...[
            _MiniBeatIndicator(state: state),
            const SizedBox(height: 16),
          ],

          // Start / Stop button
          SizedBox(
            height: 72,
            child: FilledButton.icon(
              onPressed: () => _toggleMetronome(state, notifier),
              icon: Icon(state.isPlaying ? Icons.stop : Icons.play_arrow),
              label: Text(state.isPlaying ? 'Stop' : 'Start'),
              style: FilledButton.styleFrom(
                backgroundColor: state.isPlaying
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: state.isPlaying
                    ? Theme.of(context).colorScheme.onError
                    : Theme.of(context).colorScheme.onPrimary,
                textStyle: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleMetronome(MetronomeState state, MetronomeNotifier notifier) {
    if (state.isPlaying) {
      notifier.stop();
    } else {
      notifier.startAsConductor(
        bpm: state.bpm,
        timeSignature: state.timeSignature,
      );
    }
  }
}

/// Connection status badge.
class _ConnectionBadge extends StatelessWidget {
  final MetronomeState state;

  const _ConnectionBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, text, icon) = switch (state.connectionState) {
      MetronomeConnectionState.connected => (
          Theme.of(context).colorScheme.primary,
          '${state.connectedClients} verbunden',
          Icons.circle,
        ),
      MetronomeConnectionState.connecting => (
          Theme.of(context).colorScheme.secondary,
          'Verbindet...',
          Icons.sync,
        ),
      MetronomeConnectionState.reconnecting => (
          Theme.of(context).colorScheme.error,
          'Reconnecting...',
          Icons.sync_problem,
        ),
      MetronomeConnectionState.disconnected => (
          Theme.of(context).colorScheme.outline,
          'Offline',
          Icons.circle_outlined,
        ),
    };

    return Semantics(
      label: '${state.connectedClients} Musiker verbunden',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// Time signature chip selector.
class _TimeSignatureSelector extends StatelessWidget {
  final TimeSignature selected;
  final ValueChanged<TimeSignature> onChanged;

  const _TimeSignatureSelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final ts in TimeSignature.standardOptions)
          ChoiceChip(
            label: Text(ts.display),
            selected: ts == selected,
            onSelected: (_) => onChanged(ts),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
      ],
    );
  }
}

/// Mini beat indicator for conductor view (row of dots).
class _MiniBeatIndicator extends StatelessWidget {
  final MetronomeState state;

  const _MiniBeatIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(state.timeSignature.beatsPerMeasure, (index) {
        final isActive = state.currentBeat?.beatInMeasure == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: isActive ? 16 : 10,
            height: isActive ? 16 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : null,
              border: isActive
                  ? null
                  : Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1.5,
                    ),
            ),
          ),
        );
      }),
    );
  }
}
