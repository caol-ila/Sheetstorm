import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/kapelle_notifier.dart';
import 'package:sheetstorm/features/kapelle/presentation/widgets/kapelle_card.dart';

class KapelleScreen extends ConsumerWidget {
  const KapelleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(kapelleListProvider);
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
                    ref.read(kapelleListProvider.notifier).refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (kapellen) {
          if (kapellen.isEmpty) {
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
                      onPressed: () => context.go(AppRoutes.kapelleNeu),
                      style: FilledButton.styleFrom(
                        minimumSize:
                            const Size.fromHeight(AppSpacing.touchTargetMin),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Neue Kapelle'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.kapelleBeitreten),
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
                ref.read(kapelleListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: 120,
              ),
              itemCount: kapellen.length,
              itemBuilder: (context, index) {
                final kapelle = kapellen[index];
                return KapelleCard(
                  kapelle: kapelle,
                  onTap: () =>
                      context.go(AppRoutes.kapelleDetail(id: kapelle.id)),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: listState.whenOrNull(
        data: (kapellen) => kapellen.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.kapelleNeu),
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
                              context.go(AppRoutes.kapelleBeitreten),
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
