/// Main settings hub — tabbed: Kapelle / Persönlich / Gerät — Issue #35
///
/// Entry point for the 3-level configuration system.
/// Kapelle tab only visible for admins.
/// Reference: docs/ux-specs/konfiguration.md § 2

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/application/config_notifier.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/screens/device_settings_screen.dart';
import 'package:sheetstorm/features/config/presentation/screens/band_settings_screen.dart';
import 'package:sheetstorm/features/config/presentation/screens/user_settings_screen.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_search.dart';
import 'package:sheetstorm/features/config/presentation/widgets/undo_toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.isAdmin = false});

  final bool isAdmin;

  @override
  ConsumerState<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isAdmin ? 3 : 2,
      vsync: this,
      initialIndex: widget.isAdmin ? 1 : 0,
    );

    // Initialize config on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configNotifierProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(configNotifierProvider);

    // Listen for undo actions
    ref.listen<ConfigState>(configNotifierProvider, (prev, next) {
      if (next.pendingUndo != null && prev?.pendingUndo != next.pendingUndo) {
        _showUndoToast(next.pendingUndo!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Einstellungen suchen',
            onPressed: () => _openSearch(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (widget.isAdmin)
              Tab(
                icon: Icon(Icons.account_balance, size: 20),
                text: 'Kapelle',
              ),
            const Tab(
              icon: Icon(Icons.person, size: 20),
              text: 'Persönlich',
            ),
            const Tab(
              icon: Icon(Icons.phone_android, size: 20),
              text: 'Gerät',
            ),
          ],
          indicatorColor: _activeTabColor,
          labelColor: _activeTabColor,
          unselectedLabelColor:
              Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      body: configState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : configState.error != null
              ? _buildErrorView(context, configState.error!)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    if (widget.isAdmin)
                      const BandSettingsScreen(),
                    const UserSettingsScreen(),
                    const DeviceSettingsScreen(),
                  ],
                ),
    );
  }

  Color get _activeTabColor {
    final index = _tabController.index;
    if (widget.isAdmin) {
      switch (index) {
        case 0:
          return AppColors.configBand;
        case 1:
          return AppColors.configUser;
        case 2:
          return AppColors.configDevice;
        default:
          return AppColors.primary;
      }
    } else {
      switch (index) {
        case 0:
          return AppColors.configUser;
        case 1:
          return AppColors.configDevice;
        default:
          return AppColors.primary;
      }
    }
  }

  void _showUndoToast(ConfigUndoAction action) {
    final keyLabel = action.key.split('.').last;
    UndoToast.show(
      context,
      message: '$keyLabel geändert',
      onUndo: () {
        ref.read(configNotifierProvider.notifier).undo();
      },
    );
  }

  void _openSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: ConfigSearchDelegate(),
    );
  }

  Widget _buildErrorView(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(error, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () {
              ref.read(configNotifierProvider.notifier).initialize();
            },
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
