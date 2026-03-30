import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

class QRCodeGenerator extends StatelessWidget {
  const QRCodeGenerator({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    // This is a placeholder. In production, use qr_flutter package:
    // QrImageView(data: data, size: 200, backgroundColor: Colors.white)
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppSpacing.roundedMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'QR-Code\n(qr_flutter)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
