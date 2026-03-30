import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/presentation/widgets/role_chip.dart';

/// List tile for a member, showing avatar, name, role and optional admin actions.
class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.member,
    this.isAdmin = false,
    this.onEditRoles,
    this.onRemove,
  });

  final Member member;
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
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(member.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (member.instrument != null)
            Text(
              member.instrument!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.xs),
          RoleChip(role: member.role, small: true),
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
