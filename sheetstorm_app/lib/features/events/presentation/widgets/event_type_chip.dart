import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';

class EventTypeChip extends StatelessWidget {
  const EventTypeChip({
    required this.type,
    this.size = ChipSize.medium,
    super.key,
  });

  final EventType type;
  final ChipSize size;

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (type) {
      EventType.probe => (Icons.music_note, 'Probe', AppColors.primary),
      EventType.konzert => (Icons.music_note_outlined, 'Konzert', AppColors.error),
      EventType.auftritt => (Icons.campaign, 'Auftritt', AppColors.warning),
      EventType.ausflug => (Icons.directions_bus, 'Ausflug', AppColors.secondary),
      EventType.sonstiges => (Icons.event, 'Sonstiges', AppColors.textSecondary),
    };

    final iconSize = switch (size) {
      ChipSize.small => 14.0,
      ChipSize.medium => 16.0,
      ChipSize.large => 20.0,
    };

    final fontSize = switch (size) {
      ChipSize.small => 11.0,
      ChipSize.medium => 12.0,
      ChipSize.large => 14.0,
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size == ChipSize.small ? 6 : 8,
        vertical: size == ChipSize.small ? 2 : 4,
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

enum ChipSize {
  small,
  medium,
  large,
}
