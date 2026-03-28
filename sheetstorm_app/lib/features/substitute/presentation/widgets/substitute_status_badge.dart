import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';

class SubstituteStatusBadge extends StatelessWidget {
  const SubstituteStatusBadge({super.key, required this.status});

  final SubstituteStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getStatusColor()),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case SubstituteStatus.active:
        return AppColors.success;
      case SubstituteStatus.expired:
        return AppColors.warning;
      case SubstituteStatus.revoked:
        return AppColors.error;
    }
  }
}
