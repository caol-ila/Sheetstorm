import 'dart:async';

import 'package:flutter/material.dart';

/// Auto-scroll widget for continuous vertical scrolling through long pieces.
///
/// Wraps a child in a scrollable viewport and auto-scrolls at configurable speed.
class AutoScrollWrapper extends StatefulWidget {
  const AutoScrollWrapper({
    super.key,
    required this.isActive,
    required this.speed,
    required this.child,
  });

  /// Whether auto-scroll is currently running
  final bool isActive;

  /// Scroll speed in logical pixels per second
  final double speed;

  final Widget child;

  @override
  State<AutoScrollWrapper> createState() => _AutoScrollWrapperState();
}

class _AutoScrollWrapperState extends State<AutoScrollWrapper> {
  final _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _startScrolling();
  }

  @override
  void didUpdateWidget(AutoScrollWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive ||
        widget.speed != oldWidget.speed) {
      _stopScrolling();
      if (widget.isActive) _startScrolling();
    }
  }

  @override
  void dispose() {
    _stopScrolling();
    _scrollController.dispose();
    super.dispose();
  }

  void _startScrolling() {
    const frameInterval = Duration(milliseconds: 16); // ~60fps
    _scrollTimer = Timer.periodic(frameInterval, (_) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      if (currentScroll >= maxScroll) return;

      final delta = widget.speed * 0.016; // speed * seconds per frame
      _scrollController.jumpTo((currentScroll + delta).clamp(0.0, maxScroll));
    });
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: widget.isActive
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      child: widget.child,
    );
  }
}
