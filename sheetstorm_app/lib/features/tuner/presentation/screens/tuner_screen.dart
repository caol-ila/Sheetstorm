import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tuner/application/tuner_notifier.dart';
import 'package:sheetstorm/features/tuner/presentation/widgets/note_display.dart';
import 'package:sheetstorm/features/tuner/presentation/widgets/tuner_controls.dart';
import 'package:sheetstorm/features/tuner/presentation/widgets/tuner_gauge.dart';

/// Haupt-Tuner-Ansicht.
///
/// Startet das Mikrofon automatisch beim Öffnen und stoppt es beim Verlassen.
class TunerScreen extends ConsumerStatefulWidget {
  const TunerScreen({super.key});

  @override
  ConsumerState<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends ConsumerState<TunerScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tunerProvider.notifier).start();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(tunerProvider.notifier).stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(tunerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      notifier.stop();
    } else if (state == AppLifecycleState.resumed) {
      notifier.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tunerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stimmgerät'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Center(
              child: Text(
                'A = ${state.referenceFrequency.toStringAsFixed(1)} Hz',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // ── Cent-Abweichungsanzeige ──────────────────────────────────
              Expanded(
                flex: 3,
                child: TunerGauge(centDeviation: state.centDeviation),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Ton-Anzeige ──────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: NoteDisplay(note: state.note),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Steuerung ────────────────────────────────────────────────
              const TunerControls(),
              const SizedBox(height: AppSpacing.md),

              // ── Fehlermeldung ────────────────────────────────────────────
              if (state.errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: AppSpacing.roundedMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
