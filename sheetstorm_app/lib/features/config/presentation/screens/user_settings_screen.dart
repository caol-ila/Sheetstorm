/// Nutzer/Persönlich settings screen — Issue #35
///
/// Green-themed. Shows personal preferences synced across devices.
/// Reference: docs/ux-specs/konfiguration.md § 5

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/application/config_notifier.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_setting_tile.dart';

class UserSettingsScreen extends ConsumerWidget {
  const UserSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configNotifierProvider);
    final grouped = ConfigKeys.groupedByCategory(ConfigLevel.user);
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
              color: AppColors.configUser.withOpacity(0.05),
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: AppColors.configUser.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.configUser,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Persönliche Einstellungen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.configUser,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        'Werden auf allen deinen Geräten synchronisiert',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sync,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Settings grouped by category
        for (final entry in grouped.entries) ...[
          _NutzerCategoryHeader(title: entry.key),
          for (final keyDef in entry.value)
            _buildSettingTile(context, ref, configState, keyDef),
          const SizedBox(height: AppSpacing.sm),
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
          viewLevel: ConfigLevel.user,
          onChanged: (value) {
            ref.read(configNotifierProvider.notifier).updateConfig(
                  keyDef.key,
                  value,
                  level: ConfigLevel.user,
                );
          },
          onOverride: resolved.source != ConfigLevel.user &&
                  !resolved.isLocked
              ? () {
                  // Copy the current value to the Nutzer level
                  ref.read(configNotifierProvider.notifier).overrideAtLevel(
                        keyDef.key,
                        resolved.value,
                        ConfigLevel.user,
                      );
                }
              : null,
          onReset: resolved.source == ConfigLevel.user
              ? () {
                  ref
                      .read(configNotifierProvider.notifier)
                      .resetToParent(keyDef.key, ConfigLevel.user);
                }
              : null,
        ),
      ),
    );
  }
}

class _NutzerCategoryHeader extends StatelessWidget {
  const _NutzerCategoryHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: AppTypography.fontSizeXs,
          fontWeight: AppTypography.weightBold,
          color: AppColors.configUser,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
