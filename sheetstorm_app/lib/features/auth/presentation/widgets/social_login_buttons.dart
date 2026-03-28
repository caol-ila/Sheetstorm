import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

/// Google button (all platforms) + Apple button (iOS/macOS only).
/// Spec: kein Fake-Apple-Button auf Android/Web.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.isLoading = false,
    this.label = 'anmelden',
  });

  final VoidCallback onGoogleTap;
  final VoidCallback onAppleTap;
  final bool isLoading;
  final String label;

  static bool get _showApple {
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false; // Web
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SocialButton(
          icon: _GoogleIcon(),
          label: 'Mit Google $label',
          onTap: isLoading ? null : onGoogleTap,
        ),
        if (_showApple) ...[
          const SizedBox(height: AppSpacing.sm),
          _SocialButton(
            icon: const Icon(Icons.apple, size: 20),
            label: 'Mit Apple $label',
            onTap: isLoading ? null : onAppleTap,
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: icon,
      label: Text(label),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
        textStyle: const TextStyle(
          fontSize: AppTypography.fontSizeBase,
          fontWeight: AppTypography.weightMedium,
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple "G" text icon as SVG is not bundled yet
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Color(0xFF4285F4),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
