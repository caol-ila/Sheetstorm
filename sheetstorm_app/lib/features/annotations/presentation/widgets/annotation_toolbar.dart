import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/application/annotation_toolbar_notifier.dart';
import 'package:sheetstorm/features/annotations/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/level_picker.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/stamp_picker.dart';

/// Annotation toolbar — minimal, dockable, auto-hide in play mode.
///
/// Phone: horizontal bottom bar.
/// Tablet: vertical side bar (left default, draggable).
///
/// Layout: [Ebene ▼] | ✏️ | 📝 | 🖊 | 🎵 | 🧹 | ↕️ | ↩ | ↪ | [Fertig]
class AnnotationToolbar extends ConsumerWidget {
  const AnnotationToolbar({
    super.key,
    required this.pieceId,
    this.isDirigent = false,
    this.voiceName,
    this.onDone,
  });

  final String pieceId;
  final bool isDirigent;
  final String? voiceName;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolbarState = ref.watch(annotationToolbarProvider);
    final annotationState = ref.watch(annotationProvider(pieceId));
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // Use vertical toolbar on tablet in landscape
    final useVertical = isTablet && isLandscape;

    return Stack(
      children: [
        // Main toolbar
        Positioned(
          left: useVertical ? 0 : 0,
          right: useVertical ? null : 0,
          bottom: useVertical ? 0 : 0,
          top: useVertical ? 0 : null,
          child: AnimatedSlide(
            offset: toolbarState.isToolbarVisible
                ? Offset.zero
                : useVertical
                    ? const Offset(-1, 0)
                    : const Offset(0, 1),
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            child: _buildToolbar(
              context,
              ref,
              toolbarState,
              annotationState,
              useVertical,
            ),
          ),
        ),

        // Done button (top right)
        Positioned(
          top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
          right: AppSpacing.sm,
          child: _DoneButton(onDone: onDone),
        ),

        // Level badge (top left)
        Positioned(
          top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
          left: AppSpacing.sm,
          child: _LevelBadge(level: toolbarState.activeLevel),
        ),

        // Stamp picker overlay
        if (toolbarState.isStampPickerOpen)
          Positioned(
            left: useVertical ? 56 : 0,
            right: useVertical ? null : 0,
            bottom: useVertical ? null : 56,
            top: useVertical ? 0 : null,
            child: StampPicker(
              onStampSelected: (category, value) {
                ref
                    .read(annotationToolbarProvider.notifier)
                    .selectStamp(category, value);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    AnnotationToolbarState toolbarState,
    AnnotationState annotationState,
    bool useVertical,
  ) {
    final accentColor = toolbarState.activeLevel.color;
    final children = <Widget>[
      // Level picker button
      _ToolbarButton(
        icon: Icons.layers,
        label: toolbarState.activeLevel.label,
        color: accentColor,
        isActive: false,
        filled: true,
        onTap: () => _showLevelPicker(context, ref),
      ),
      _toolbarDivider(useVertical),
      // Tools
      _ToolbarButton(
        icon: Icons.edit,
        label: 'Stift',
        color: accentColor,
        isActive: toolbarState.activeTool == AnnotationTool.pencil,
        onTap: () => ref
            .read(annotationToolbarProvider.notifier)
            .selectTool(AnnotationTool.pencil),
      ),
      _ToolbarButton(
        icon: Icons.short_text,
        label: 'Text',
        color: accentColor,
        isActive: toolbarState.activeTool == AnnotationTool.text,
        onTap: () => ref
            .read(annotationToolbarProvider.notifier)
            .selectTool(AnnotationTool.text),
      ),
      _ToolbarButton(
        icon: Icons.highlight,
        label: 'Marker',
        color: accentColor,
        isActive: toolbarState.activeTool == AnnotationTool.highlighter,
        onTap: () => ref
            .read(annotationToolbarProvider.notifier)
            .selectTool(AnnotationTool.highlighter),
      ),
      _ToolbarButton(
        icon: Icons.music_note,
        label: 'Stempel',
        color: accentColor,
        isActive: toolbarState.activeTool == AnnotationTool.stamp,
        onTap: () => ref
            .read(annotationToolbarProvider.notifier)
            .selectTool(AnnotationTool.stamp),
      ),
      _ToolbarButton(
        icon: Icons.auto_fix_high,
        label: 'Radierer',
        color: accentColor,
        isActive: toolbarState.activeTool == AnnotationTool.eraser,
        onTap: () => ref
            .read(annotationToolbarProvider.notifier)
            .selectTool(AnnotationTool.eraser),
      ),
      _toolbarDivider(useVertical),
      // Undo / Redo
      _ToolbarButton(
        icon: Icons.undo,
        label: 'Undo',
        color: accentColor,
        isActive: false,
        enabled: annotationState.canUndo,
        onTap: () =>
            ref.read(annotationProvider(pieceId).notifier).undo(),
      ),
      _ToolbarButton(
        icon: Icons.redo,
        label: 'Redo',
        color: accentColor,
        isActive: false,
        enabled: annotationState.canRedo,
        onTap: () =>
            ref.read(annotationProvider(pieceId).notifier).redo(),
      ),
    ];

    final container = Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: useVertical
            ? const BorderRadius.horizontal(right: Radius.circular(12))
            : const BorderRadius.vertical(top: Radius.circular(12)),
        boxShadow: AppShadows.lg,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: useVertical ? AppSpacing.xs : AppSpacing.sm,
        vertical: useVertical ? AppSpacing.sm : AppSpacing.xs,
      ),
      child: SafeArea(
        top: !useVertical,
        left: useVertical,
        right: false,
        bottom: !useVertical,
        child: useVertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: children,
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
      ),
    );

    return container;
  }

  Widget _toolbarDivider(bool vertical) {
    return Container(
      width: vertical ? 32 : 1,
      height: vertical ? 1 : 32,
      margin: EdgeInsets.symmetric(
        horizontal: vertical ? 0 : 4,
        vertical: vertical ? 4 : 0,
      ),
      color: Colors.white24,
    );
  }

  void _showLevelPicker(BuildContext context, WidgetRef ref) {
    showDialog<AnnotationLevel>(
      context: context,
      builder: (_) => LevelPicker(
        currentLevel: ref.read(annotationToolbarProvider).activeLevel,
        isDirigent: isDirigent,
        voiceName: voiceName,
      ),
    ).then((level) {
      if (level != null) {
        ref.read(annotationToolbarProvider.notifier).selectLevel(level);
      }
    });
  }
}

// ─── Toolbar Button ───────────────────────────────────────────────────────────

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isActive,
    required this.onTap,
    this.enabled = true,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool isActive;
  final bool enabled;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        enabled ? (isActive ? color : Colors.white70) : Colors.white24;

    return Tooltip(
      message: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppSpacing.roundedMd,
          child: Container(
            width: AppSpacing.touchTargetMin,
            height: AppSpacing.touchTargetMin,
            decoration: BoxDecoration(
              color: isActive
                  ? color.withOpacity(0.2)
                  : filled
                      ? color.withOpacity(0.15)
                      : null,
              borderRadius: AppSpacing.roundedMd,
              border: isActive
                  ? Border(
                      bottom: BorderSide(color: color, width: 2.5),
                    )
                  : null,
            ),
            child: Icon(icon, color: effectiveColor, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─── Done Button ──────────────────────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({this.onDone});
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onDone,
      icon: const Icon(Icons.check, size: 18),
      label: const Text('Fertig'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

// ─── Level Badge ──────────────────────────────────────────────────────────────

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final AnnotationLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.9),
        borderRadius: AppSpacing.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.iconChar,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            level.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightBold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
