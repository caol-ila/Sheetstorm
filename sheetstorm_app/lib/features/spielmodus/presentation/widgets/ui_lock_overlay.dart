import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// UI-Lock indicator overlay (UX §14).
///
/// When locked, only tap-zones (page forward/back) work.
/// 5 consecutive center taps required to unlock (AC-05).
class UiLockOverlay extends StatefulWidget {
  const UiLockOverlay({
    super.key,
    required this.isLocked,
    required this.onUnlockTriggered,
  });

  final bool isLocked;
  final VoidCallback onUnlockTriggered;

  @override
  State<UiLockOverlay> createState() => _UiLockOverlayState();
}

class _UiLockOverlayState extends State<UiLockOverlay> {
  int _centerTapCount = 0;
  DateTime? _lastTapTime;

  static const _requiredTaps = 5;
  static const _tapResetDuration = Duration(seconds: 3);

  void _onCenterTap() {
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) > _tapResetDuration) {
      _centerTapCount = 0;
    }
    _lastTapTime = now;
    _centerTapCount++;

    if (_centerTapCount >= _requiredTaps) {
      _centerTapCount = 0;
      widget.onUnlockTriggered();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLocked) return const SizedBox.shrink();

    return Positioned.fill(
      child: GestureDetector(
        onTap: _onCenterTap,
        child: Container(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedOpacity(
                  opacity: _centerTapCount > 0 ? 1.0 : 0.0,
                  duration: AppDurations.fast,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, color: Colors.white70, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Tippe ${_requiredTaps - _centerTapCount}× in die Mitte zum Entsperren',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: AppTypography.fontSizeSm,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
