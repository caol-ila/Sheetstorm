import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/events/presentation/screens/calendar_screen.dart';
import 'package:sheetstorm/features/events/presentation/screens/event_detail_screen.dart';
import 'package:sheetstorm/features/events/presentation/screens/rsvp_screen.dart';

/// Event/Calendar routes for integration into app_router.dart
///
/// Verschachtelt wie setlistRoutes: Eltern-Route mit verschachtelten
/// Unter-Routen für korrekte StatefulShellBranch-Integration und Deep Links.
final eventRoutes = [
  GoRoute(
    path: '/app/events',
    builder: (context, state) => const CalendarScreen(),
    routes: [
      GoRoute(
        path: ':eventId',
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['eventId']!,
        ),
        routes: [
          GoRoute(
            path: 'rsvps',
            builder: (context, state) => RsvpScreen(
              eventId: state.pathParameters['eventId']!,
            ),
          ),
        ],
      ),
    ],
  ),
];
