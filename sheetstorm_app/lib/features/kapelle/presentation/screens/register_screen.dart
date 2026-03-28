import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/application/kapelle_notifier.dart';
import 'package:sheetstorm/features/kapelle/application/register_notifier.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';

class KapelleRegisterScreen extends ConsumerWidget {
  const KapelleRegisterScreen({super.key, required this.kapelleId});

  final String kapelleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerProvider(kapelleId));
    final canManage = _canManage(ref);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => _showCreateDialog(context, ref),
              tooltip: 'Register erstellen',
              child: const Icon(Icons.add),
            )
          : null,
      body: registerState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Fehler beim Laden', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () => ref
                    .read(registerProvider(kapelleId).notifier)
                    .refresh(),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (registers) {
          if (registers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Noch keine Register',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Erstelle Stimmgruppen für die Kapelle.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref
                .read(registerProvider(kapelleId).notifier)
                .refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: registers.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final register = registers[index];
                return _RegisterCard(
                  register: register,
                  canManage: canManage,
                  onEdit: canManage
                      ? () => _showEditDialog(context, ref, register)
                      : null,
                  onDelete: canManage
                      ? () => _confirmDelete(context, ref, register)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _canManage(WidgetRef ref) {
    final listState = ref.watch(kapelleListProvider);
    return listState.whenOrNull(
          data: (kapellen) =>
              kapellen
                  .cast<Kapelle?>()
                  .firstWhere((k) => k!.id == kapelleId, orElse: () => null)
                  ?.isDirigentOrAdmin ??
              false,
        ) ??
        false;
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final beschreibungController = TextEditingController();
    final farbeController = TextEditingController(text: '#4A90D9');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register erstellen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: farbeController,
                decoration: const InputDecoration(
                  labelText: 'Farbe (Hex)',
                  hintText: '#4A90D9',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    nameController.dispose();
    beschreibungController.dispose();

    final beschreibung = beschreibungController.text.trim();
    final farbe = farbeController.text.trim();
    farbeController.dispose();

    final result =
        await ref.read(registerProvider(kapelleId).notifier).create(
              name: name,
              beschreibung: beschreibung.isNotEmpty ? beschreibung : null,
              farbe: farbe.isNotEmpty ? farbe : null,
            );

    if (!context.mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register konnte nicht erstellt werden.'),
        ),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    Register register,
  ) async {
    final nameController = TextEditingController(text: register.name);
    final beschreibungController =
        TextEditingController(text: register.beschreibung ?? '');
    final farbeController =
        TextEditingController(text: register.farbe ?? '#4A90D9');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register bearbeiten'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: beschreibungController,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: farbeController,
                decoration: const InputDecoration(
                  labelText: 'Farbe (Hex)',
                  hintText: '#4A90D9',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) return;

    nameController.dispose();
    final beschreibung = beschreibungController.text.trim();
    beschreibungController.dispose();
    final farbe = farbeController.text.trim();
    farbeController.dispose();

    final success =
        await ref.read(registerProvider(kapelleId).notifier).updateRegister(
              registerId: register.id,
              name: name,
              beschreibung: beschreibung.isNotEmpty ? beschreibung : null,
              farbe: farbe.isNotEmpty ? farbe : null,
            );

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register konnte nicht aktualisiert werden.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Register register,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Register löschen?'),
        content: Text(
          'Möchtest du "${register.name}" wirklich löschen?',
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final success = await ref
        .read(registerProvider(kapelleId).notifier)
        .delete(register.id);

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Register konnte nicht gelöscht werden.'),
        ),
      );
    }
  }
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({
    required this.register,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  final Register register;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(register.farbe);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppSpacing.roundedSm,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    register.name,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (register.beschreibung != null &&
                      register.beschreibung!.isNotEmpty)
                    Text(
                      register.beschreibung!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (canManage) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Bearbeiten',
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Löschen',
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.length < 7) return const Color(0xFF4A90D9);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF4A90D9);
    }
  }
}
