import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Top and bottom overlay bars for the Spielmodus (UX §7).
///
/// Appears on center-tap with 150ms fade-in (AC-52).
/// Auto-hides after 4 seconds without interaction (AC-53).
/// All touch targets ≥ 44px, bottom bar ≥ 64px (AC-55).
class PerformanceModeOverlay extends StatelessWidget {
  const PerformanceModeOverlay({
    super.key,
    required this.visible,
    required this.pageIndicator,
    required this.onBack,
    required this.onSettings,
    required this.onStimme,
    required this.onNightMode,
    required this.onLock,
    required this.onPageIndicatorTap,
    required this.onInteraction,
    this.nightModeIcon = Icons.nights_stay_outlined,
    this.nightModeLabel = 'Nacht',
  });

  final bool visible;
  final String pageIndicator;
  final VoidCallback onBack;
  final VoidCallback onSettings;
  final VoidCallback onStimme;
  final VoidCallback onNightMode;
  final VoidCallback onLock;
  final VoidCallback onPageIndicatorTap;
  final VoidCallback onInteraction;
  final IconData nightModeIcon;
  final String nightModeLabel;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: AppDurations.fast,
        curve: AppCurves.enter,
        child: GestureDetector(
          onTap: onInteraction,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              _buildTopBar(context),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: onBack,
                  tooltip: 'Zurück',
                  iconSize: 24,
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTargetMin,
                    minHeight: AppSpacing.touchTargetMin,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Page/Setlist indicator — tappable for setlist nav (UX §9.1)
                Expanded(
                  child: GestureDetector(
                    onTap: onPageIndicatorTap,
                    child: Text(
                      pageIndicator,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.fontSizeBase,
                        fontWeight: AppTypography.weightMedium,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // Settings button
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: onSettings,
                  tooltip: 'Einstellungen',
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchTargetMin,
                    minHeight: AppSpacing.touchTargetMin,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stimme wechseln (AC-37)
                _OverlayButton(
                  icon: Icons.music_note_outlined,
                  label: 'Stimme',
                  onTap: onStimme,
                ),

                // Nachtmodus toggle (AC-31)
                _OverlayButton(
                  icon: nightModeIcon,
                  label: nightModeLabel,
                  onTap: onNightMode,
                ),

                // UI Lock (AC-05)
                _OverlayButton(
                  icon: Icons.lock_outline,
                  label: 'Sperren',
                  onTap: onLock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: AppSpacing.touchTargetPlay,
          minHeight: AppSpacing.touchTargetPlay,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppTypography.fontSizeXs,
                fontWeight: AppTypography.weightMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
