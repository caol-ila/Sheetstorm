/// Kapelle settings screen (Admin only) — Issue #35
///
/// Blue-themed. Shows organization-wide settings + policies.
/// Reference: docs/ux-specs/konfiguration.md § 4

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/application/config_notifier.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_setting_tile.dart';

class BandSettingsScreen extends ConsumerWidget {
  const BandSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configNotifierProvider);
    final grouped = ConfigKeys.groupedByCategory(ConfigLevel.band);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.configBand.withOpacity(0.05),
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: AppColors.configBand.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  color: AppColors.configBand,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kapelle-Einstellungen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.configBand,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        'Gelten für alle Mitglieder dieser Kapelle',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Settings grouped by category
        for (final entry in grouped.entries) ...[
          _CategoryHeader(
            title: entry.key,
            color: AppColors.configBand,
          ),
          for (final keyDef in entry.value)
            _buildSettingTile(context, ref, configState, keyDef),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Policies section
        if (configState.policies.isNotEmpty) ...[
          _CategoryHeader(
            title: 'Aktive Policies',
            color: AppColors.warning,
            icon: Icons.shield,
          ),
          _PoliciesSection(
            policies: configState.policies,
            onToggle: (key, value) {
              ref.read(configNotifierProvider.notifier).togglePolicy(key, value);
            },
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    WidgetRef ref,
    ConfigState configState,
    ConfigKeyDef keyDef,
  ) {
    final resolved = configState.resolved[keyDef.key];
    if (resolved == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: ConfigSettingTile(
          keyDef: keyDef,
          resolved: resolved,
          viewLevel: ConfigLevel.band,
          onChanged: (value) {
            ref.read(configNotifierProvider.notifier).updateConfig(
                  keyDef.key,
                  value,
                  level: ConfigLevel.band,
                );
          },
          onReset: resolved.source == ConfigLevel.band
              ? () {
                  ref
                      .read(configNotifierProvider.notifier)
                      .resetToParent(keyDef.key, ConfigLevel.band);
                }
              : null,
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
    required this.color,
    this.icon,
  });

  final String title;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: AppTypography.fontSizeXs,
              fontWeight: AppTypography.weightBold,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PoliciesSection extends StatelessWidget {
  const _PoliciesSection({
    required this.policies,
    required this.onToggle,
  });

  final Map<String, ConfigPolicy> policies;
  final void Function(String key, dynamic value) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.05),
              borderRadius: AppSpacing.roundedSm,
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Policies mit Bedacht verwenden — sie schränken alle Mitglieder ein',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in policies.entries)
            _PolicyTile(
              key: entry.key,
              policy: entry.value,
              onToggle: (value) => onToggle(entry.key, value),
            ),
        ],
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  const _PolicyTile({
    required this.key,
    required this.policy,
    required this.onToggle,
  });

  final String key;
  final ConfigPolicy policy;
  final ValueChanged<dynamic> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyDef = ConfigKeys.lookup(key);
    final isActive = policy.value == true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.lock : Icons.lock_open,
          color: isActive ? AppColors.warning : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(keyDef?.label ?? key),
        subtitle: keyDef?.description != null
            ? Text(keyDef!.description!)
            : null,
        trailing: Switch(
          value: isActive,
          onChanged: (v) => onToggle(v),
          activeColor: AppColors.warning,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
