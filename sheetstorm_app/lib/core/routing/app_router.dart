import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/auth/presentation/screens/login_screen.dart';
import 'package:sheetstorm/features/kapelle/presentation/screens/kapelle_screen.dart';
import 'package:sheetstorm/features/noten/presentation/screens/bibliothek_screen.dart';
import 'package:sheetstorm/features/spielmodus/presentation/screens/spielmodus_screen.dart';
import 'package:sheetstorm/shared/widgets/app_shell.dart';

part 'app_router.g.dart';

/// Named routes — verwende AppRoutes statt Magic Strings
abstract final class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String shell = '/app';
  static const String bibliothek = '/app/bibliothek';
  static const String setlists = '/app/setlists';
  static const String kalender = '/app/kalender';
  static const String profil = '/app/profil';
  static const String spielmodus = '/app/spielmodus/:notenId';
  static const String kapelle = '/app/kapelle';

  // Deep-Links: sheetstorm://bibliothek/[id]
  static String bibliothekDetail(String id) => '/app/bibliothek/$id';
  static String aushilfeToken(String token) => '/aushilfe/$token';
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.bibliothek,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
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
                builder: (context, state) => const _PlaceholderScreen(title: 'Setlists'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.kalender,
                builder: (context, state) => const _PlaceholderScreen(title: 'Kalender'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profil,
                builder: (context, state) => const _PlaceholderScreen(title: 'Profil'),
              ),
              GoRoute(
                path: AppRoutes.kapelle,
                builder: (context, state) => const KapelleScreen(),
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
