import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/metronome/application/metronome_notifier.dart';

/// Canvas-based beat indicator for 60fps animation.
///
/// Renders a pulsing circle that flashes on each beat.
/// Beat 1 (downbeat) uses accent color, other beats use primary.
class BeatIndicator extends ConsumerStatefulWidget {
  const BeatIndicator({super.key});

  @override
  ConsumerState<BeatIndicator> createState() => _BeatIndicatorState();
}

class _BeatIndicatorState extends ConsumerState<BeatIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  int _lastBeatNumber = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeProvider);
    final currentBeat = state.currentBeat;
    final beatsPerMeasure = state.timeSignature.beatsPerMeasure;

    // Trigger pulse animation on beat change
    if (currentBeat != null && currentBeat.beatNumber != _lastBeatNumber) {
      _lastBeatNumber = currentBeat.beatNumber;
      _controller.forward(from: 0.0);
    }

    final isDownbeat = currentBeat?.isDownbeat ?? false;
    final beatActive = state.isPlaying && currentBeat != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight) * 0.6;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Beat circle
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: BeatCirclePainter(
                    isActive: beatActive,
                    isDownbeat: isDownbeat,
                    pulseScale: beatActive ? _pulseAnimation.value : 1.0,
                    accentColor: isDownbeat
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Beat position dots
            if (beatsPerMeasure > 0)
              _BeatPositionDots(
                beatsPerMeasure: beatsPerMeasure,
                currentBeatInMeasure: currentBeat?.beatInMeasure,
                isPlaying: state.isPlaying,
              ),
          ],
        );
      },
    );
  }
}

/// CustomPainter for the beat circle.
///
/// Draws a circle that changes color and scale on each beat.
/// Downbeats (beat 1) use accent color, other beats use primary.
class BeatCirclePainter extends CustomPainter {
  final bool isActive;
  final bool isDownbeat;
  final double pulseScale;
  final Color accentColor;
  final Color inactiveColor;

  BeatCirclePainter({
    required this.isActive,
    required this.isDownbeat,
    required this.pulseScale,
    required this.accentColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) / 2;
    final radius = baseRadius * pulseScale;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isActive ? accentColor : inactiveColor;

    canvas.drawCircle(center, radius, paint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = isActive
          ? accentColor.withValues(alpha: 0.5)
          : inactiveColor.withValues(alpha: 0.3);

    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(BeatCirclePainter oldDelegate) =>
      isActive != oldDelegate.isActive ||
      isDownbeat != oldDelegate.isDownbeat ||
      pulseScale != oldDelegate.pulseScale ||
      accentColor != oldDelegate.accentColor;
}

/// Beat position dots (e.g., ● ○ ○ ○ for 4/4).
class _BeatPositionDots extends StatelessWidget {
  final int beatsPerMeasure;
  final int? currentBeatInMeasure;
  final bool isPlaying;

  const _BeatPositionDots({
    required this.beatsPerMeasure,
    required this.currentBeatInMeasure,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(beatsPerMeasure, (index) {
        final isActive = isPlaying && currentBeatInMeasure == index;
        final isFirst = index == 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: isActive ? 14 : 10,
                height: isActive ? 14 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (isFirst
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary)
                      : null,
                  border: isActive
                      ? null
                      : Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
