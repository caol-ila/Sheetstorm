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
import 'package:sheetstorm/features/config/presentation/screens/settings_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/create_band_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/invite_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/join_band_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/band_detail_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/band_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/members_screen.dart';
import 'package:sheetstorm/features/band/presentation/screens/section_screen.dart';
import 'package:sheetstorm/features/sheet_music/presentation/screens/library_screen.dart';
import 'package:sheetstorm/features/sheet_music/presentation/screens/import_screen.dart';
import 'package:sheetstorm/features/sheet_music/presentation/screens/import_summary_screen.dart';
import 'package:sheetstorm/features/sheet_music/presentation/screens/labeling_screen.dart';
import 'package:sheetstorm/features/sheet_music/presentation/screens/metadata_editor_screen.dart';
import 'package:sheetstorm/features/performance_mode/presentation/screens/performance_mode_screen.dart';
import 'package:sheetstorm/features/setlist/routes.dart';
import 'package:sheetstorm/features/events/routes.dart';
import 'package:sheetstorm/features/song_broadcast/routes.dart';
import 'package:sheetstorm/features/communication/routes.dart';
import 'package:sheetstorm/features/attendance/routes.dart';
import 'package:sheetstorm/features/substitute/routes.dart';
import 'package:sheetstorm/features/shifts/routes.dart';
import 'package:sheetstorm/shared/widgets/app_shell.dart';
import 'package:sheetstorm/features/tuner/routes.dart';

part 'app_router.g.dart';

/// Named routes — verwende AppRoutes statt Magic Strings
abstract final class AppRoutes {
  static const String root = '/';
  static const String loading = '/loading';
  static const String login = '/login';
  static const String sections = '/sections';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerify = '/email-verify';
  static const String emailVerifyToken = '/email-verify/:token';
  static const String onboarding = '/onboarding';
  static const String aushilfe = '/aushilfe/:token';
  static const String shell = '/app';
  static const String library = '/app/library';
  static const String setlists = '/app/setlists';
  static const String calendar = '/app/calendar';
  static const String events = '/app/events';
  static const String board = '/app/board';
  static const String profile = '/app/profile';
  static const String performanceMode = '/app/performance-mode/:sheetId';
  static const String band = '/app/band';
  static const String bandNew = '/app/band/new';
  static const String bandJoin = '/app/band/join';
  static String bandDetail({required String id}) => '/app/band/$id';
  static String bandMembers({required String bandId}) =>
      '/app/band/$bandId/members';
  static String bandInvite({required String bandId}) =>
      '/app/band/$bandId/invite';
  static String bandSections({required String bandId}) =>
      '/app/band/$bandId/sections';
  static String bandBroadcast({required String bandId}) =>
      '/app/band/$bandId/broadcast';
  static String bandBroadcastJoin({required String bandId}) =>
      '/app/band/$bandId/broadcast/join';
  static String bandAttendance({required String bandId}) =>
      '/app/band/$bandId/attendance?bandId=$bandId';
  static String bandSubstitutes({required String bandId}) =>
      '/app/band/$bandId/substitutes?bandId=$bandId';
  static String bandShifts({required String bandId, String? planId}) =>
      '/app/band/$bandId/shifts?bandId=$bandId${planId != null ? '&planId=$planId' : ''}';

  // ── Import routes ──────────────────────────────────────────────────────────
  static const String importStart = '/app/import';
  static const String _importLabeling = '/app/import/:uploadId/labeling';
  static const String _importMetadata =
      '/app/import/:uploadId/metadata/:pieceIndex';
  static const String _importSummary = '/app/import/:uploadId/summary';
  static const String tuner = '/app/tuner';
  static const String settings = '/app/settings';

  // Deep-Links: sheetstorm://bibliothek/[id]
  static String bibliothekDetail(String id) => '/app/bibliothek/$id';
  static String aushilfeToken(String token) => '/aushilfe/$token';
  static String emailVerifyWithToken(String token) => '/email-verify/$token';
  static String importLabeling(String uploadId) =>
      '/app/import/$uploadId/labeling';
  static String importMetadata(String uploadId, String pieceIndex) =>
      '/app/import/$uploadId/metadata/$pieceIndex';
  static String importSummary(String uploadId) =>
      '/app/import/$uploadId/summary';
  static String setlistDetail(String setlistId) => '/app/setlists/$setlistId';
  static String setlistEdit(String setlistId) =>
      '/app/setlists/$setlistId/edit';
  static String setlistPlay(String setlistId) => '/app/setlists/$setlistId/play';
  static String eventDetail(String eventId) => '/app/events/$eventId';
  static String eventRsvp(String eventId) => '/app/events/$eventId/rsvps';
}

/// Routes that do not require authentication.
/// Note: `/loading` is intentionally NOT here — it is only valid while
/// auth state is [AuthLoading]. Once resolved, users must leave it.
const _publicRoutes = {
  AppRoutes.login,
  AppRoutes.sections,
  AppRoutes.forgotPassword,
  AppRoutes.emailVerify,
};

@riverpod
GoRouter appRouter(Ref ref) {
  final routerNotifier = _RouterNotifier();

  ref.listen<AuthState>(authProvider, (_, next) {
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
        path: AppRoutes.sections,
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

      // ── Import flow (full-screen, outside the shell) ────────────────────────
      GoRoute(
        path: AppRoutes.importStart,
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: '/app/import/:uploadId/labeling',
        builder: (context, state) => LabelingScreen(
          uploadId: state.pathParameters['uploadId']!,
        ),
      ),
      GoRoute(
        path: '/app/import/:uploadId/metadata/:pieceIndex',
        builder: (context, state) => MetadataEditorScreen(
          uploadId: state.pathParameters['uploadId']!,
          pieceIndex:
              int.tryParse(state.pathParameters['pieceIndex'] ?? '0') ?? 0,
        ),
      ),
      GoRoute(
        path: '/app/import/:uploadId/summary',
        builder: (context, state) => ImportSummaryScreen(
          uploadId: state.pathParameters['uploadId']!,
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
                path: AppRoutes.library,
                builder: (context, state) => const LibraryScreen(),
                routes: [
                  GoRoute(
                    path: ':sheetId/performance-mode',
                    builder: (context, state) => PerformanceModeScreen(
                      sheetId: state.pathParameters['sheetId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              setlistRoutes,
            ],
          ),
          StatefulShellBranch(
            routes: eventRoutes,
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) =>
                    const _PlaceholderScreen(title: 'Profil'),
              ),
              GoRoute(
                path: AppRoutes.band,
                builder: (context, state) => const BandScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => const CreateBandScreen(),
                  ),
                  GoRoute(
                    path: 'join',
                    builder: (context, state) => const JoinBandScreen(),
                  ),
                  GoRoute(
                    path: ':bandId',
                    builder: (context, state) => BandDetailScreen(
                      bandId: state.pathParameters['bandId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'members',
                        builder: (context, state) => MembersScreen(
                          bandId: state.pathParameters['bandId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'invite',
                        builder: (context, state) => InviteScreen(
                          bandId: state.pathParameters['bandId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'sections',
                        builder: (context, state) => BandSectionScreen(
                          bandId: state.pathParameters['bandId']!,
                        ),
                      ),
                      // Song broadcast routes (nested under band)
                      GoRoute(
                        path: 'broadcast',
                        builder: (context, state) => broadcastRoutes.builder!(context, state),
                        routes: broadcastRoutes.routes,
                      ),
                      // Attendance, Substitute, Shifts routes
                      ...attendanceRoutes,
                      ...substituteRoutes,
                      ...shiftRoutes,
                    ],
                  ),
                ],
              ),
              // Communication board routes (top-level in profile shell)
              ...communicationRoutes,
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
          // ── Werkzeuge (Tuner, etc.) ─────────────────────────────────────
          StatefulShellBranch(
            routes: [
              tunerRoute,
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
  final authState = ref.read(authProvider);
  final loc = state.matchedLocation;

  if (authState is AuthLoading) {
    // Stay on loading screen while auth initialises
    return loc == AppRoutes.loading ? null : AppRoutes.loading;
  }

  // Auth resolved — /loading is no longer valid, redirect away
  final isOnLoading = loc == AppRoutes.loading;
  final isPublic = _publicRoutes.contains(loc);
  final isAushilfe = loc.startsWith('/aushilfe/');
  final isEmailVerifyDeepLink = loc.startsWith('/email-verify/');

  if (authState is AuthEmailPendingVerification) {
    if (loc == AppRoutes.emailVerify || isEmailVerifyDeepLink) return null;
    return AppRoutes.emailVerify;
  }

  if (authState is AuthAuthenticated) {
    final user = authState.user;
    if (!user.onboardingCompleted && loc != AppRoutes.onboarding) {
      return AppRoutes.onboarding;
    }
    // Redirect authenticated users away from auth/loading/verify screens
    if (isPublic || isOnLoading || isEmailVerifyDeepLink) {
      return AppRoutes.library;
    }
    return null;
  }

  // Unauthenticated — redirect /loading to /login, allow public + aushilfe
  if (isOnLoading) return AppRoutes.login;
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
