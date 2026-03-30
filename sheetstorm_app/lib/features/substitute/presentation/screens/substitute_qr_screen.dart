import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/substitute/application/substitute_notifier.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';

/// Zeigt den QR-Code für einen bestehenden Aushilfen-Zugang.
///
/// Route: /app/band/:bandId/substitute/qr/:accessId
/// Der accessId wird als Pfadparameter übergeben (kein state.extra).
class SubstituteQrScreen extends ConsumerWidget {
  const SubstituteQrScreen({
    super.key,
    required this.bandId,
    required this.accessId,
  });

  final String bandId;
  final String accessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessListAsync = ref.watch(substituteListProvider(bandId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR-Code'),
      ),
      body: accessListAsync.when(
        data: (list) {
          final SubstituteAccess? access = list
              .where((a) => a.id == accessId)
              .cast<SubstituteAccess?>()
              .firstOrNull;

          if (access == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Zugang nicht gefunden',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Text(
                          access.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${access.instrument} (${access.voice})',
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
                          'QR-Code scannen um den Aushilfen-Zugang zu öffnen',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Gültig bis: ${_formatDate(access.expiresAt)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}.${date.month}.${date.year}';
}
