import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/presentation/widgets/auth_text_field.dart';

/// Password reset flow — email input → success state.
/// Cooldown: "Erneut senden" is locked for 60 seconds after each request.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _sent = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .forgotPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _sent = true;
        _isLoading = false;
        _startCooldown();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Senden. Bitte versuche es später.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startCooldown() {
    _cooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _cooldown--;
        if (_cooldown <= 0) t.cancel();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort zurücksetzen'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: _sent ? _buildSuccess(theme) : _buildForm(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(
          Icons.lock_reset_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Passwort vergessen?',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Gib deine E-Mail-Adresse ein. Wir senden dir einen Reset-Link (gültig für 30 Minuten).',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthTextField(
          label: 'E-Mail',
          prefixIcon: Icons.email_outlined,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onFieldSubmitted: (_) => _sendResetLink(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'E-Mail erforderlich';
            if (!v.contains('@')) return 'Ungültige E-Mail-Adresse';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendResetLink,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: _isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Reset-Link senden'),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: const Text('Zurück zum Login'),
        ),
      ],
    );
  }

  Widget _buildSuccess(ThemeData theme) {
    final canResend = _cooldown <= 0 && !_isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(
          Icons.mark_email_read_outlined,
          size: 56,
          color: AppColors.success,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'E-Mail gesendet!',
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Wir haben einen Reset-Link an ${_emailController.text.trim()} gesendet. '
          'Der Link ist 30 Minuten gültig.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton(
          onPressed: canResend ? _sendResetLink : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: Text(
            _cooldown > 0
                ? 'Erneut senden ($_cooldown s)'
                : 'Erneut senden',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: const Text('Zurück zum Login'),
        ),
      ],
    );
  }
}
