import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pingAsync = ref.watch(pingProvider);
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.appTitle),
          ),
          body: _buildBody(context, l10n, pingAsync),
          bottomNavigationBar: isWide ? null : _buildBottomNav(l10n),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<String> pingAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        final content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.helloBand,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              pingAsync.when(
                data: (message) => Text(
                  'Backend: $message',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text(
                  'Error: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            children: [
              _buildNavigationRail(l10n),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: content),
            ],
          );
        }

        return content;
      },
    );
  }

  Widget _buildNavigationRail(AppLocalizations l10n) {
    return NavigationRail(
      selectedIndex: 0,
      labelType: NavigationRailLabelType.all,
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: Text(l10n.homeNavLabel),
        ),
      ],
      onDestinationSelected: (index) {},
    );
  }

  Widget _buildBottomNav(AppLocalizations l10n) {
    return NavigationBar(
      selectedIndex: 0,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: l10n.homeNavLabel,
        ),
      ],
      onDestinationSelected: (index) {},
    );
  }
}
