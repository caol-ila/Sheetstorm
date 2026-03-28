/// Settings search widget — Issue #35
///
/// Fuzzy search across all setting names with breadcrumb navigation.
/// Reference: docs/ux-specs/konfiguration.md § 2.3

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/config/domain/config_keys.dart';
import 'package:sheetstorm/features/config/domain/config_models.dart';
import 'package:sheetstorm/features/config/presentation/widgets/config_level_badge.dart';

class ConfigSearchDelegate extends SearchDelegate<String?> {
  ConfigSearchDelegate();

  @override
  String get searchFieldLabel => 'Einstellungen suchen…';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
          tooltip: 'Suche leeren',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
      tooltip: 'Zurück',
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Einstellung suchen',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final lowerQuery = query.toLowerCase();
    final results = ConfigKeys.allKeys.where((key) {
      return key.label.toLowerCase().contains(lowerQuery) ||
          key.schluessel.toLowerCase().contains(lowerQuery) ||
          key.kategorie.toLowerCase().contains(lowerQuery) ||
          (key.beschreibung?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Keine Ergebnisse für "$query"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final keyDef = results[index];
        final color = ConfigLevelBadge.colorFor(keyDef.ebene);

        return ListTile(
          leading: Icon(
            ConfigLevelBadge.iconFor(keyDef.ebene),
            color: color,
          ),
          title: Text(keyDef.label),
          subtitle: Text(
            '${keyDef.ebene.label} → ${keyDef.kategorie}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          trailing: ConfigLevelBadge(ebene: keyDef.ebene, compact: true),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          minVerticalPadding: AppSpacing.sm,
          onTap: () {
            close(context, keyDef.schluessel);
          },
        );
      },
    );
  }
}
