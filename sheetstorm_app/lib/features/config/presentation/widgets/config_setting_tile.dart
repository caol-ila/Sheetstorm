/// Main setting tile widget with level indicators — Issue #35
///
/// The core UI component for each config entry. Shows:
/// - 4px colored left border indicating level
/// - Level badge + icon
/// - Setting label and value
/// - Policy lock indicator
/// - Override/Reset controls
///
/// Minimum touch target: 44px (ux-design.md § 1.2)

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_level_badge.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_policy_indicator.dart';

class ConfigSettingTile extends StatelessWidget {
  const ConfigSettingTile({
    super.key,
    required this.keyDef,
    required this.resolved,
    required this.onChanged,
    this.onOverride,
    this.onReset,
    this.viewLevel,
  });

  final ConfigKeyDef keyDef;
  final ResolvedConfigValue resolved;
  final ValueChanged<dynamic> onChanged;
  final VoidCallback? onOverride;
  final VoidCallback? onReset;
  final ConfigEbene? viewLevel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = resolved.istGesperrt;
    final isInherited = viewLevel != null && resolved.herkunft != viewLevel;
    final levelColor = ConfigLevelBadge.colorFor(resolved.herkunft);

    return Semantics(
      label: '${keyDef.label}, ${resolved.herkunft.beschreibung}'
          '${isLocked ? ', gesperrt' : ''}',
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: levelColor, width: 4),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: label + badge
                Row(
                  children: [
                    if (isLocked)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          Icons.lock,
                          size: 16,
                          color: AppColors.warning,
                          semanticLabel: 'Gesperrt',
                        ),
                      ),
                    Expanded(
                      child: Text(
                        keyDef.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isLocked
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                    ConfigLevelBadge(ebene: resolved.herkunft, compact: true),
                  ],
                ),

                // Description
                if (keyDef.beschreibung != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    keyDef.beschreibung!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],

                // Policy lock explanation
                if (isLocked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  const ConfigPolicyIndicator(),
                ],

                // Inherited value indicator
                if (isInherited && !isLocked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _InheritedIndicator(
                    herkunft: resolved.herkunft,
                    onOverride: onOverride,
                  ),
                ],

                // Setting control (if not locked)
                if (!isLocked) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildControl(context),
                ],

                // Reset button (if overridden)
                if (!isInherited && !isLocked && onReset != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _ResetButton(
                    herkunft: resolved.herkunft,
                    onReset: onReset!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControl(BuildContext context) {
    final isLocked = resolved.istGesperrt;
    final isInherited = viewLevel != null && resolved.herkunft != viewLevel;

    switch (keyDef.widgetType) {
      case ConfigWidgetType.toggle:
        return SizedBox(
          height: AppSpacing.touchTargetMin,
          child: Switch(
            value: (resolved.wert as bool?) ?? false,
            onChanged: isLocked || isInherited ? null : (v) => onChanged(v),
          ),
        );

      case ConfigWidgetType.dropdown:
        return SizedBox(
          height: AppSpacing.touchTargetMin,
          child: DropdownButton<String>(
            value: resolved.wert?.toString(),
            isExpanded: true,
            onChanged: isLocked || isInherited
                ? null
                : (v) => onChanged(v),
            items: (keyDef.optionen ?? []).map((o) {
              return DropdownMenuItem(value: o, child: Text(_formatOption(o)));
            }).toList(),
          ),
        );

      case ConfigWidgetType.segmented:
        return SizedBox(
          height: AppSpacing.touchTargetMin,
          child: SegmentedButton<String>(
            segments: (keyDef.optionen ?? []).map((o) {
              return ButtonSegment(value: o, label: Text(_formatOption(o)));
            }).toList(),
            selected: {resolved.wert?.toString() ?? ''},
            onSelectionChanged: isLocked || isInherited
                ? null
                : (v) => onChanged(v.first),
          ),
        );

      case ConfigWidgetType.slider:
        final min = keyDef.min ?? 0.0;
        final max = keyDef.max ?? 1.0;
        final currentValue = (resolved.wert is num)
            ? (resolved.wert as num).toDouble()
            : min;
        return SizedBox(
          height: AppSpacing.touchTargetMin,
          child: Slider(
            value: currentValue.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            label: currentValue.toStringAsFixed(1),
            onChanged: isLocked || isInherited
                ? null
                : (v) => onChanged(v),
          ),
        );

      case ConfigWidgetType.number:
        return SizedBox(
          height: AppSpacing.touchTargetMin,
          child: _NumberInput(
            value: resolved.wert is num ? (resolved.wert as num).toInt() : 0,
            min: keyDef.min?.toInt(),
            max: keyDef.max?.toInt(),
            enabled: !isLocked && !isInherited,
            onChanged: (v) => onChanged(v),
          ),
        );

      case ConfigWidgetType.text:
        return TextField(
          controller: TextEditingController(text: resolved.wert?.toString()),
          enabled: !isLocked && !isInherited,
          onSubmitted: (v) => onChanged(v),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
          ),
        );

      case ConfigWidgetType.roleSelector:
      case ConfigWidgetType.colorPicker:
        // Simplified: show as text for now
        return Text(
          resolved.wert?.toString() ?? '—',
          style: Theme.of(context).textTheme.bodyLarge,
        );
    }
  }

  String _formatOption(String option) {
    switch (option) {
      case 'light':
        return 'Hell';
      case 'dark':
        return 'Dunkel';
      case 'system':
        return 'Wie Gerät';
      case 'horizontal':
        return 'Horizontal';
      case 'vertikal':
        return 'Vertikal';
      case 'klein':
        return 'Klein';
      case 'mittel':
        return 'Mittel';
      case 'gross':
        return 'Groß';
      case 'sehr_gross':
        return 'Sehr Groß';
      case 'gering':
        return 'Gering';
      case 'hoch':
        return 'Hoch';
      case 'de':
        return 'Deutsch';
      case 'en':
        return 'English';
      case 'azure_vision':
        return 'Azure AI Vision';
      case 'openai_vision':
        return 'OpenAI Vision';
      case 'google_vision':
        return 'Google Vision';
      case 'null':
        return 'Frei wählbar';
      case 'true':
        return 'Erzwungen: An';
      case 'false':
        return 'Erzwungen: Aus';
      default:
        return option;
    }
  }
}

// ─── Sub-Widgets ──────────────────────────────────────────────────────────────

class _InheritedIndicator extends StatelessWidget {
  const _InheritedIndicator({
    required this.herkunft,
    this.onOverride,
  });

  final ConfigEbene herkunft;
  final VoidCallback? onOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = ConfigLevelBadge.colorFor(herkunft);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: AppSpacing.roundedSm,
      ),
      child: Row(
        children: [
          Icon(ConfigLevelBadge.iconFor(herkunft), size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Standard von ${herkunft.label}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (onOverride != null)
            TextButton(
              onPressed: onOverride,
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSpacing.touchTargetMin,
                  AppSpacing.touchTargetMin,
                ),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('Eigenen Wert festlegen'),
            ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({
    required this.herkunft,
    required this.onReset,
  });

  final ConfigEbene herkunft;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onReset,
        icon: const Icon(Icons.restore, size: 16),
        label: const Text('Zurücksetzen'),
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.touchTargetMin,
            AppSpacing.touchTargetMin,
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.value,
    this.min,
    this.max,
    required this.enabled,
    required this.onChanged,
  });

  final int value;
  final int? min;
  final int? max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: enabled && (min == null || value > min!)
              ? () => onChanged(value - 1)
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchTargetMin,
            minHeight: AppSpacing.touchTargetMin,
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: AppTypography.weightMedium,
            ),
          ),
        ),
        IconButton(
          onPressed: enabled && (max == null || value < max!)
              ? () => onChanged(value + 1)
              : null,
          icon: const Icon(Icons.add_circle_outline),
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchTargetMin,
            minHeight: AppSpacing.touchTargetMin,
          ),
        ),
      ],
    );
  }
}
