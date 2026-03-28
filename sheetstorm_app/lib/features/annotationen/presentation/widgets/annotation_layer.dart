import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotationen/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotationen/application/annotation_toolbar_notifier.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';
import 'package:sheetstorm/features/annotationen/presentation/painters/annotation_painter.dart';
import 'package:sheetstorm/features/annotationen/presentation/painters/drawing_painter.dart';
import 'package:sheetstorm/features/annotationen/presentation/widgets/annotation_toolbar.dart';

/// The annotation overlay that sits on top of the sheet music page.
///
/// Handles:
/// - Stylus vs. finger detection (stylus = draw, finger = navigate)
/// - Pressure-sensitive input
/// - Palm rejection
/// - Rendering of persisted + active annotations
/// - Long-press to enter annotation mode
class AnnotationLayer extends ConsumerStatefulWidget {
  const AnnotationLayer({
    super.key,
    required this.stuckId,
    required this.pageIndex,
    this.isDirigent = false,
    this.stimmeName,
    this.onNavigateBack,
    this.onNavigateForward,
  });

  final String stuckId;
  final int pageIndex;
  final bool isDirigent;
  final String? stimmeName;
  final VoidCallback? onNavigateBack;
  final VoidCallback? onNavigateForward;

  @override
  ConsumerState<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends ConsumerState<AnnotationLayer> {
  /// Current stroke points being drawn
  final List<StrokePoint> _activePoints = [];

  /// Whether a stylus is currently being used
  bool _isStylusActive = false;

  /// Timer for long-press detection
  bool _isLongPressing = false;

  /// Repaint notifier for active drawing (60fps)
  final _drawingNotifier = ValueNotifier<int>(0);

  /// Auto-exit timer
  DateTime? _lastInteractionTime;
  static const _autoExitDuration = Duration(minutes: 3);
  static const _autoExitWarning = Duration(minutes: 2, seconds: 50);

  @override
  void dispose() {
    _drawingNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final annotationState = ref.watch(annotationProvider(widget.stuckId));
    final toolbarState = ref.watch(annotationToolbarProvider);
    final isActive = annotationState.isAnnotationMode;

    return Stack(
      children: [
        // ─── Persisted Annotations Layer (RepaintBoundary for performance) ───
        RepaintBoundary(
          child: CustomPaint(
            painter: AnnotationPainter(
              annotations: annotationState.visibleAnnotations,
              layerVisibility: annotationState.layerVisibility,
            ),
            size: Size.infinite,
          ),
        ),

        // ─── Active Drawing Layer (repaints at 60fps during drawing) ─────────
        if (isActive && _activePoints.isNotEmpty)
          ValueListenableBuilder<int>(
            valueListenable: _drawingNotifier,
            builder: (_, __, ___) => CustomPaint(
              painter: DrawingPainter(
                points: List.unmodifiable(_activePoints),
                color: toolbarState.activeLevel.color,
                strokeWidth: toolbarState.effectiveStrokeWidth,
                opacity: toolbarState.effectiveOpacity,
                tool: toolbarState.activeTool,
              ),
              size: Size.infinite,
            ),
          ),

        // ─── Input Handler ───────────────────────────────────────────────────
        Positioned.fill(
          child: Listener(
            onPointerDown: (event) => _onPointerDown(event, isActive),
            onPointerMove: (event) => _onPointerMove(event, isActive),
            onPointerUp: (event) => _onPointerUp(event, isActive),
            behavior: HitTestBehavior.translucent,
            child: GestureDetector(
              // Long-press to enter annotation mode (600ms, UX-Spec §4.1)
              onLongPressStart: isActive
                  ? null
                  : (details) => _onLongPressStart(details),
              // Allow taps through when not in annotation mode
              behavior: isActive
                  ? HitTestBehavior.opaque
                  : HitTestBehavior.translucent,
            ),
          ),
        ),

        // ─── Toolbar (only visible in annotation mode) ──────────────────────
        if (isActive)
          AnnotationToolbar(
            stuckId: widget.stuckId,
            isDirigent: widget.isDirigent,
            stimmeName: widget.stimmeName,
            onDone: _exitAnnotationMode,
          ),
      ],
    );
  }

  // ─── Stylus Engine ────────────────────────────────────────────────────────

  bool _isStylusEvent(PointerEvent event) {
    return event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;
  }

  bool _shouldDraw(PointerEvent event, bool isActive) {
    // Stylus always draws (auto-activates annotation mode)
    if (_isStylusEvent(event)) return true;

    // Finger only draws if annotation mode is active
    return isActive;
  }

  /// Palm rejection: ignore events with large contact areas
  bool _isPalmContact(PointerEvent event) {
    // Palm typically has a larger radiusMajor
    if (event.radiusMajor > 30.0 && !_isStylusEvent(event)) return true;
    return false;
  }

  void _onPointerDown(PointerEvent event, bool isActive) {
    if (_isPalmContact(event)) return;

    final isStylusInput = _isStylusEvent(event);

    // Auto-activate annotation mode when stylus touches (UX-Spec §4.1)
    if (isStylusInput && !isActive) {
      ref.read(annotationProvider(widget.stuckId).notifier).enterAnnotationMode();
      _isStylusActive = true;
    }

    if (!_shouldDraw(event, isActive) && !isStylusInput) return;

    _lastInteractionTime = DateTime.now();

    final toolbarState = ref.read(annotationToolbarProvider);
    final tool = toolbarState.activeTool;
    final size = context.size;
    if (size == null) return;

    final double relX = (event.localPosition.dx / size.width).clamp(0.0, 1.0).toDouble();
    final double relY = (event.localPosition.dy / size.height).clamp(0.0, 1.0).toDouble();
    final double pressure = isStylusInput ? event.pressure.clamp(0.0, 1.0).toDouble() : 0.5;

    switch (tool) {
      case AnnotationTool.pencil:
      case AnnotationTool.highlighter:
      case AnnotationTool.eraser:
        _activePoints.clear();
        _activePoints.add(StrokePoint(x: relX, y: relY, pressure: pressure));
        _notifyDrawing();

      case AnnotationTool.text:
        _showTextInput(relX, relY);

      case AnnotationTool.stamp:
        _placeStamp(relX, relY);

      case AnnotationTool.selection:
        // Selection would be handled separately
        break;
    }
  }

  void _onPointerMove(PointerEvent event, bool isActive) {
    if (_isPalmContact(event)) return;
    if (!_shouldDraw(event, isActive) && !_isStylusActive) return;

    final size = context.size;
    if (size == null) return;

    final toolbarState = ref.read(annotationToolbarProvider);
    final tool = toolbarState.activeTool;

    if (tool != AnnotationTool.pencil &&
        tool != AnnotationTool.highlighter &&
        tool != AnnotationTool.eraser) {
      return;
    }

    final double relX = (event.localPosition.dx / size.width).clamp(0.0, 1.0).toDouble();
    final double relY = (event.localPosition.dy / size.height).clamp(0.0, 1.0).toDouble();
    final double pressure =
        _isStylusEvent(event) ? event.pressure.clamp(0.0, 1.0).toDouble() : 0.5;

    _activePoints.add(StrokePoint(x: relX, y: relY, pressure: pressure));

    // Eraser: real-time erase while moving
    if (tool == AnnotationTool.eraser) {
      ref.read(annotationProvider(widget.stuckId).notifier).eraseAt(
            x: relX,
            y: relY,
            radius: toolbarState.effectiveStrokeWidth / 100, // Normalized
            activeLevel: toolbarState.activeLevel,
          );
    }

    _notifyDrawing();
  }

  void _onPointerUp(PointerEvent event, bool isActive) {
    if (!_shouldDraw(event, isActive) && !_isStylusActive) return;

    _isStylusActive = false;
    final toolbarState = ref.read(annotationToolbarProvider);
    final tool = toolbarState.activeTool;

    if ((tool == AnnotationTool.pencil || tool == AnnotationTool.highlighter) &&
        _activePoints.length >= 2) {
      ref.read(annotationProvider(widget.stuckId).notifier).commitStroke(
            points: List.from(_activePoints),
            level: toolbarState.activeLevel,
            tool: tool,
            strokeWidth: toolbarState.effectiveStrokeWidth,
            opacity: toolbarState.effectiveOpacity,
          );
    }

    _activePoints.clear();
    _notifyDrawing();
  }

  void _notifyDrawing() {
    _drawingNotifier.value++;
  }

  // ─── Long Press to Enter Annotation Mode ──────────────────────────────────

  void _onLongPressStart(LongPressStartDetails details) {
    HapticFeedback.mediumImpact();
    ref.read(annotationProvider(widget.stuckId).notifier).enterAnnotationMode();
  }

  void _exitAnnotationMode() {
    _activePoints.clear();
    ref.read(annotationProvider(widget.stuckId).notifier).exitAnnotationMode();
    ref.read(annotationToolbarProvider.notifier).closeStampPicker();
  }

  // ─── Text Input ───────────────────────────────────────────────────────────

  void _showTextInput(double relX, double relY) {
    final toolbarState = ref.read(annotationToolbarProvider);

    showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Text-Annotation'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Annotation eingeben...',
              border: const OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: toolbarState.activeLevel.color,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    ).then((text) {
      if (text != null && text.isNotEmpty) {
        ref.read(annotationProvider(widget.stuckId).notifier).addTextAnnotation(
              text: text,
              x: relX,
              y: relY,
              level: toolbarState.activeLevel,
            );
      }
    });
  }

  // ─── Stamp Placement ──────────────────────────────────────────────────────

  void _placeStamp(double relX, double relY) {
    final toolbarState = ref.read(annotationToolbarProvider);
    final category = toolbarState.selectedStampCategory;
    final value = toolbarState.selectedStampValue;

    if (value == null) {
      // Open stamp picker if no stamp selected
      ref.read(annotationToolbarProvider.notifier).toggleStampPicker();
      return;
    }

    ref.read(annotationProvider(widget.stuckId).notifier).addStampAnnotation(
          category: category,
          value: value,
          x: relX,
          y: relY,
          level: toolbarState.activeLevel,
        );
  }
}
