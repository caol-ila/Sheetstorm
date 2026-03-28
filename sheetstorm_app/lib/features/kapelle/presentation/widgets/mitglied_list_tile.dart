import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/presentation/widgets/role_chip.dart';

/// List tile for a member, showing avatar, name, roles and optional admin actions.
class MitgliedListTile extends StatelessWidget {
  const MitgliedListTile({
    super.key,
    required this.mitglied,
    this.isAdmin = false,
    this.onEditRoles,
    this.onRemove,
  });

  final Mitglied mitglied;
  final bool isAdmin;
  final VoidCallback? onEditRoles;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: mitglied.avatarUrl != null
            ? NetworkImage(mitglied.avatarUrl!)
            : null,
        child: mitglied.avatarUrl == null
            ? Text(
                mitglied.name.isNotEmpty ? mitglied.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Text(mitglied.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mitglied.register.isNotEmpty)
            Text(
              mitglied.register.join(', '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: mitglied.rollen
                .map((r) => RoleChip(rolle: r, small: true))
                .toList(),
          ),
        ],
      ),
      trailing: isAdmin
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Rollen bearbeiten',
                  onPressed: onEditRoles,
                ),
                IconButton(
                  icon: Icon(
                    Icons.person_remove_outlined,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Entfernen',
                  onPressed: onRemove,
                ),
              ],
            )
          : null,
    );
  }
}
