import 'package:flutter/material.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

/// Color matrix filter for night/sepia display modes (AC-30..AC-36).
///
/// Night mode: inverted colors with controlled rendering — not a simple CSS invert.
/// Sepia mode: warm paper-like tone for eye comfort during long rehearsals.
class NightModeFilter extends StatelessWidget {
  const NightModeFilter({
    super.key,
    required this.colorMode,
    required this.brightness,
    required this.child,
  });

  final ColorMode colorMode;

  /// Brightness: 0.6–1.0 (AC-34)
  final double brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (colorMode == ColorMode.standard && brightness >= 1.0) {
      return child;
    }

    return ColorFiltered(
      colorFilter: _buildColorFilter(),
      child: child,
    );
  }

  ColorFilter _buildColorFilter() {
    return switch (colorMode) {
      ColorMode.standard => ColorFilter.matrix(_brightnessMatrix(brightness)),
      ColorMode.night => ColorFilter.matrix(_nightModeMatrix(brightness)),
      ColorMode.sepia => ColorFilter.matrix(_sepiaMatrix(brightness)),
    };
  }

  /// Night mode: invert with controlled brightness (AC-30)
  static List<double> _nightModeMatrix(double brightness) {
    final b = brightness;
    return [
      -b, 0, 0, 0, 255 * b, //
      0, -b, 0, 0, 255 * b, //
      0, 0, -b, 0, 255 * b, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// Sepia mode: warm yellow-brown tone (AC-33)
  static List<double> _sepiaMatrix(double brightness) {
    final b = brightness;
    return [
      0.393 * b, 0.769 * b, 0.189 * b, 0, 0, //
      0.349 * b, 0.686 * b, 0.168 * b, 0, 0, //
      0.272 * b, 0.534 * b, 0.131 * b, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// Simple brightness adjustment
  static List<double> _brightnessMatrix(double brightness) {
    return [
      brightness, 0, 0, 0, 0, //
      0, brightness, 0, 0, 0, //
      0, 0, brightness, 0, 0, //
      0, 0, 0, 1, 0, //
    ];
  }
}
