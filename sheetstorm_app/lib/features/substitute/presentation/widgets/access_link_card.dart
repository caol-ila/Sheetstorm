import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';
import 'package:sheetstorm/features/substitute/presentation/widgets/substitute_status_badge.dart';

class AccessLinkCard extends StatelessWidget {
  const AccessLinkCard({
    super.key,
    required this.access,
    required this.onRevoke,
    required this.onExtend,
    required this.onShowQR,
  });

  final SubstituteAccess access;
  final VoidCallback onRevoke;
  final VoidCallback onExtend;
  final VoidCallback onShowQR;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor().withOpacity(0.2),
          child: Icon(
            Icons.person,
            color: _getStatusColor(),
          ),
        ),
        title: Text(access.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${access.instrument} (${access.voice})'),
            const SizedBox(height: 4),
            Row(
              children: [
                SubstituteStatusBadge(status: access.status),
                const SizedBox(width: 8),
                Text(
                  'Gültig bis: ${_formatDate(access.expiresAt)}',
                  style: const TextStyle(fontSize: AppTypography.fontSizeXs),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'qr',
              child: Row(
                children: [
                  Icon(Icons.qr_code),
                  SizedBox(width: AppSpacing.sm),
                  Text('QR-Code anzeigen'),
                ],
              ),
            ),
            if (access.isActive) ...[
              const PopupMenuItem(
                value: 'extend',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: AppSpacing.sm),
                    Text('Verlängern'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'revoke',
                child: Row(
                  children: [
                    Icon(Icons.block, color: AppColors.error),
                    SizedBox(width: AppSpacing.sm),
                    Text('Widerrufen', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ],
          onSelected: (value) {
            switch (value) {
              case 'qr':
                onShowQR();
                break;
              case 'extend':
                onExtend();
                break;
              case 'revoke':
                onRevoke();
                break;
            }
          },
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (access.status) {
      case SubstituteStatus.active:
        return AppColors.success;
      case SubstituteStatus.expired:
        return AppColors.warning;
      case SubstituteStatus.revoked:
        return AppColors.error;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
