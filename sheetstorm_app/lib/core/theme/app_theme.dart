import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: AppTypography.textTheme.apply(
        fontFamily: AppTypography.fontFamily,
        bodyColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        displayColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
        foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.background,
        indicatorColor: (isDark ? AppColors.darkPrimary : AppColors.primary).withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.fontSizeXs,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDark ? AppColors.darkTextPrimary : AppColors.textSecondary,
            size: 24,
          );
        }),
        // Enforce 44px minimum height (ux-design.md § 1.2)
        height: 64,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(AppSpacing.touchTargetMin, AppSpacing.touchTargetMin),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.fontSizeBase,
            fontWeight: AppTypography.weightMedium,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
          minimumSize: const Size(AppSpacing.touchTargetMin, AppSpacing.touchTargetMin),
          side: BorderSide(
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedMd,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedMd,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkPrimary : AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkSurface : AppColors.border,
        thickness: 1,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: Color(0xFFDCE8FF),
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onPrimary,
    secondaryContainer: Color(0xFFEDE9FE),
    onSecondaryContainer: Color(0xFF4C1D95),
    error: AppColors.error,
    onError: AppColors.onPrimary,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF991B1B),
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.border,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.border,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkBackground,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: AppColors.darkPrimary,
    secondary: Color(0xFFA78BFA),
    onSecondary: AppColors.darkBackground,
    secondaryContainer: Color(0xFF4C1D95),
    onSecondaryContainer: Color(0xFFA78BFA),
    error: Color(0xFFFCA5A5),
    onError: AppColors.darkBackground,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFCA5A5),
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkTextPrimary,
    surfaceContainerHighest: Color(0xFF1F2937),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF374151),
  );
}
