import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/kapelle_notifier.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';
import 'package:sheetstorm/features/kapelle/presentation/widgets/role_chip.dart';

class KapelleDetailScreen extends ConsumerWidget {
  const KapelleDetailScreen({super.key, required this.kapelleId});

  final String kapelleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(kapelleListProvider);
    final theme = Theme.of(context);

    return listState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Kapelle')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Kapelle')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
      ),
      data: (kapellen) {
        final kapelle = kapellen
            .cast<Kapelle?>()
            .firstWhere((k) => k!.id == kapelleId, orElse: () => null);
        if (kapelle == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Kapelle')),
            body: const Center(child: Text('Kapelle nicht gefunden.')),
          );
        }
        return _DetailContent(kapelle: kapelle);
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.kapelle});

  final Kapelle kapelle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(kapelle.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Header
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppSpacing.roundedLg,
                ),
                child: kapelle.logoUrl != null
                    ? ClipRRect(
                        borderRadius: AppSpacing.roundedLg,
                        child: Image.network(
                          kapelle.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.groups_rounded,
                            size: 40,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.groups_rounded,
                        size: 40,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              kapelle.name,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (kapelle.ort != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    kapelle.ort!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (kapelle.beschreibung != null &&
                kapelle.beschreibung!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                kapelle.beschreibung!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            // Roles
            const SizedBox(height: AppSpacing.md),
            if (kapelle.meineRollen.isNotEmpty)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: kapelle.meineRollen
                    .map((r) => RoleChip(rolle: r))
                    .toList(),
              ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Mitglieder
            _SectionTile(
              icon: Icons.people_outline,
              title: 'Mitglieder',
              subtitle: '${kapelle.mitgliederAnzahl} Mitglieder',
              onTap: () =>
                  context.go(AppRoutes.kapelleMitglieder(kapelleId: kapelle.id)),
            ),

            // Register
            _SectionTile(
              icon: Icons.category_outlined,
              title: 'Register',
              subtitle: 'Stimmgruppen verwalten',
              onTap: () =>
                  context.go(AppRoutes.kapelleRegister(kapelleId: kapelle.id)),
            ),

            // Einladen (admin only)
            if (kapelle.isAdmin)
              _SectionTile(
                icon: Icons.person_add_outlined,
                title: 'Mitglieder einladen',
                subtitle: 'Per E-Mail oder Link',
                onTap: () =>
                    context.go(AppRoutes.kapelleEinladen(kapelleId: kapelle.id)),
              ),

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            const SizedBox(height: AppSpacing.md),

            // Kapelle verlassen
            OutlinedButton.icon(
              onPressed: () => _showLeaveDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
              ),
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Kapelle verlassen'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLeaveDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kapelle verlassen?'),
        content: Text(
          'Möchtest du "${kapelle.name}" wirklich verlassen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      final service = ref.read(kapelleServiceProvider);
      await service.leaveKapelle(kapelle.id);

      if (!context.mounted) return;

      await ref.read(kapelleListProvider.notifier).refresh();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapelle verlassen.')),
      );
      context.go(AppRoutes.kapelle);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Verlassen der Kapelle.'),
        ),
      );
    }
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
