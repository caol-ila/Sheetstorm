import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// Contextual settings sheet for the Spielmodus (Spec §4, max 5 options).
///
/// Settings:
/// 1. Half-Page-Turn toggle
/// 2. Nachtmodus tri-state
/// 3. Annotation layers multi-toggle
/// 4. Helligkeit slider
/// 5. Zoom slider (override)
class ContextSettingsSheet extends StatelessWidget {
  const ContextSettingsSheet({
    super.key,
    required this.settings,
    required this.onHalfPageTurnChanged,
    required this.onColorModeChanged,
    required this.onHelligkeitChanged,
    required this.onAnnotationLayerChanged,
    required this.onHalfPageSplitChanged,
  });

  final PerformanceModeSettings settings;
  final VoidCallback onHalfPageTurnChanged;
  final ValueChanged<ColorMode> onColorModeChanged;
  final ValueChanged<double> onHelligkeitChanged;
  final ValueChanged<AnnotationLayer> onAnnotationLayerChanged;
  final ValueChanged<double> onHalfPageSplitChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white24,
                borderRadius: AppSpacing.roundedFull,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. Half-Page-Turn toggle (AC-16)
            _buildToggleTile(
              icon: Icons.flip_to_back_outlined,
              title: 'Half-Page-Turn',
              value: settings.halfPageTurn,
              onChanged: (_) => onHalfPageTurnChanged(),
            ),

            // Half-page split ratio (AC-17)
            if (settings.halfPageTurn)
              _buildSplitSelector(),

            // 2. ColorMode (AC-30..AC-33)
            _buildColorModeTile(),

            // 3. Annotation Layers (AC-35)
            _buildAnnotationLayersTile(),

            // 4. Helligkeit (AC-34)
            _buildHelligkeitSlider(),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.darkPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }

  Widget _buildSplitSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          const SizedBox(width: 56),
          const Text(
            'Teilung:',
            style: TextStyle(color: Colors.white70, fontSize: AppTypography.fontSizeSm),
          ),
          const Spacer(),
          for (final ratio in [0.4, 0.5, 0.6])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: ChoiceChip(
                label: Text('${(ratio * 100).round()}/${((1 - ratio) * 100).round()}'),
                selected: (settings.halfPageSplit - ratio).abs() < 0.01,
                onSelected: (_) => onHalfPageSplitChanged(ratio),
                selectedColor: AppColors.darkPrimary.withOpacity(0.3),
                backgroundColor: Colors.white12,
                labelStyle: TextStyle(
                  color: (settings.halfPageSplit - ratio).abs() < 0.01
                      ? Colors.white
                      : Colors.white70,
                  fontSize: AppTypography.fontSizeXs,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorModeTile() {
    return ListTile(
      leading: Icon(settings.colorMode.icon, color: Colors.white70),
      title: const Text(
        'Anzeigemodus',
        style: TextStyle(color: Colors.white),
      ),
      trailing: SegmentedButton<ColorMode>(
        segments: ColorMode.values
            .map((m) => ButtonSegment<ColorMode>(
                  value: m,
                  label: Text(
                    m.label,
                    style: const TextStyle(fontSize: AppTypography.fontSizeXs),
                  ),
                ))
            .toList(),
        selected: {settings.colorMode},
        onSelectionChanged: (s) => onColorModeChanged(s.first),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.white
                : Colors.white70;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.darkPrimary.withOpacity(0.3)
                : Colors.transparent;
          }),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }

  Widget _buildAnnotationLayersTile() {
    return ListTile(
      leading: const Icon(Icons.layers_outlined, color: Colors.white70),
      title: const Text(
        'annotations',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Row(
        children: AnnotationLayer.values.map((layer) {
          final isActive = switch (layer) {
            AnnotationLayer.private => settings.annotationPrivate,
            AnnotationLayer.voice => settings.annotationVoice,
            AnnotationLayer.orchestra => settings.annotationOrchestra,
          };

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm, top: AppSpacing.xs),
            child: FilterChip(
              label: Text(layer.label),
              selected: isActive,
              onSelected: (_) => onAnnotationLayerChanged(layer),
              selectedColor: layer.color.withOpacity(0.3),
              checkmarkColor: layer.color,
              backgroundColor: Colors.white12,
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: AppTypography.fontSizeXs,
              ),
            ),
          );
        }).toList(),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }

  Widget _buildHelligkeitSlider() {
    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined, color: Colors.white70),
      title: const Text(
        'Helligkeit',
        style: TextStyle(color: Colors.white),
      ),
      subtitle: Slider(
        value: settings.brightness,
        min: 0.6,
        max: 1.0,
        divisions: 8,
        label: '${(settings.brightness * 100).round()}%',
        activeColor: AppColors.darkPrimary,
        onChanged: onHelligkeitChanged,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    );
  }
}
