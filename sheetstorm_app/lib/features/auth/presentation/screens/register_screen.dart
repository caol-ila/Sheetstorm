import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:sheetstorm/features/auth/presentation/widgets/password_strength_indicator.dart';

/// 4-step progressive registration form.
/// Step 1: E-Mail + Passwort
/// Step 2: Name (displayName)
/// Step 3: Instrument auswählen
/// Step 4: Kapelle (optional, skip → Onboarding handles it)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 1;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _bandController = TextEditingController();

  String _password = '';
  String? _selectedInstrument;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _bandController.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_step < 4) {
      if (_formKey.currentState!.validate()) {
        setState(() => _step++);
      }
      return;
    }
    // Step 4: trigger registration
    await _register();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    final response = await ref.read(authProvider.notifier).sections(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (response != null) {
      // Router redirect handles navigation based on AuthState:
      // AuthEmailPendingVerification → /email-verify
      // AuthAuthenticated (dev mode) → /onboarding
      final authState = ref.read(authProvider);
      if (authState is AuthEmailPendingVerification) {
        context.go(AppRoutes.emailVerify);
      } else {
        context.go(AppRoutes.onboarding);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konto erstellen'),
        centerTitle: false,
        leading: _step > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step--),
                tooltip: 'Zurück',
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _StepProgressBar(current: _step, total: 4),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: AnimatedSwitcher(
                    duration: AppDurations.base,
                    child: _buildStep(theme),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    return switch (_step) {
      1 => _Step1(
          key: const ValueKey(1),
          emailController: _emailController,
          passwordController: _passwordController,
          password: _password,
          onPasswordChanged: (v) => setState(() => _password = v),
          onNext: _proceed,
        ),
      2 => _Step2(
          key: const ValueKey(2),
          nameController: _nameController,
          onNext: _proceed,
        ),
      3 => _Step3(
          key: const ValueKey(3),
          selectedInstrument: _selectedInstrument,
          onSelected: (v) => setState(() => _selectedInstrument = v),
          onNext: _proceed,
          onSkip: () => setState(() => _step++),
        ),
      _ => _Step4(
          key: const ValueKey(4),
          bandController: _bandController,
          isLoading: _isLoading,
          onRegister: _register,
          onSkip: _register,
        ),
    };
  }
}

// ─── Step 1: E-Mail + Passwort ────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  const _Step1({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.password,
    required this.onPasswordChanged,
    required this.onNext,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String password;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Deine Zugangsdaten', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mit diesen Daten meldest du dich bei Sheetstorm an.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthTextField(
          label: 'E-Mail',
          prefixIcon: Icons.email_outlined,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofocus: true,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'E-Mail erforderlich';
            if (!RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z]+$').hasMatch(v.trim())) {
              return 'Ungültige E-Mail-Adresse';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AuthTextField(
          label: 'Passwort',
          prefixIcon: Icons.lock_outline,
          controller: passwordController,
          obscureText: true,
          toggleObscure: true,
          textInputAction: TextInputAction.done,
          onChanged: onPasswordChanged,
          validator: (v) {
            if (!PasswordStrengthIndicator.isValid(v ?? '')) {
              return 'Passwort erfüllt nicht die Anforderungen';
            }
            return null;
          },
        ),
        PasswordStrengthIndicator(password: password),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed:
              PasswordStrengthIndicator.isValid(password) ? onNext : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: const Text('Weiter'),
        ),
        const SizedBox(height: AppSpacing.md),
        _LoginLink(),
      ],
    );
  }
}

// ─── Step 2: Name ─────────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  const _Step2({
    super.key,
    required this.nameController,
    required this.onNext,
  });

  final TextEditingController nameController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Wie heißt du?', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Dein Name ist für andere Mitglieder deiner Kapelle sichtbar.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthTextField(
          label: 'Dein Name',
          prefixIcon: Icons.person_outline,
          controller: nameController,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.done,
          autofocus: true,
          onFieldSubmitted: (_) => onNext(),
          validator: (v) {
            if (v == null || v.trim().length < 2) return 'Name mindestens 2 Zeichen';
            if (v.trim().length > 100) return 'Name maximal 100 Zeichen';
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}

// ─── Step 3: Instrument ───────────────────────────────────────────────────────

const _windBandInstruments = [
  'Flöte', 'Oboe', 'Fagott',
  'Klarinette (B)', 'Klarinette (Es)',
  'Altsaxophon', 'Tenorsaxophon', 'Baritonsaxophon', 'Sopransaxophon',
  'Flügelhorn', 'Trompete',
  'Waldhorn',
  'Tenorhorn', 'Bariton',
  'Posaune', 'Bassposaune',
  'Tuba', 'Sousaphon',
  'Kontrabass',
  'Schlagzeug', 'Perkussion', 'Glockenspiel', 'Xylophon',
  'Keyboard',
  'Sonstiges',
];

class _Step3 extends StatelessWidget {
  const _Step3({
    super.key,
    required this.selectedInstrument,
    required this.onSelected,
    required this.onNext,
    required this.onSkip,
  });

  final String? selectedInstrument;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Dein Instrument', style: theme.textTheme.headlineMedium),
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.touchTargetMin),
              ),
              child: const Text('Überspringen'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Wähle dein Hauptinstrument. Du kannst es später ändern.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _windBandInstruments.map((instrument) {
            final selected = selectedInstrument == instrument;
            return FilterChip(
              label: Text(instrument),
              selected: selected,
              onSelected: (_) => onSelected(instrument),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: selectedInstrument != null ? onNext : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: const Text('Weiter'),
        ),
      ],
    );
  }
}

// ─── Step 4: Kapelle ──────────────────────────────────────────────────────────

class _Step4 extends StatelessWidget {
  const _Step4({
    super.key,
    required this.bandController,
    required this.isLoading,
    required this.onRegister,
    required this.onSkip,
  });

  final TextEditingController bandController;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Deine Kapelle', style: theme.textTheme.headlineMedium),
            TextButton(
              onPressed: isLoading ? null : onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, AppSpacing.touchTargetMin),
              ),
              child: const Text('Überspringen'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Suche nach deiner Kapelle oder überspringe diesen Schritt.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xl),
        AuthTextField(
          label: 'Kapellenname',
          prefixIcon: Icons.search,
          controller: bandController,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          hint: 'z.B. Musikverein Musterhausen',
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Deine Kapelle ist noch nicht dabei? Du kannst sie später hinzufügen.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontSize: AppTypography.fontSizeXs,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ElevatedButton(
          onPressed: isLoading ? null : onRegister,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Konto erstellen'),
        ),
      ],
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  const _StepProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schritt $current von $total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.fontSizeXs,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppSpacing.roundedFull,
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Bereits ein Konto?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () => context.pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(0, AppSpacing.touchTargetMin),
          ),
          child: const Text('Anmelden'),
        ),
      ],
    );
  }
}
