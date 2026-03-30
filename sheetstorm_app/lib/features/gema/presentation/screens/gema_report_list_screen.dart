import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/gema/application/gema_notifier.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';
import 'package:sheetstorm/features/gema/presentation/widgets/gema_report_card.dart';

class GemaReportListScreen extends ConsumerWidget {
  const GemaReportListScreen({required this.kapelleId, super.key});

  final String kapelleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(gemaReportListProvider(kapelleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('GEMA-Meldungen'),
      ),
      body: reportsAsync.when(
        data: (reports) {
          if (reports.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(gemaReportListProvider(kapelleId).notifier)
                  .refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: reports.length,
              itemBuilder: (context, index) => GemaReportCard(
                report: reports[index],
                onTap: () => _navigateToDetail(context, reports[index].id),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Fehler: $err'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreate(context),
        icon: const Icon(Icons.add),
        label: const Text('Neue Meldung'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Noch keine GEMA-Meldungen erstellt',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Erstelle eine Meldung aus einer Setlist',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, String reportId) {
    // Navigate to detail screen (implementation depends on routing)
    // Navigator.of(context).pushNamed('/gema/$reportId');
  }

  void _navigateToCreate(BuildContext context) {
    // Navigate to create screen
    // Navigator.of(context).pushNamed('/gema/new');
  }
}
