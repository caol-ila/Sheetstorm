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

  /// Tracks scale-gesture start state for tap/swipe disambiguation.
  Offset _scaleStartPosition = Offset.zero;
  Offset _scaleCurrentPosition = Offset.zero;
  DateTime? _scaleStartTime;
  double _scaleMaxDelta = 0.0;

  /// For double-tap detection via scale callbacks.
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  /// Tap detection thresholds.
  static const _tapMaxDuration = Duration(milliseconds: 250);
  static const _tapMaxMovement = 20.0;
  static const _doubleTapMaxInterval = Duration(milliseconds: 300);
  static const _doubleTapMaxDistance = 40.0;

  /// Swipe threshold: 40px minimum (ux-design.md §1.2, handschuh-kompatibel)
  static const _swipeThreshold = 40.0;

  /// Center zone: ±5% of screen width around the middle (UX §3.2)
  static const _centerZoneFraction = 0.05;

  void _handleTap(Offset localPosition, double screenWidth) {
    if (widget.isLocked) return;

    final now = DateTime.now();

    // Double-tap detection: two taps close together in time and space.
    if (_lastTapTime != null && _lastTapPosition != null) {
      final interval = now.difference(_lastTapTime!);
      final dist = (localPosition - _lastTapPosition!).distance;
      if (interval <= _doubleTapMaxInterval && dist <= _doubleTapMaxDistance) {
        _lastTapTime = null;
        _lastTapPosition = null;
        widget.onDoubleTap();
        return;
      }
    }

    _lastTapTime = now;
    _lastTapPosition = localPosition;

    final relativeX = localPosition.dx / screenWidth;

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

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
    _scaleStartPosition = details.localFocalPoint;
    _scaleCurrentPosition = details.localFocalPoint;
    _scaleStartTime = DateTime.now();
    _scaleMaxDelta = 0.0;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    _scaleCurrentPosition = details.localFocalPoint;

    final scaleDelta = (details.scale - 1.0).abs();
    if (scaleDelta > _scaleMaxDelta) _scaleMaxDelta = scaleDelta;

    // Only apply zoom for actual multi-finger pinch (AC-50).
    if (details.pointerCount >= 2 && !widget.isLocked) {
      _currentScale = (_baseScale * details.scale).clamp(0.5, 5.0);
      widget.onZoomChanged?.call(_currentScale);
    }
  }

  void _onScaleEnd(ScaleEndDetails details, double widgetWidth) {
    final duration = _scaleStartTime != null
        ? DateTime.now().difference(_scaleStartTime!)
        : const Duration(seconds: 1);

    // Use both velocity AND raw displacement for swipe detection.
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final displacementX = _scaleCurrentPosition.dx - _scaleStartPosition.dx;
    final totalDisplacementAbs = (_scaleCurrentPosition - _scaleStartPosition).distance;

    // Single-finger gesture — scale must stay near 1.0
    if (details.pointerCount <= 1 && _scaleMaxDelta < 0.1) {
      // Swipe: significant horizontal displacement OR high velocity (AC-08)
      final isSwipe = velocityX.abs() > 100 || displacementX.abs() >= _swipeThreshold;
      if (isSwipe && !widget.isLocked) {
        final goingLeft = velocityX < -50 || (velocityX.abs() <= 50 && displacementX < 0);
        if (goingLeft) {
          widget.onNextPage();
        } else {
          widget.onPreviousPage();
        }
        return;
      }

      // Tap: short duration and minimal movement
      if (duration <= _tapMaxDuration && totalDisplacementAbs < _tapMaxMovement) {
        _handleTap(_scaleStartPosition, widgetWidth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widgetWidth = constraints.maxWidth;
        return GestureDetector(
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: (details) => _onScaleEnd(details, widgetWidth),
          behavior: HitTestBehavior.opaque,
          child: widget.child,
        );
      },
    );
  }
}
