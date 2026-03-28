import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/presentation/widgets/role_chip.dart';

/// Card displaying a [Band] summary for the list screen.
class BandCard extends StatelessWidget {
  const BandCard({
    super.key,
    required this.band,
    required this.onTap,
  });

  final Band band;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.roundedMd,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Logo placeholder
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppSpacing.roundedMd,
                ),
                child: band.logoUrl != null
                    ? ClipRRect(
                        borderRadius: AppSpacing.roundedMd,
                        child: Image.network(
                          band.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.groups_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.groups_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      band.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (band.location != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              band.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${band.memberCount} Mitglieder',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        ...band.myRoles.map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: RoleChip(role: r, small: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
