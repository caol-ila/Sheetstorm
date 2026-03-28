import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';

/// Design tokens from ux-design.md § 7.3
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // Touch targets (ux-design.md § 1.2 — "nie kleiner als 44×44px")
  static const double touchTargetMin = 44.0;
  static const double touchTargetPlay = 64.0;
  static const double touchTargetZuAbsage = 64.0;

  // Border radius (ux-design.md § 7.3)
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 16.0;
  static const double radiusFull = 9999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));
}

/// Design tokens from ux-design.md § 7.2
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 20.0;
  static const double fontSizeXl = 28.0;
  static const double fontSize2xl = 48.0;
  static const double fontSize3xl = 72.0;

  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightBold = FontWeight.w700;

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: fontSize3xl, fontWeight: weightBold),
    displayMedium: TextStyle(fontSize: fontSize2xl, fontWeight: weightBold),
    displaySmall: TextStyle(fontSize: fontSizeXl, fontWeight: weightBold),
    headlineMedium: TextStyle(fontSize: fontSizeLg, fontWeight: weightBold),
    titleMedium: TextStyle(fontSize: fontSizeBase, fontWeight: weightMedium),
    bodyLarge: TextStyle(fontSize: fontSizeBase, fontWeight: weightNormal),
    bodyMedium: TextStyle(fontSize: fontSizeSm, fontWeight: weightNormal),
    labelSmall: TextStyle(fontSize: fontSizeXs, fontWeight: weightMedium),
  );
}

/// Design tokens from ux-design.md § 7.4
abstract final class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 4)),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 15, offset: Offset(0, 10)),
  ];
}

/// Design tokens from ux-design.md § 7.5
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

abstract final class AppCurves {
  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
}
