import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';

/// Non-destructive layer toggle panel for the Spielmodus overlay.
///
/// Allows toggling visibility of each annotation level independently.
/// UX-Spec §5.2: Toggle-Position im Spielmodus-Overlay.
class LayerTogglePanel extends ConsumerWidget {
  const LayerTogglePanel({
    super.key,
    required this.pieceId,
  });

  final String pieceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(annotationProvider(pieceId));
    final visibility = state.layerVisibility;

    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9),
        borderRadius: AppSpacing.roundedLg,
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xs,
              0,
            ),
            child: Row(
              children: [
                const Text(
                  'Ebenen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.fontSizeBase,
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Toggles
          _LayerToggle(
            level: AnnotationLevel.private,
            isVisible: visibility.isPrivate,
            onToggle: () => ref
                .read(annotationProvider(pieceId).notifier)
                .toggleLayerVisibility(AnnotationLevel.private),
          ),
          _LayerToggle(
            level: AnnotationLevel.voice,
            isVisible: visibility.isVoice,
            onToggle: () => ref
                .read(annotationProvider(pieceId).notifier)
                .toggleLayerVisibility(AnnotationLevel.voice),
          ),
          _LayerToggle(
            level: AnnotationLevel.orchestra,
            isVisible: visibility.isOrchestra,
            onToggle: () => ref
                .read(annotationProvider(pieceId).notifier)
                .toggleLayerVisibility(AnnotationLevel.orchestra),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  const _LayerToggle({
    required this.level,
    required this.isVisible,
    required this.onToggle,
  });

  final AnnotationLevel level;
  final bool isVisible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onToggle,
      leading: Icon(
        isVisible ? Icons.visibility : Icons.visibility_off,
        color: isVisible ? level.color : Colors.white30,
        size: 20,
      ),
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isVisible ? level.color : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            level.iconChar,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            level.label,
            style: TextStyle(
              color: isVisible ? Colors.white : Colors.white38,
              fontSize: AppTypography.fontSizeSm,
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ],
      ),
    );
  }
}
