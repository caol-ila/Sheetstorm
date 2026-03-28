import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/song_broadcast/data/services/broadcast_service.dart';

/// Visual indicator of the SignalR connection state.
///
/// Shows a pulsing dot, color-coded by state:
/// - Green: connected
/// - Orange: connecting/reconnecting
/// - Red: disconnected
class BroadcastStatusIndicator extends StatefulWidget {
  const BroadcastStatusIndicator({
    super.key,
    required this.connectionState,
    this.compact = false,
  });

  final SignalRConnectionState connectionState;
  final bool compact;

  @override
  State<BroadcastStatusIndicator> createState() =>
      _BroadcastStatusIndicatorState();
}

class _BroadcastStatusIndicatorState extends State<BroadcastStatusIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _updateAnimation();
  }

  @override
  void didUpdateWidget(BroadcastStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionState != widget.connectionState) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.connectionState == SignalRConnectionState.connecting ||
        widget.connectionState == SignalRConnectionState.reconnecting) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _color => switch (widget.connectionState) {
        SignalRConnectionState.connected => AppColors.success,
        SignalRConnectionState.connecting => AppColors.warning,
        SignalRConnectionState.reconnecting => AppColors.warning,
        SignalRConnectionState.disconnected => AppColors.error,
      };

  String get _label => switch (widget.connectionState) {
        SignalRConnectionState.connected => 'Verbunden',
        SignalRConnectionState.connecting => 'Verbindung…',
        SignalRConnectionState.reconnecting => 'Erneut verbinden…',
        SignalRConnectionState.disconnected => 'Getrennt',
      };

  IconData get _icon => switch (widget.connectionState) {
        SignalRConnectionState.connected => Icons.podcasts,
        SignalRConnectionState.connecting => Icons.sync,
        SignalRConnectionState.reconnecting => Icons.sync,
        SignalRConnectionState.disconnected => Icons.wifi_off,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.compact) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: _animation.value),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            _label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
