import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';

/// Shown after registration when e-mail is not yet verified.
///
/// Two entry points:
/// 1. Normal flow: `/email-verify` — user is prompted to check inbox.
/// 2. Deep-link: `/email-verify/:token` — [verificationToken] is set and
///    verification is triggered automatically on init.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, this.verificationToken});

  final String? verificationToken;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.verificationToken != null) {
      // Deep-link: auto-verify as soon as the widget is mounted
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(authProvider.notifier)
            .verifyEmail(widget.verificationToken!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAuthenticated) {
        // Verification succeeded — proceed to onboarding or app
        if (next.user.onboardingCompleted) {
          context.go(AppRoutes.bibliothek);
        } else {
          context.go(AppRoutes.onboarding);
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final authState = ref.watch(authProvider);
    final email = authState is AuthEmailPendingVerification
        ? authState.email
        : null;
    final isAutoVerifying =
        widget.verificationToken != null && authState is AuthLoading;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isAutoVerifying
                    ? Icons.hourglass_top_rounded
                    : Icons.mark_email_unread_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                isAutoVerifying
                    ? 'E-Mail wird bestätigt…'
                    : 'Bitte bestätige deine E-Mail',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (isAutoVerifying)
                const Center(child: CircularProgressIndicator())
              else ...[
                if (email != null) ...[
                  Text(
                    'Wir haben eine Bestätigungs-E-Mail an',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: AppTypography.weightMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'gesendet. Klicke auf den Link in der E-Mail, '
                    'um dein Konto zu aktivieren.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  Text(
                    'Klicke auf den Bestätigungslink in deiner E-Mail, '
                    'um dein Konto zu aktivieren.',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.xl),
                // TODO(follow-up): Add resend button once backend exposes
                // a POST /api/auth/resend-verification endpoint.
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  style: TextButton.styleFrom(
                    minimumSize:
                        const Size.fromHeight(AppSpacing.touchTargetMin),
                  ),
                  child: const Text('Zurück zur Anmeldung'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
