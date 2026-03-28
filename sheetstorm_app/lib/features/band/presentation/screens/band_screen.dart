import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/band/presentation/widgets/band_card.dart';

class BandScreen extends ConsumerWidget {
  const BandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(bandListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kapellen')),
      body: listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Fehler beim Laden', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () =>
                    ref.read(bandListProvider.notifier).refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (bands) {
          if (bands.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.groups_outlined,
                      size: 64,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Keine Kapellen',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Erstelle eine neue Kapelle oder tritt einer bei.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => context.go(AppRoutes.bandNew),
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppSpacing.touchTargetMin),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Neue Kapelle'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.bandJoin),
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppSpacing.touchTargetMin),
                      ),
                      icon: const Icon(Icons.group_add),
                      label: const Text('Kapelle beitreten'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(bandListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: 120,
              ),
              itemCount: bands.length,
              itemBuilder: (context, index) {
                final band = bands[index];
                return BandCard(
                  band: band,
                  onTap: () =>
                      context.go(AppRoutes.bandDetail(id: band.id)),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: listState.whenOrNull(
        data: (bands) => bands.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.bandNew),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                AppSpacing.touchTargetMin),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Neue Kapelle'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.go(AppRoutes.bandJoin),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                                AppSpacing.touchTargetMin),
                          ),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Beitreten'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
