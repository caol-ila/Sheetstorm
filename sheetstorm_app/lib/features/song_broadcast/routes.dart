import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/screens/broadcast_control_screen.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/screens/broadcast_receiver_screen.dart';
import 'package:sheetstorm/features/song_broadcast/presentation/screens/metronome_screen.dart';

/// Song Broadcast feature route definitions for integration into the app router.
///
/// These routes are designed to be placed under the band/kapelle route tree.
/// The conductor accesses [BroadcastControlScreen] and musicians access
/// [BroadcastReceiverScreen].
final broadcastRoutes = GoRoute(
  path: '/app/band/:bandId/broadcast',
  builder: (context, state) => BroadcastControlScreen(
    bandId: state.pathParameters['bandId']!,
  ),
  routes: [
    GoRoute(
      path: 'join',
      builder: (context, state) => BroadcastReceiverScreen(
        bandId: state.pathParameters['bandId']!,
      ),
    ),
    GoRoute(
      path: 'metronome',
      builder: (context, state) => MetronomeScreen(
        bandId: state.pathParameters['bandId']!,
      ),
    ),
  ],
);
