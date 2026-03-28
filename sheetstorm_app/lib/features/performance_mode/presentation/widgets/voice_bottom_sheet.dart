import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// Stimme (voice/instrument) selection bottom sheet (AC-37..AC-42, UX §8).
///
/// Shows user's instruments first with visual highlight,
/// then all other available voices alphabetically sorted.
class VoiceBottomSheet extends StatelessWidget {
  const VoiceBottomSheet({
    super.key,
    required this.voices,
    required this.currentVoiceId,
    required this.onStimmeSelected,
  });

  final List<Voice> voices;
  final String? currentVoiceId;
  final ValueChanged<String> onStimmeSelected;

  @override
  Widget build(BuildContext context) {
    final userStimmen =
        voices.where((s) => s.isUserInstrument).toList();
    final otherStimmen =
        voices.where((s) => !s.isUserInstrument).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Stimme wechseln',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeLg,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTargetMin,
                    minHeight: AppSpacing.touchTargetMin,
                  ),
                ),
              ],
            ),
          ),

          // "Meine Instrumente" section (AC-38)
          if (userStimmen.isNotEmpty) ...[
            _buildSectionHeader('MEINE INSTRUMENTE'),
            ...userStimmen.map((s) => _buildStimmeItem(context, s)),
          ],

          // "Andere Stimmen" section (AC-39)
          if (otherStimmen.isNotEmpty) ...[
            _buildSectionHeader('ANDERE STIMMEN'),
            ...otherStimmen.map((s) => _buildStimmeItem(context, s)),
          ],

          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: AppTypography.fontSizeXs,
          fontWeight: AppTypography.weightMedium,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStimmeItem(BuildContext context, Stimme stimme) {
    final isSelected = stimme.id == currentVoiceId;

    return ListTile(
      leading: isSelected
          ? Icon(Icons.check_circle, color: AppColors.darkPrimary)
          : stimme.isFallback
              ? const Icon(Icons.arrow_forward, color: Colors.amber)
              : const SizedBox(width: 24),
      title: Text(
        stimme.name,
        style: TextStyle(
          color: stimme.isFallback && !isSelected
              ? Colors.white38
              : Colors.white,
          fontWeight: isSelected ? AppTypography.weightMedium : null,
        ),
      ),
      subtitle: stimme.fallbackReason != null
          ? Text(
              stimme.fallbackReason!,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: AppTypography.fontSizeXs,
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.darkPrimary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      minVerticalPadding: AppSpacing.sm,
      onTap: () {
        onStimmeSelected(stimme.id);
        Navigator.of(context).pop();
      },
    );
  }
}
