import 'package:flutter/material.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';

/// Chip that displays a [BandRole] with role-specific color.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role, this.small = false});

  final BandRole role;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(role);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.label,
        style: TextStyle(
          color: fg,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static (Color, Color) _colors(BandRole role) => switch (role) {
        BandRole.admin => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
        BandRole.conductor =>
          (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
        BandRole.sheetMusicManager =>
          (const Color(0xFFDBEAFE), const Color(0xFF1A56DB)),
        BandRole.sectionLeader =>
          (const Color(0xFFFFF7ED), const Color(0xFFD97706)),
        BandRole.sectionLeader =>
          (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
        BandRole.musician =>
          (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      };
}
