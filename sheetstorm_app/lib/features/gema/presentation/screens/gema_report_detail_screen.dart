import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/gema/application/gema_notifier.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';

class GemaReportDetailScreen extends ConsumerWidget {
  const GemaReportDetailScreen({
    required this.kapelleId,
    required this.reportId,
    super.key,
  });

  final String kapelleId;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      gemaReportDetailProvider(kapelleId, reportId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('GEMA-Meldung'),
        actions: [
          IconButton(
            onPressed: () => _showExportDialog(context, ref),
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportieren',
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildContent(context, ref, report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, GemaReport report) {
    final canEdit = report.status == GemaReportStatus.entwurf;

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(gemaReportDetailProvider(kapelleId, reportId).notifier)
            .refresh();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(context, report.status),
            const SizedBox(height: AppSpacing.md),
            _buildEventCard(context, report),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Werke (${report.eintraege.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (report.fehlendeWerknummern > 0)
                  Chip(
                    label: Text('${report.fehlendeWerknummern} ohne Werknummer'),
                    backgroundColor: Colors.orange.shade100,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (canEdit && report.fehlendeWerknummern > 0)
              ElevatedButton.icon(
                onPressed: () => _searchAllWerknummern(context, ref),
                icon: const Icon(Icons.search),
                label: const Text('Alle Werknummern suchen'),
              ),
            const SizedBox(height: AppSpacing.md),
            ...report.eintraege.map((entry) => _buildEntryCard(
                  context,
                  ref,
                  entry,
                  canEdit,
                )),
            if (canEdit) ...[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _addEntry(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Werk hinzufügen'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GemaReportStatus status) {
    final color = status == GemaReportStatus.entwurf
        ? Colors.orange
        : Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == GemaReportStatus.entwurf
                ? Icons.edit_outlined
                : Icons.check_circle_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, GemaReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.veranstaltungName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              Icons.calendar_today,
              DateFormat('dd.MM.yyyy').format(report.veranstaltungDatum),
            ),
            _buildInfoRow(Icons.location_on, report.veranstaltungOrt),
            _buildInfoRow(Icons.category, report.veranstaltungArt),
            _buildInfoRow(Icons.business, report.veranstalter),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: AppSpacing.sm),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    WidgetRef ref,
    GemaEntry entry,
    bool canEdit,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(entry.werktitel),
        subtitle: Text(entry.komponist),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.gemaWerknummer != null)
              Chip(
                label: Text(entry.gemaWerknummer!),
                backgroundColor: Colors.green.shade100,
              )
            else if (canEdit)
              IconButton(
                onPressed: () => _searchWerknummer(context, ref, entry.id),
                icon: const Icon(Icons.search),
                tooltip: 'Werknummer suchen',
              ),
            if (canEdit) ...[
              IconButton(
                onPressed: () => _editEntry(context, ref, entry),
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: () => _deleteEntry(context, ref, entry.id),
                icon: const Icon(Icons.delete),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _searchWerknummer(
    BuildContext context,
    WidgetRef ref,
    String entryId,
  ) async {
    // Show search dialog (implementation)
  }

  Future<void> _searchAllWerknummern(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Bulk search for all missing werk numbers
  }

  Future<void> _addEntry(BuildContext context, WidgetRef ref) async {
    // Show add entry dialog
  }

  Future<void> _editEntry(
    BuildContext context,
    WidgetRef ref,
    GemaEntry entry,
  ) async {
    // Show edit dialog
  }

  Future<void> _deleteEntry(
    BuildContext context,
    WidgetRef ref,
    String entryId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Werk entfernen'),
        content: const Text('Möchtest du dieses Werk wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(
        gemaReportDetailProvider(kapelleId, reportId).notifier,
      );
      await notifier.deleteEntry(entryId);
    }
  }

  Future<void> _showExportDialog(BuildContext context, WidgetRef ref) async {
    // Show export format selection dialog
  }
}
