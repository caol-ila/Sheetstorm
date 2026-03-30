import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

class RsvpStatusBadge extends StatelessWidget {
  const RsvpStatusBadge({
    required this.status,
    this.size = BadgeSize.medium,
    super.key,
  });

  final RsvpStatus status;
  final BadgeSize size;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (status) {
      RsvpStatus.zugesagt => (Icons.check_circle, 'Zugesagt', AppColors.success),
      RsvpStatus.abgesagt => (Icons.cancel, 'Abgesagt', AppColors.error),
      RsvpStatus.unsicher => (Icons.help, 'Unsicher', AppColors.warning),
      RsvpStatus.offen => (Icons.circle_outlined, 'Offen', AppColors.textSecondary),
    };

    final iconSize = switch (size) {
      BadgeSize.small => 14.0,
      BadgeSize.medium => 16.0,
      BadgeSize.large => 20.0,
    };

    final fontSize = switch (size) {
      BadgeSize.small => 11.0,
      BadgeSize.medium => 12.0,
      BadgeSize.large => 14.0,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == BadgeSize.small ? 6 : 8,
        vertical: size == BadgeSize.small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

enum BadgeSize {
  small,
  medium,
  large,
}
