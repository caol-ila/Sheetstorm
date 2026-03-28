/// Undo toast for auto-save — Issue #35
///
/// Shows a snackbar-style toast with "Rückgängig" action for 5 seconds.

import 'package:flutter/material.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';

class UndoToast extends StatelessWidget {
  const UndoToast({
    super.key,
    required this.message,
    required this.onUndo,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onUndo;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Material(
        elevation: 4,
        borderRadius: AppSpacing.roundedMd,
        color: theme.colorScheme.inverseSurface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onUndo,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.inversePrimary,
                  minimumSize: const Size(
                    AppSpacing.touchTargetMin,
                    AppSpacing.touchTargetMin,
                  ),
                ),
                child: const Text(
                  'Rückgängig',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the undo toast as a SnackBar.
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: onUndo,
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedMd,
        ),
      ),
    );
  }
}
