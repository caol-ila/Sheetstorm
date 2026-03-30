import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';

/// Visual bar showing total setlist duration with per-entry breakdown.
class TimingBar extends StatelessWidget {
  const TimingBar({super.key, required this.entries});

  final List<SetlistEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalSeconds = entries.fold<int>(
      0,
      (sum, e) => sum + (e.geschaetzteDauerSekunden ?? 0),
    );

    if (totalSeconds <= 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          'Dauer eingeben für Timing',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final formattedTotal = hours > 0 ? '${hours}h ${mins}min' : '${mins}min';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Total duration label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Gesamtdauer',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              formattedTotal,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Segmented bar
        ClipRRect(
          borderRadius: AppSpacing.roundedSm,
          child: SizedBox(
            height: 12,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return Row(
                  children: entries.map((entry) {
                    final duration =
                        entry.geschaetzteDauerSekunden ?? 0;
                    if (duration <= 0) return const SizedBox.shrink();

                    final fraction = duration / totalSeconds;
                    final width = maxWidth * fraction;

                    return Container(
                      width: width.clamp(2.0, maxWidth),
                      decoration: BoxDecoration(
                        color: _colorForEntry(entry),
                        border: const Border(
                          right: BorderSide(
                            color: Colors.white,
                            width: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Legend
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendItem(
              color: AppColors.primary,
              label: 'Stücke',
            ),
            _LegendItem(
              color: AppColors.warning,
              label: 'Platzhalter',
            ),
            _LegendItem(
              color: AppColors.textSecondary,
              label: 'Pausen',
            ),
          ],
        ),

        // If we have calculated start/end times, show them
        if (entries.isNotEmpty &&
            entries.first.startzeitBerechnet != null &&
            entries.last.endzeitBerechnet != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${entries.first.startzeitBerechnet} – ${entries.last.endzeitBerechnet}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Color _colorForEntry(SetlistEntry entry) => switch (entry.typ) {
        SetlistEntryType.stueck => AppColors.primary,
        SetlistEntryType.platzhalter => AppColors.warning,
        SetlistEntryType.pause => AppColors.textSecondary,
      };
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppSpacing.roundedSm,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
