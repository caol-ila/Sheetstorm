import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/song_broadcast/application/broadcast_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/application/metronome_notifier.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/beat_indicator.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/widgets/bpm_display.dart';

/// Metronome screen — conductor sends beats, musician receives them.
class MetronomeScreen extends ConsumerWidget {
  const MetronomeScreen({super.key, required this.bandId});

  final String bandId;

  // Common time signatures (beats / unit)
  static const _timeSignatures = [
    (2, 4),
    (3, 4),
    (4, 4),
    (5, 4),
    (6, 8),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metronome = ref.watch(metronomeProvider);
    final broadcast = ref.watch(broadcastProvider);
    final notifier = ref.read(metronomeProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metronom'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: _ModeChip(isConductor: metronome.isConductor),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mode indicator + connection count
              _StatusBar(
                isConductor: metronome.isConductor,
                connectedCount: broadcast.connectedCount,
                isPlaying: metronome.isPlaying,
              ),
              const SizedBox(height: AppSpacing.lg),

              // BPM display (tappable for tap tempo, ±1/±5 buttons)
              BpmDisplay(
                bpm: metronome.bpm,
                onTap: metronome.isConductor ? notifier.tapTempo : null,
                onBpmChanged:
                    metronome.isConductor ? notifier.setBpm : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Beat indicator
              BeatIndicator(
                beatsPerMeasure: metronome.beatsPerMeasure,
                currentBeat: metronome.currentBeat,
                isPlaying: metronome.isPlaying,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Time signature selector (conductor only)
              if (metronome.isConductor || !metronome.isPlaying) ...[
                Text(
                  'Taktart',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                _TimeSignatureSelector(
                  selected: (metronome.beatsPerMeasure, metronome.beatUnit),
                  enabled: !metronome.isPlaying,
                  onSelected: (sig) =>
                      notifier.setTimeSignature(sig.$1, sig.$2),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Start / Stop button
              _PlayButton(
                isPlaying: metronome.isPlaying,
                isConductor: metronome.isConductor,
                onStart: () {
                  if (metronome.isConductor || !metronome.isPlaying) {
                    notifier.startMetronome();
                  } else {
                    notifier.startReceiving();
                  }
                },
                onStop: () {
                  if (metronome.isConductor) {
                    notifier.stopMetronome();
                  } else {
                    notifier.stopReceiving();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Switch mode (when stopped)
              if (!metronome.isPlaying)
                TextButton(
                  onPressed: () => _toggleMode(ref, metronome),
                  child: Text(
                    metronome.isConductor
                        ? 'Als Musiker beitreten'
                        : 'Als Dirigent starten',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleMode(WidgetRef ref, MetronomeState state) {
    final notifier = ref.read(metronomeProvider.notifier);
    notifier.setTimeSignature(state.beatsPerMeasure, state.beatUnit);
    // Mode is set when startMetronome() or startReceiving() is called;
    // here we just flip the conductor flag for UI purposes.
    if (state.isConductor) {
      notifier.startReceiving();
      notifier.stopReceiving(); // immediately stop to stay idle
    } else {
      notifier.stopMetronome();
    }
  }
}

// ─── Mode chip ────────────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.isConductor});
  final bool isConductor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isConductor
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: AppSpacing.roundedFull,
        border: Border.all(
          color: isConductor ? AppColors.primary : AppColors.secondary,
        ),
      ),
      child: Text(
        isConductor ? 'Dirigent' : 'Musiker',
        style: TextStyle(
          fontSize: AppTypography.fontSizeSm,
          fontWeight: AppTypography.weightMedium,
          color: isConductor ? AppColors.primary : AppColors.secondary,
        ),
      ),
    );
  }
}

// ─── Status bar ───────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.isConductor,
    required this.connectedCount,
    required this.isPlaying,
  });

  final bool isConductor;
  final int connectedCount;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isPlaying ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: isPlaying ? AppColors.success : AppColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          isPlaying ? 'Läuft' : 'Gestoppt',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isPlaying ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        if (isConductor && connectedCount > 0) ...[
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.people_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$connectedCount verbunden',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Time signature selector ──────────────────────────────────────────────────

class _TimeSignatureSelector extends StatelessWidget {
  const _TimeSignatureSelector({
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final (int, int) selected;
  final ValueChanged<(int, int)> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      children: MetronomeScreen._timeSignatures.map((sig) {
        final isSelected = selected == sig;
        return GestureDetector(
          onTap: enabled ? () => onSelected(sig) : null,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchTargetMin,
              minHeight: AppSpacing.touchTargetMin,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              '${sig.$1}/${sig.$2}',
              style: TextStyle(
                fontSize: AppTypography.fontSizeBase,
                fontWeight: isSelected
                    ? AppTypography.weightBold
                    : AppTypography.weightNormal,
                color:
                    isSelected ? AppColors.onPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Play / Stop button ───────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.isConductor,
    required this.onStart,
    required this.onStop,
  });

  final bool isPlaying;
  final bool isConductor;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.touchTargetPlay,
      child: FilledButton.icon(
        onPressed: isPlaying ? onStop : onStart,
        icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
        label: Text(
          isPlaying
              ? 'Stopp'
              : isConductor
                  ? 'Metronom starten'
                  : 'Empfangen starten',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: isPlaying ? AppColors.error : AppColors.primary,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
    );
  }
}
