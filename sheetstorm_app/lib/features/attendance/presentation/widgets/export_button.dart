import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

class ExportButton extends StatelessWidget {
  const ExportButton({super.key, required this.onExport});

  final Function(String format) onExport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.upload),
      onSelected: onExport,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.table_chart),
              SizedBox(width: AppSpacing.sm),
              Text('CSV exportieren'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf),
              SizedBox(width: AppSpacing.sm),
              Text('PDF exportieren'),
            ],
          ),
        ),
      ],
    );
  }
}
