import 'package:go_router/go_router.dart';

/// Route constants for the cloud sync feature.
///
/// Cloud sync UI is widget-based (SyncStatusIndicator, SyncConflictDialog)
/// and does not have dedicated full screens. This stub exists for consistency.
abstract final class CloudSyncRoutes {
  // No dedicated routes — sync UI is embedded in other screens via widgets.
}

/// GoRoute definitions for cloud sync.
/// Currently empty — sync UI is injected as widgets, not standalone screens.
final cloudSyncRoutes = <GoRoute>[];
