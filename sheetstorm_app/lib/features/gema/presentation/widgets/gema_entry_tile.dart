import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';

class GemaEntryTile extends StatelessWidget {
  const GemaEntryTile({
    required this.entry,
    this.onTap,
    this.onSearchWerknummer,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final GemaEntry entry;
  final VoidCallback? onTap;
  final VoidCallback? onSearchWerknummer;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.werktitel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          entry.komponist,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (entry.gemaWerknummer != null)
                    Chip(
                      label: Text(entry.gemaWerknummer!),
                      backgroundColor: Colors.green.shade100,
                    )
                  else if (onSearchWerknummer != null)
                    IconButton(
                      onPressed: onSearchWerknummer,
                      icon: const Icon(Icons.search),
                      tooltip: 'Werknummer suchen',
                    ),
                ],
              ),
              if (entry.verlag != null || entry.bearbeiter != null) ...[
                const SizedBox(height: AppSpacing.sm),
                if (entry.verlag != null)
                  Text(
                    'Verlag: ${entry.verlag}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (entry.bearbeiter != null)
                  Text(
                    'Bearbeiter: ${entry.bearbeiter}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
              if (onEdit != null || onDelete != null) ...[
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Bearbeiten'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Entfernen'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
