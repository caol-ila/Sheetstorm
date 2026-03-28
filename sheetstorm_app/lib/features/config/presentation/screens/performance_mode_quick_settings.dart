/// Spielmodus quick-settings overlay — Issue #35
///
/// Max 5 options, semi-transparent over sheet music.
/// Auto-close after 5s inactivity.
/// Reference: docs/ux-specs/konfiguration.md § 9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/application/config_notifier.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';

class PerformanceModeQuickSettings extends ConsumerStatefulWidget {
  const PerformanceModeQuickSettings({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  ConsumerState<PerformanceModeQuickSettings> createState() =>
      _PerformanceModeQuickSettingsState();
}

class _PerformanceModeQuickSettingsState
    extends ConsumerState<PerformanceModeQuickSettings>
    with SingleTickerProviderStateMixin {
  Timer? _autoCloseTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.base,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: AppCurves.enter,
    );
    _animController.forward();
    _resetAutoClose();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _resetAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      _animController.reverse().then((_) => widget.onClose());
    });
  }

  void _onInteraction() {
    _resetAutoClose();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(configNotifierProvider);
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: widget.onClose,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent tap-through
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.xl),
                constraints: const BoxConstraints(maxWidth: 380),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withOpacity(0.95),
                  borderRadius: AppSpacing.roundedLg,
                  boxShadow: AppShadows.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.settings,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Schnelleinstellungen',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: widget.onClose,
                            tooltip: 'Schließen',
                            constraints: const BoxConstraints(
                              minWidth: AppSpacing.touchTargetMin,
                              minHeight: AppSpacing.touchTargetMin,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // 5 Quick Settings
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          // 1. Dark Mode Toggle
                          _QuickToggle(
                            icon: Icons.dark_mode,
                            label: 'Nachtmodus',
                            value: _getBoolValue(
                                configState, 'user.theme', 'dark'),
                            isLocked: configState.isLocked('user.theme'),
                            onChanged: (v) {
                              _onInteraction();
                              ref
                                  .read(configNotifierProvider.notifier)
                                  .updateConfig(
                                    'user.theme',
                                    v ? 'dark' : 'light',
                                    level: ConfigLevel.device,
                                  );
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 2. Half-Page-Turn Toggle
                          _QuickToggle(
                            icon: Icons.vertical_split,
                            label: 'Half-Page-Turn',
                            value: (configState.getValue<dynamic>(
                                    'user.performance_mode.half_page_turn') ==
                                true),
                            isLocked: configState.isLocked(
                                'user.performance_mode.half_page_turn'),
                            onChanged: (v) {
                              _onInteraction();
                              ref
                                  .read(configNotifierProvider.notifier)
                                  .updateConfig(
                                    'user.performance_mode.half_page_turn',
                                    v,
                                    level: ConfigLevel.device,
                                  );
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 3. Schriftgröße
                          _QuickSegmented(
                            icon: Icons.text_fields,
                            label: 'Schriftgröße',
                            value: configState
                                    .getValue<dynamic>(
                                        'device.display.font_size')
                                    ?.toString() ??
                                'mittel',
                            options: const [
                              'klein',
                              'mittel',
                              'gross',
                              'sehr_gross'
                            ],
                            optionLabels: const [
                              'S',
                              'M',
                              'L',
                              'XL'
                            ],
                            onChanged: (v) {
                              _onInteraction();
                              ref
                                  .read(configNotifierProvider.notifier)
                                  .updateConfig(
                                    'device.display.font_size',
                                    v,
                                    level: ConfigLevel.device,
                                  );
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 4. Annotation Layers (simplified as toggle)
                          _QuickToggle(
                            icon: Icons.layers,
                            label: 'annotations',
                            value: true,
                            isLocked: false,
                            onChanged: (v) {
                              _onInteraction();
                              // Toggle annotation visibility
                            },
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // 5. Helligkeit Slider
                          _QuickSlider(
                            icon: Icons.brightness_6,
                            label: 'Helligkeit',
                            value: _getDoubleValue(
                              configState,
                              'device.display.brightness',
                              1.0,
                            ),
                            min: 0.5,
                            max: 1.5,
                            onChanged: (v) {
                              _onInteraction();
                              ref
                                  .read(configNotifierProvider.notifier)
                                  .updateConfig(
                                    'device.display.brightness',
                                    v,
                                    level: ConfigLevel.device,
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _getBoolValue(ConfigState state, String key, String trueValue) {
    final val = state.resolved[key]?.value;
    return val?.toString() == trueValue;
  }

  double _getDoubleValue(ConfigState state, String key, double fallback) {
    final val = state.resolved[key]?.value;
    if (val is num) return val.toDouble();
    return fallback;
  }
}

// ─── Quick Setting Widgets ────────────────────────────────────────────────────

class _QuickToggle extends StatelessWidget {
  const _QuickToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.isLocked,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final bool isLocked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: AppSpacing.touchTargetMin,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyLarge),
          ),
          if (isLocked)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(Icons.lock, size: 16, color: AppColors.warning),
            ),
          Switch(
            value: value,
            onChanged: isLocked ? null : onChanged,
          ),
        ],
      ),
    );
  }
}

class _QuickSlider extends StatelessWidget {
  const _QuickSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        SizedBox(
          height: AppSpacing.touchTargetMin,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _QuickSegmented extends StatelessWidget {
  const _QuickSegmented({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabels,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final List<String> optionLabels;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: AppSpacing.touchTargetMin,
          child: SegmentedButton<String>(
            segments: List.generate(options.length, (i) {
              return ButtonSegment(
                value: options[i],
                label: Text(optionLabels[i]),
              );
            }),
            selected: {value},
            onSelectionChanged: (v) => onChanged(v.first),
            style: SegmentedButton.styleFrom(
              textStyle: const TextStyle(fontSize: AppTypography.fontSizeSm),
            ),
          ),
        ),
      ],
    );
  }
}
