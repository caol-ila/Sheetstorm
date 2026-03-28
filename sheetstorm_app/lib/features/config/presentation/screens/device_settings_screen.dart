/// Gerät/Device settings screen — Issue #35
///
/// Orange-themed. Local-only device settings, never synced.
/// Reference: docs/ux-specs/konfiguration.md § 6

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/application/config_notifier.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_setting_tile.dart';

class DeviceSettingsScreen extends ConsumerWidget {
  const DeviceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configState = ref.watch(configProvider);
    final grouped = ConfigKeys.groupedByCategory(ConfigLevel.device);
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
              color: AppColors.configDevice.withOpacity(0.05),
              borderRadius: AppSpacing.roundedMd,
              border: Border.all(
                color: AppColors.configDevice.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_android,
                  color: AppColors.configDevice,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geräte-Einstellungen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.configDevice,
                          fontWeight: AppTypography.weightBold,
                        ),
                      ),
                      Text(
                        'Nur auf diesem Gerät — wird nicht synchronisiert',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.sync_disabled,
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
          _GeraetCategoryHeader(title: entry.key),
          for (final keyDef in entry.value)
            _buildSettingTile(context, ref, configState, keyDef),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Cache section
        const SizedBox(height: AppSpacing.md),
        _CacheSection(),

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
          viewLevel: ConfigLevel.device,
          onChanged: (value) {
            ref.read(configProvider.notifier).updateConfig(
                  keyDef.key,
                  value,
                  level: ConfigLevel.device,
                );
          },
          onOverride: resolved.source != ConfigLevel.device &&
                  !resolved.isLocked
              ? () {
                  ref.read(configProvider.notifier).overrideAtLevel(
                        keyDef.key,
                        resolved.value,
                        ConfigLevel.device,
                      );
                }
              : null,
          onReset: resolved.source == ConfigLevel.device
              ? () {
                  ref
                      .read(configProvider.notifier)
                      .resetToParent(keyDef.key, ConfigLevel.device);
                }
              : null,
        ),
      ),
    );
  }
}

class _GeraetCategoryHeader extends StatelessWidget {
  const _GeraetCategoryHeader({required this.title});

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
          color: AppColors.configDevice,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CacheSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SPEICHER & CACHE',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.configDevice,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Cache usage bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Offline-Cache',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: AppSpacing.roundedSm,
                          child: LinearProgressIndicator(
                            value: 0.24,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.configDevice,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '1,2 GB von 5 GB verwendet (24%)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Cache clear button (destructive)
              OutlinedButton.icon(
                onPressed: () => _showClearCacheDialog(context),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Cache leeren'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error.withOpacity(0.5)),
                  minimumSize: const Size(
                    double.infinity,
                    AppSpacing.touchTargetMin,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache leeren?'),
        content: const Text(
          'Alle zwischengespeicherten Noten und Daten werden gelöscht. '
          'Du kannst sie bei Bedarf erneut herunterladen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache wurde geleert')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cache leeren'),
          ),
        ],
      ),
    );
  }
}
