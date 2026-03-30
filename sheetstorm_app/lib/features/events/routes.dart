import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/events/presentation/screens/calendar_screen.dart';
import 'package:sheetstorm/features/events/presentation/screens/event_detail_screen.dart';
import 'package:sheetstorm/features/events/presentation/screens/rsvp_screen.dart';

/// Event/Calendar routes for integration into app_router.dart
///
/// DO NOT modify app_router.dart directly. Instead, export these routes
/// and integrate them manually.
final eventRoutes = [
  GoRoute(
    path: '/app/events',
    builder: (context, state) => const CalendarScreen(),
  ),
  GoRoute(
    path: '/app/events/:eventId',
    builder: (context, state) => EventDetailScreen(
      eventId: state.pathParameters['eventId']!,
    ),
  ),
  GoRoute(
    path: '/app/events/:eventId/rsvps',
    builder: (context, state) => RsvpScreen(
      eventId: state.pathParameters['eventId']!,
    ),
  ),
];
