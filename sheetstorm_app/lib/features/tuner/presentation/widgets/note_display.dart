import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/tuner/data/models/tuner_models.dart';

/// Zeigt den erkannten Tonnamen groß an (mindestens 72sp, aus 1m lesbar).
///
/// Zeigt "—" wenn kein Ton erkannt.
class NoteDisplay extends StatelessWidget {
  const NoteDisplay({super.key, required this.note});

  final TunerNote? note;

  @override
  Widget build(BuildContext context) {
    final hasNote = note != null;

    return Semantics(
      label: hasNote
          ? 'Erkannter Ton: ${note!.displayName}, '
              '${note!.frequency.toStringAsFixed(1)} Hz'
          : 'Kein Ton erkannt',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasNote ? note!.name : '—',
            style: TextStyle(
              fontSize: AppTypography.fontSize3xl, // 72sp
              fontWeight: AppTypography.weightBold,
              color: hasNote
                  ? Theme.of(context).colorScheme.onSurface
                  : AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (hasNote) ...[
            Text(
              '${note!.octave}',
              style: const TextStyle(
                fontSize: AppTypography.fontSizeXl,
                fontWeight: AppTypography.weightMedium,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${note!.frequency.toStringAsFixed(1)} Hz',
              style: const TextStyle(
                fontSize: AppTypography.fontSizeLg,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
