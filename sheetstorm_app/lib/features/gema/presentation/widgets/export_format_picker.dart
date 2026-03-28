import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/gema/data/models/gema_models.dart';

class ExportFormatPicker extends StatelessWidget {
  const ExportFormatPicker({
    required this.onFormatSelected,
    super.key,
  });

  final void Function(ExportFormat format) onFormatSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Export-Format wählen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildFormatTile(
          context,
          ExportFormat.xml,
          Icons.code,
          'GEMA-XML',
          'Offizielles Format für elektronische Einreichung',
        ),
        _buildFormatTile(
          context,
          ExportFormat.csv,
          Icons.table_chart,
          'CSV',
          'Tabelle für Excel',
        ),
        _buildFormatTile(
          context,
          ExportFormat.pdf,
          Icons.picture_as_pdf,
          'PDF',
          'Dokument zum Ausdrucken',
        ),
      ],
    );
  }

  Widget _buildFormatTile(
    BuildContext context,
    ExportFormat format,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => onFormatSelected(format),
      ),
    );
  }
}
