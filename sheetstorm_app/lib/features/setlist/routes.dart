import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/setlist/presentation/screens/setlist_builder_screen.dart';
import 'package:sheetstorm/features/setlist/presentation/screens/setlist_detail_screen.dart';
import 'package:sheetstorm/features/setlist/presentation/screens/setlist_list_screen.dart';
import 'package:sheetstorm/features/setlist/presentation/screens/setlist_player_screen.dart';

/// Setlist feature route definitions for integration into the app router.
///
/// These routes are designed to be nested under the setlists shell branch.
/// The list screen serves as the index route, with detail, builder and player
/// as sub-routes.
final setlistRoutes = GoRoute(
  path: '/app/setlists',
  builder: (context, state) => const SetlistListScreen(),
  routes: [
    GoRoute(
      path: ':setlistId',
      builder: (context, state) => SetlistDetailScreen(
        setlistId: state.pathParameters['setlistId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => SetlistBuilderScreen(
            setlistId: state.pathParameters['setlistId']!,
          ),
        ),
        GoRoute(
          path: 'play',
          builder: (context, state) => SetlistPlayerScreen(
            setlistId: state.pathParameters['setlistId']!,
          ),
        ),
      ],
    ),
  ],
);
