import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/gema/application/gema_notifier.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';

class GemaExportScreen extends ConsumerWidget {
  const GemaExportScreen({
    required this.kapelleId,
    required this.reportId,
    super.key,
  });

  final String kapelleId;
  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportieren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Export-Format wählen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildFormatCard(
              context,
              ref,
              ExportFormat.xml,
              Icons.code,
              'GEMA-XML',
              'Offizielles GEMA-Format für elektronische Einreichung',
            ),
            _buildFormatCard(
              context,
              ref,
              ExportFormat.csv,
              Icons.table_chart,
              'CSV',
              'Tabelle für Excel oder andere Tabellenkalkulationen',
            ),
            _buildFormatCard(
              context,
              ref,
              ExportFormat.pdf,
              Icons.picture_as_pdf,
              'PDF',
              'Dokument zum Ausdrucken oder Archivieren',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _export(context, ref, format),
        borderRadius: AppSpacing.roundedMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    ExportFormat format,
  ) async {
    final notifier = ref.read(
      gemaReportDetailProvider(kapelleId, reportId).notifier,
    );

    final url = await notifier.exportReport(format);

    if (context.mounted) {
      if (url != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export erfolgreich: ${format.label}')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export fehlgeschlagen')),
        );
      }
    }
  }
}
