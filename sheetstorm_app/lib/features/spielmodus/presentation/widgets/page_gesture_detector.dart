import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Gesture detection layer for Spielmodus (AC-06..AC-12, UX §3.2, §3.3).
///
/// Implements:
/// - Asymmetric tap zones: 40% back / 60% forward
/// - Center tap (~10% width): toggle overlay
/// - Swipe left: next page (threshold ≥ 40px)
/// - Swipe right: previous page
/// - Pinch-to-zoom support
/// - Double-tap: reset zoom (AC-51)
class PageGestureDetector extends StatefulWidget {
  const PageGestureDetector({
    super.key,
    required this.onNextPage,
    required this.onPreviousPage,
    required this.onToggleOverlay,
    required this.onDoubleTap,
    this.onZoomChanged,
    this.isLocked = false,
    this.child,
  });

  final VoidCallback onNextPage;
  final VoidCallback onPreviousPage;
  final VoidCallback onToggleOverlay;
  final VoidCallback onDoubleTap;
  final ValueChanged<double>? onZoomChanged;
  final bool isLocked;
  final Widget? child;

  @override
  State<PageGestureDetector> createState() => _PageGestureDetectorState();
}

class _PageGestureDetectorState extends State<PageGestureDetector> {
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  Offset _panStart = Offset.zero;

  /// Swipe threshold: 40px minimum (ux-design.md §1.2, handschuh-kompatibel)
  static const _swipeThreshold = 40.0;

  /// Center zone: ±5% of screen width around the middle (UX §3.2)
  static const _centerZoneFraction = 0.05;

  void _onTapUp(TapUpDetails details, double screenWidth) {
    if (widget.isLocked) return;

    final tapX = details.localPosition.dx;
    final relativeX = tapX / screenWidth;

    // Center zone: 45%–55% of width → toggle overlay (AC-12)
    if (relativeX >= 0.5 - _centerZoneFraction &&
        relativeX <= 0.5 + _centerZoneFraction) {
      widget.onToggleOverlay();
      return;
    }

    // Left 40%: previous page (AC-07)
    if (relativeX < 0.40) {
      widget.onPreviousPage();
      return;
    }

    // Right 60%: next page (AC-06)
    widget.onNextPage();
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.isLocked) return;

    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;

    if (velocity < 0) {
      // Swipe left → next page (AC-08)
      widget.onNextPage();
    } else {
      // Swipe right → previous page (AC-08)
      widget.onPreviousPage();
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (widget.isLocked) return;
    _currentScale = (_baseScale * details.scale).clamp(0.5, 5.0);
    widget.onZoomChanged?.call(_currentScale);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTapUp: (details) => _onTapUp(details, screenWidth),
      onDoubleTap: widget.isLocked ? null : widget.onDoubleTap,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}
