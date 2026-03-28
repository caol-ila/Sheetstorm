import 'package:flutter/material.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';

/// Chip that displays a [KapelleRolle] with role-specific color.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.rolle, this.small = false});

  final KapelleRolle rolle;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(rolle);
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
        rolle.label,
        style: TextStyle(
          color: fg,
          fontSize: small ? 10 : 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static (Color, Color) _colors(KapelleRolle rolle) => switch (rolle) {
        KapelleRolle.admin => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
        KapelleRolle.dirigent =>
          (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
        KapelleRolle.notenwart =>
          (const Color(0xFFDBEAFE), const Color(0xFF1A56DB)),
        KapelleRolle.registerfuehrer =>
          (const Color(0xFFFFF7ED), const Color(0xFFD97706)),
        KapelleRolle.musiker =>
          (const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      };
}
