import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tuner/application/tuner_notifier.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

/// Steuerungsleiste für den Tuner: Start/Stop, Kammerton, Transposition.
class TunerControls extends ConsumerWidget {
  const TunerControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tunerProvider);
    final notifier = ref.read(tunerProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Transpositions-Auswahl ──────────────────────────────────────────
        _TranspositionSelector(
          current: state.transposition,
          onChanged: notifier.setTransposition,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Kammerton-Picker ────────────────────────────────────────────────
        _ReferenceFrequencyPicker(
          value: state.referenceFrequency,
          onChanged: notifier.setReferenceFrequency,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Start/Stop-Button ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: AppSpacing.touchTargetPlay,
          child: ElevatedButton.icon(
            onPressed: () {
              if (state.isListening) {
                notifier.stop();
              } else {
                notifier.start();
              }
            },
            icon: Icon(state.isListening ? Icons.stop : Icons.mic),
            label: Text(state.isListening ? 'Stoppen' : 'Stimmen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isListening
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: AppColors.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Transpositions-Auswahl ───────────────────────────────────────────────────

class _TranspositionSelector extends StatelessWidget {
  const _TranspositionSelector({
    required this.current,
    required this.onChanged,
  });

  final TranspositionMode current;
  final ValueChanged<TranspositionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: TranspositionMode.values.map((mode) {
        final isSelected = mode == current;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: ChoiceChip(
            label: Text(mode.label),
            selected: isSelected,
            onSelected: (_) => onChanged(mode),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Kammerton-Picker ─────────────────────────────────────────────────────────

class _ReferenceFrequencyPicker extends StatelessWidget {
  const _ReferenceFrequencyPicker({
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'A = ${value.toStringAsFixed(1)} Hz',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Slider(
          value: value,
          min: 430.0,
          max: 450.0,
          divisions: 40, // 0.5 Hz Schritte
          label: '${value.toStringAsFixed(1)} Hz',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
