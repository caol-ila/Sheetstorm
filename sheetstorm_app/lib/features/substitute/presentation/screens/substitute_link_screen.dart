import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';

class SubstituteLinkScreen extends StatelessWidget {
  const SubstituteLinkScreen({super.key, required this.link});

  final SubstituteLink link;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aushilfen-Zugang'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 64, color: AppColors.success),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Zugang erstellt!',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      link.access.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${link.access.instrument} (${link.access.voice})',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zugangslink',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: AppSpacing.roundedMd,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: SelectableText(
                        link.link,
                        style: const TextStyle(fontSize: AppTypography.fontSizeSm),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: link.link));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Link kopiert'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Kopieren'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Share functionality
                              // share_plus package would be used here
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Teilen'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Text(
                      'QR-Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      width: 200,
                      height: 200,
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          'QR-Code\n(Implementierung: qr_flutter)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'QR-Code scannen um den Link zu öffnen',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      'Gültig bis',
                      _formatDate(link.access.expiresAt),
                    ),
                    if (link.access.eventName != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        context,
                        'Termin',
                        link.access.eventName!,
                      ),
                    ],
                    if (link.access.note != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        context,
                        'Notiz',
                        link.access.note!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
