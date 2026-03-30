import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/screens/broadcast_control_screen.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/screens/broadcast_receiver_screen.dart';

/// Song Broadcast feature route definitions for integration into the app router.
///
/// These routes are designed to be placed under the band/kapelle route tree
/// (i.e., nested under `/app/band/:bandId`). Paths are relative.
final broadcastRoutes = [
  GoRoute(
    path: 'broadcast',
    builder: (context, state) => BroadcastControlScreen(
      bandId: state.pathParameters['bandId'] ?? '',
    ),
    routes: [
      GoRoute(
        path: 'join',
        builder: (context, state) => BroadcastReceiverScreen(
          bandId: state.pathParameters['bandId'] ?? '',
        ),
      ),
    ],
  ),
];
