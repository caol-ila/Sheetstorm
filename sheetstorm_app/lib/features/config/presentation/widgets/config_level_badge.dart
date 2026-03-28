/// Color-coded level badge widget — Issue #35
///
/// Shows a colored indicator (left border + icon + label) for the config level.
/// Accessibility: never color-only, always icon + text.

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';

class ConfigLevelBadge extends StatelessWidget {
  const ConfigLevelBadge({
    super.key,
    required this.level,
    this.compact = false,
  });

  final ConfigLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: AppSpacing.roundedSm,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 14 : 16, color: _color),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              level.description,
              style: TextStyle(
                fontSize: compact ? AppTypography.fontSizeXs : AppTypography.fontSizeSm,
                fontWeight: AppTypography.weightMedium,
                color: _color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _color {
    switch (level) {
      case ConfigLevel.band:
        return AppColors.configBand;
      case ConfigLevel.user:
        return AppColors.configUser;
      case ConfigLevel.device:
        return AppColors.configDevice;
    }
  }

  IconData get _icon {
    switch (level) {
      case ConfigLevel.band:
        return Icons.account_balance;
      case ConfigLevel.user:
        return Icons.person;
      case ConfigLevel.device:
        return Icons.phone_android;
    }
  }

  /// Helper to get the color for a given level (used across widgets).
  static Color colorFor(ConfigLevel level) {
    switch (level) {
      case ConfigLevel.band:
        return AppColors.configBand;
      case ConfigLevel.user:
        return AppColors.configUser;
      case ConfigLevel.device:
        return AppColors.configDevice;
    }
  }

  /// Helper to get the icon for a given level.
  static IconData iconFor(ConfigLevel level) {
    switch (level) {
      case ConfigLevel.band:
        return Icons.account_balance;
      case ConfigLevel.user:
        return Icons.person;
      case ConfigLevel.device:
        return Icons.phone_android;
    }
  }
}
