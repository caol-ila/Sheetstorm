import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/cloud_sync/data/models/sync_models.dart';

/// Badge widget showing the current cloud-sync status.
///
/// Used in AppBar or list tiles. Respects min touch target via [size].
class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.size = 20.0,
  });

  final SyncStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: _buildIcon(context),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    switch (status) {
      case SyncStatus.syncing:
        return const CircularProgressIndicator(
          strokeWidth: 2.0,
          color: AppColors.primary,
        );
      case SyncStatus.synced:
        return Icon(Icons.cloud_done, size: size, color: AppColors.success);
      case SyncStatus.conflict:
        return Icon(Icons.warning_amber, size: size, color: AppColors.warning);
      case SyncStatus.offline:
        return Icon(Icons.cloud_off, size: size, color: AppColors.textSecondary);
      case SyncStatus.error:
        return Icon(Icons.error_outline, size: size, color: AppColors.error);
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_outlined,
          size: size,
          color: AppColors.textSecondary,
        );
    }
  }

  String get _semanticLabel => switch (status) {
        SyncStatus.syncing => 'Synchronisierung läuft',
        SyncStatus.synced => 'Synchronisiert',
        SyncStatus.conflict => 'Synchronisierungskonflikt',
        SyncStatus.offline => 'Offline',
        SyncStatus.error => 'Synchronisierungsfehler',
        SyncStatus.idle => 'Bereit zur Synchronisierung',
      };
}
