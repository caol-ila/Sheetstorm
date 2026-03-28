import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/auth/application/auth_notifier.dart';
import 'package:sheetstorm/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:sheetstorm/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:sheetstorm/features/auth/presentation/screens/login_screen.dart';
import 'package:sheetstorm/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:sheetstorm/features/auth/presentation/screens/register_screen.dart';
import 'package:sheetstorm/features/config/presentation/screens/einstellungen_screen.dart';
import 'package:sheetstorm/features/kapelle/presentation/screens/kapelle_screen.dart';
import 'package:sheetstorm/features/noten/presentation/screens/bibliothek_screen.dart';
import 'package:sheetstorm/features/spielmodus/presentation/screens/spielmodus_screen.dart';
import 'package:sheetstorm/shared/widgets/app_shell.dart';

part 'app_router.g.dart';

/// Named routes — verwende AppRoutes statt Magic Strings
abstract final class AppRoutes {
  static const String root = '/';
  static const String loading = '/loading';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerify = '/email-verify';
  static const String emailVerifyToken = '/email-verify/:token';
  static const String onboarding = '/onboarding';
  static const String aushilfe = '/aushilfe/:token';
  static const String shell = '/app';
  static const String bibliothek = '/app/bibliothek';
  static const String setlists = '/app/setlists';
  static const String kalender = '/app/kalender';
  static const String profil = '/app/profil';
  static const String spielmodus = '/app/spielmodus/:notenId';
  static const String kapelle = '/app/kapelle';
  static const String einstellungen = '/app/einstellungen';

  // Deep-Links: sheetstorm://bibliothek/[id]
  static String bibliothekDetail(String id) => '/app/bibliothek/$id';
  static String aushilfeToken(String token) => '/aushilfe/$token';
  static String emailVerifyWithToken(String token) => '/email-verify/$token';
}

/// Routes that do not require authentication.
const _publicRoutes = {
  AppRoutes.loading,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
  AppRoutes.emailVerify,
};

@riverpod
GoRouter appRouter(Ref ref) {
  final routerNotifier = _RouterNotifier();

  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    routerNotifier.notifyRouterListeners();
  });
  ref.onDispose(routerNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.loading,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: routerNotifier,
    redirect: (context, state) => _redirect(ref, state),
    routes: [
      // ── Loading splash ───────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const _SplashScreen(),
      ),

      // ── Auth routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── E-Mail-Bestätigung ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.emailVerify,
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailVerifyToken,
        builder: (context, state) => EmailVerificationScreen(
          verificationToken: state.pathParameters['token'],
        ),
      ),

      // ── Aushilfen Deep-Link (no account required) ────────────────────────
      GoRoute(
        path: AppRoutes.aushilfe,
        builder: (context, state) => _AushilfeScreen(
          token: state.pathParameters['token']!,
        ),
      ),

      // ── App shell (authenticated) ────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bibliothek,
                builder: (context, state) => const BibliothekScreen(),
                routes: [
                  GoRoute(
                    path: ':notenId/spielmodus',
                    builder: (context, state) => SpielmodusScreen(
                      notenId: state.pathParameters['notenId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.setlists,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Setlists'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kalender,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Kalender'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profil,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Profil'),
              ),
              GoRoute(
                path: AppRoutes.kapelle,
                builder: (context, state) => const KapelleScreen(),
              ),
              GoRoute(
                path: AppRoutes.einstellungen,
                builder: (context, state) => const EinstellungenScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route nicht gefunden: ${state.uri}'),
      ),
    ),
  );
}

String? _redirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authNotifierProvider);
  final loc = state.matchedLocation;

  if (authState is AuthLoading) {
    // Stay on loading screen while auth initialises
    return loc == AppRoutes.loading ? null : AppRoutes.loading;
  }

  final isPublic = _publicRoutes.contains(loc);
  final isAushilfe = loc.startsWith('/aushilfe/');
  final isEmailVerifyDeepLink = loc.startsWith('/email-verify/');

  if (authState is AuthEmailPendingVerification) {
    // Allow email-verify routes and deep-links; block everything else
    if (loc == AppRoutes.emailVerify || isEmailVerifyDeepLink) return null;
    return AppRoutes.emailVerify;
  }

  if (authState is AuthAuthenticated) {
    final user = authState.user;
    // First-time users → onboarding (unless already there or at a public route)
    if (!user.onboardingCompleted && loc != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }
    // Redirect authenticated users away from auth/verify screens
    if (isPublic || isEmailVerifyDeepLink) return AppRoutes.bibliothek;
    return null;
  }

  // Unauthenticated
  if (isPublic || isAushilfe || isEmailVerifyDeepLink) return null;
  return AppRoutes.login;
}

// ─── Private widgets ──────────────────────────────────────────────────────────

class _RouterNotifier extends ChangeNotifier {
  void notifyRouterListeners() => notifyListeners();
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _AushilfeScreen extends StatelessWidget {
  const _AushilfeScreen({required this.token});
  final String token;

  @override
  Widget build(BuildContext context) {
    // TODO Issue #15: Aushilfen deep-link flow
    return Scaffold(
      appBar: AppBar(title: const Text('Aushilfen-Zugang')),
      body: Center(
        child: Text('Token: $token\n(Implementierung folgt in Issue #15)'),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — Coming Soon',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
