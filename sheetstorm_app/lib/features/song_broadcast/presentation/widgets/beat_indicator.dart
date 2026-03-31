import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Visual beat indicator — a row of circles, current beat filled/accented.
/// Downbeat (index 0) is larger and uses accent color.
class BeatIndicator extends StatelessWidget {
  const BeatIndicator({
    super.key,
    required this.beatsPerMeasure,
    required this.currentBeat,
    this.isPlaying = false,
  });

  final int beatsPerMeasure;
  final int currentBeat; // -1 = none active
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(beatsPerMeasure, (index) {
        final isDownbeat = index == 0;
        final isActive = isPlaying && index == currentBeat;
        final size = isDownbeat ? 28.0 : 20.0;

        Color fillColor;
        if (isActive) {
          fillColor = isDownbeat ? AppColors.primary : AppColors.secondary;
        } else {
          fillColor = isPlaying
              ? AppColors.border
              : AppColors.textSecondary.withValues(alpha: 0.3);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.enter,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fillColor,
              border: Border.all(
                color: isDownbeat ? AppColors.primary : AppColors.textSecondary,
                width: isActive ? 0 : 1.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}
