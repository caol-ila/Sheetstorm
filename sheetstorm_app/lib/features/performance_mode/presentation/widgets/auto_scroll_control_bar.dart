import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';

/// Compact control bar for auto-scroll (UX-Spec §5.1).
///
/// Layout: [Stop] [Play/Pause] [Reset]  [−] speed [+]
/// Height: 48px, slide-in from bottom.
class AutoScrollControlBar extends ConsumerWidget {
  const AutoScrollControlBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scrollState = ref.watch(autoScrollProvider);
    final notifier = ref.read(autoScrollProvider.notifier);

    return SizedBox(
      height: 48,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // ── Stop ──────────────────────────────────────
              _ControlButton(
                icon: Icons.stop,
                onPressed: scrollState.isIdle ? null : notifier.stop,
                semanticLabel: 'Stop',
              ),
              const SizedBox(width: 4),

              // ── Play / Pause ──────────────────────────────
              _ControlButton(
                icon: scrollState.isPlaying ? Icons.pause : Icons.play_arrow,
                onPressed: () {
                  if (scrollState.isPlaying) {
                    notifier.pause();
                  } else {
                    notifier.play();
                  }
                },
                isPrimary: true,
                semanticLabel:
                    scrollState.isPlaying ? 'Pause' : 'Abspielen',
              ),
              const SizedBox(width: 4),

              // ── Reset ─────────────────────────────────────
              _ControlButton(
                icon: Icons.replay,
                onPressed: notifier.reset,
                semanticLabel: 'Zurücksetzen',
              ),

              const Spacer(),

              // ── Speed: [−] label [+] ──────────────────────
              _ControlButton(
                icon: Icons.remove,
                onPressed: notifier.decrementSpeed,
                semanticLabel: 'Langsamer',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  scrollState.speedLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              _ControlButton(
                icon: Icons.add,
                onPressed: notifier.incrementSpeed,
                semanticLabel: 'Schneller',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single control button with minimum touch target (UX §5.3: 44×40).
class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 40,
      child: IconButton(
        icon: Icon(icon, size: 24),
        onPressed: onPressed,
        tooltip: semanticLabel,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 40),
        color: isPrimary
            ? Theme.of(context).colorScheme.primary
            : null,
        disabledColor: Theme.of(context).disabledColor,
      ),
    );
  }
}
