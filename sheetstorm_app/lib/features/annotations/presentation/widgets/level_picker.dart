import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';

/// Flyout dialog for selecting the annotation visibility level.
///
/// Shows 3 levels with color coding and icons (UX-Spec §4.3).
/// Orchester is locked with 🔒 if user is not Dirigent/Admin.
class LevelPicker extends StatelessWidget {
  const LevelPicker({
    super.key,
    required this.currentLevel,
    required this.isDirigent,
    this.voiceName,
  });

  final AnnotationLevel currentLevel;
  final bool isDirigent;
  final String? voiceName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  const Text(
                    'Ebene wählen',
                    style: TextStyle(
                      fontSize: AppTypography.fontSizeLg,
                      fontWeight: AppTypography.weightBold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Levels
            _LevelOption(
              level: AnnotationLevel.private,
              isActive: currentLevel == AnnotationLevel.private,
              subtitle: 'nur für mich',
              isLocked: false,
              onTap: () => Navigator.pop(context, AnnotationLevel.private),
            ),
            _LevelOption(
              level: AnnotationLevel.voice,
              isActive: currentLevel == AnnotationLevel.voice,
              subtitle: voiceName ?? 'alle mit gleicher Stimme',
              isLocked: false,
              onTap: () => Navigator.pop(context, AnnotationLevel.voice),
            ),
            _LevelOption(
              level: AnnotationLevel.orchestra,
              isActive: currentLevel == AnnotationLevel.orchestra,
              subtitle: isDirigent ? 'alle Kapellenmitglieder' : 'nur Dirigent',
              isLocked: !isDirigent,
              onTap: isDirigent
                  ? () => Navigator.pop(context, AnnotationLevel.orchestra)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.isActive,
    required this.subtitle,
    required this.isLocked,
    required this.onTap,
  });

  final AnnotationLevel level;
  final bool isActive;
  final String subtitle;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = isLocked ? Colors.grey : level.color;
    final textColor = isLocked ? Colors.grey : null;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: isActive
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      title: Row(
        children: [
          Text(
            level.iconChar,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            level.label,
            style: TextStyle(
              color: textColor,
              fontWeight: isActive
                  ? AppTypography.weightBold
                  : AppTypography.weightMedium,
            ),
          ),
          if (isLocked) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.lock, size: 16, color: Colors.grey.shade400),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor ?? Colors.grey.shade600,
          fontSize: AppTypography.fontSizeXs,
        ),
      ),
    );
  }
}
