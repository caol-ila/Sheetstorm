import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Password strength requirements & live indicator bar.
/// Shows Schwach (rot) / Mittel (orange) / Stark (grün).
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = _evaluate(password);

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        // Strength bar
        ClipRRect(
          borderRadius: AppSpacing.roundedFull,
          child: LinearProgressIndicator(
            value: strength.fraction,
            minHeight: 6,
            backgroundColor: AppColors.border,
            color: strength.color,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strength.label,
          style: TextStyle(
            fontSize: AppTypography.fontSizeXs,
            fontWeight: AppTypography.weightMedium,
            color: strength.color,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Checklist
        _CheckItem(label: 'Mindestens 8 Zeichen', met: password.length >= 8),
        _CheckItem(
          label: 'Mindestens ein Großbuchstabe',
          met: password.contains(RegExp(r'[A-Z]')),
        ),
        _CheckItem(
          label: 'Mindestens eine Zahl oder ein Sonderzeichen',
          met: password.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]')),
        ),
      ],
    );
  }

  static _PasswordStrength _evaluate(String pw) {
    if (pw.isEmpty) return _PasswordStrength.none;
    int score = 0;
    if (pw.length >= 8) score++;
    if (pw.contains(RegExp(r'[A-Z]'))) score++;
    if (pw.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'))) score++;
    return switch (score) {
      3 => _PasswordStrength.stark,
      2 => _PasswordStrength.mittel,
      _ => _PasswordStrength.schwach,
    };
  }

  /// True when all requirements are met.
  static bool isValid(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9!@#\$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'));
  }
}

enum _PasswordStrength {
  none(0, Colors.transparent, ''),
  schwach(0.33, AppColors.error, 'Schwach'),
  mittel(0.66, AppColors.warning, 'Mittel'),
  stark(1.0, AppColors.success, 'Stark');

  const _PasswordStrength(this.fraction, this.color, this.label);
  final double fraction;
  final Color color;
  final String label;
}

class _CheckItem extends StatelessWidget {
  const _CheckItem({required this.label, required this.met});
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: met ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.fontSizeXs,
              color: met ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
