import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';

class OpenShiftsBadge extends StatelessWidget {
  const OpenShiftsBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.volunteer_activism, size: 14, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            '$count ${count == 1 ? 'Platz' : 'Plätze'} frei',
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
