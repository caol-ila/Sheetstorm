import 'package:flutter/material.dart';

/// Design tokens from ux-design.md § 7
abstract final class AppColors {
  // ─── Light Mode ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF5F5F5);
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1040A8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFF7C3AED);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // ─── Dark Mode ───────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkPrimary = Color(0xFF60A5FA);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkNoteInk = Color(0xFFE5E7EB);

  // ─── Config Level Colors (3-Ebenen-System) ───────────────────────────────────
  /// Kapelle-Einstellung (blau)
  static const Color configKapelle = Color(0xFF1A56DB);

  /// Nutzer-Einstellung (grün)
  static const Color configNutzer = Color(0xFF16A34A);

  /// Gerät-Einstellung (orange)
  static const Color configGerat = Color(0xFFD97706);

  // ─── Annotation Layer Colors ─────────────────────────────────────────────────
  static const Color annotationPrivate = Color(0xFF16A34A);
  static const Color annotationStimme = Color(0xFF1A56DB);
  static const Color annotationOrchester = Color(0xFFD97706);
}
