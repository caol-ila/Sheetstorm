import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetstorm/core/routing/app_router.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

/// 5-step onboarding wizard shown once after first registration.
/// All steps skippable. Prefills data from registration where possible.
///
/// Step 1: Name bestätigen
/// Step 2: Instrument auswählen
/// Step 3: Kapelle & Standardstimme
/// Step 4: Theme (Hell/Dunkel/System)
/// Step 5: Fertig
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Collected data
  String? _displayName;
  String? _instrument;
  String? _kapelleName;
  String? _defaultVoice;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      _displayName = authState.user.displayName;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: AppDurations.base,
        curve: AppCurves.standard,
      );
    } else {
      _finish();
    }
  }

  void _skipPage() => _nextPage();

  Future<void> _finish() async {
    try {
      // Uses the interceptor-equipped Dio so the Bearer token is attached.
      await ref.read(apiClientProvider).patch<void>(
        '/api/users/me/onboarding',
        data: {
          if (_instrument != null) 'instrument': _instrument,
          if (_themeMode.name != 'system') 'theme': _themeMode.name,
          'onboardingCompleted': true,
        },
      );
    } catch (_) {
      // Non-blocking: onboarding data saved locally, API best-effort
    }
    await ref.read(authProvider.notifier).markOnboardingCompleted();
    if (mounted) context.go(AppRoutes.bibliothek);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _OnboardingHeader(
              current: _currentPage + 1,
              total: _totalPages,
              onSkip: _currentPage < _totalPages - 1 ? _skipPage : null,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _PageNameConfirm(
                    displayName: _displayName ?? '',
                    onNameChanged: (v) => _displayName = v,
                    onNext: _nextPage,
                    onSkip: _skipPage,
                  ),
                  _PageInstrument(
                    selected: _instrument,
                    onSelected: (v) => setState(() => _instrument = v),
                    onNext: _nextPage,
                    onSkip: _skipPage,
                  ),
                  _PageKapelle(
                    kapelleName: _kapelleName,
                    onKapelleChanged: (v) => _kapelleName = v,
                    defaultVoice: _defaultVoice,
                    onVoiceChanged: (v) => _defaultVoice = v,
                    onNext: _nextPage,
                    onSkip: _skipPage,
                  ),
                  _PageTheme(
                    themeMode: _themeMode,
                    onThemeChanged: (v) => setState(() => _themeMode = v),
                    onNext: _nextPage,
                    onSkip: _skipPage,
                  ),
                  _PageFinish(onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.current,
    required this.total,
    this.onSkip,
  });
  final int current;
  final int total;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Schritt $current von $total',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (onSkip != null)
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

// ─── Page 1: Name bestätigen ─────────────────────────────────────────────────

class _PageNameConfirm extends StatefulWidget {
  const _PageNameConfirm({
    required this.displayName,
    required this.onNameChanged,
    required this.onNext,
    required this.onSkip,
  });
  final String displayName;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<_PageNameConfirm> createState() => _PageNameConfirmState();
}

class _PageNameConfirmState extends State<_PageNameConfirm> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.displayName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _OnboardingPage(
      icon: Icons.waving_hand_outlined,
      title: 'Willkommen bei Sheetstorm!',
      subtitle: 'Stimmt dein Name so?',
      onNext: () {
        widget.onNameChanged(_ctrl.text.trim());
        widget.onNext();
      },
      onSkip: widget.onSkip,
      child: TextFormField(
        controller: _ctrl,
        style: theme.textTheme.headlineMedium,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Dein Name',
        ),
      ),
    );
  }
}

// ─── Page 2: Instrument ───────────────────────────────────────────────────────

const _blaskapelleInstrumente = [
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

class _PageInstrument extends StatelessWidget {
  const _PageInstrument({
    required this.selected,
    required this.onSelected,
    required this.onNext,
    required this.onSkip,
  });
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.music_note_outlined,
      title: 'Dein Instrument',
      subtitle: 'Wähle dein Hauptinstrument für die Stimmenzuweisung.',
      onNext: selected != null ? onNext : null,
      onSkip: onSkip,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.center,
        children: _blaskapelleInstrumente.map((i) {
          return FilterChip(
            label: Text(i),
            selected: selected == i,
            onSelected: (_) => onSelected(i),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Page 3: Kapelle & Standardstimme ────────────────────────────────────────

class _PageKapelle extends StatelessWidget {
  const _PageKapelle({
    required this.kapelleName,
    required this.onKapelleChanged,
    required this.defaultVoice,
    required this.onVoiceChanged,
    required this.onNext,
    required this.onSkip,
  });
  final String? kapelleName;
  final ValueChanged<String> onKapelleChanged;
  final String? defaultVoice;
  final ValueChanged<String> onVoiceChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.group_outlined,
      title: 'Deine Kapelle',
      subtitle: 'Tritt deiner Kapelle bei oder suche sie.',
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Kapellenname',
              prefixIcon: Icon(Icons.search, size: 20),
              hintText: 'z.B. Musikverein Musterhausen',
            ),
            onChanged: onKapelleChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Standardstimme (optional)',
              prefixIcon: Icon(Icons.music_note_outlined, size: 20),
              hintText: 'z.B. 1. Klarinette',
            ),
            onChanged: onVoiceChanged,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Kapelle noch nicht dabei? Kein Problem — du kannst sie später '
            'in den Einstellungen hinzufügen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: AppTypography.fontSizeXs,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 4: Theme ────────────────────────────────────────────────────────────

class _PageTheme extends StatelessWidget {
  const _PageTheme({
    required this.themeMode,
    required this.onThemeChanged,
    required this.onNext,
    required this.onSkip,
  });
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      icon: Icons.palette_outlined,
      title: 'Erscheinungsbild',
      subtitle: 'Wie soll Sheetstorm aussehen?',
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        children: [
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: 'Hell',
            selected: themeMode == ThemeMode.light,
            onTap: () => onThemeChanged(ThemeMode.light),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: 'Dunkel',
            selected: themeMode == ThemeMode.dark,
            onTap: () => onThemeChanged(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            label: 'Automatisch (Systemeinstellung)',
            selected: themeMode == ThemeMode.system,
            onTap: () => onThemeChanged(ThemeMode.system),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.roundedMd,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: AppSpacing.roundedMd,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : AppColors.border,
            width: selected ? 2 : 1,
          ),
          color: selected
              ? theme.colorScheme.primary.withAlpha(15)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? theme.colorScheme.primary : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected
                      ? AppTypography.weightMedium
                      : AppTypography.weightNormal,
                  color: selected ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 5: Fertig ───────────────────────────────────────────────────────────

class _PageFinish extends StatelessWidget {
  const _PageFinish({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 72,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Alles bereit!',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Du kannst Sheetstorm jetzt verwenden. Alle Einstellungen '
            'kannst du jederzeit im Profil anpassen.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: onFinish,
            icon: const Icon(Icons.library_music_outlined),
            label: const Text('Zur Bibliothek'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Page Scaffold ─────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onNext,
    required this.onSkip,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.md),
          Icon(icon, size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(child: child),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (onNext != null)
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin),
              ),
              child: const Text('Weiter'),
            ),
        ],
      ),
    );
  }
}
