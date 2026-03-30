import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/metronome/presentation/screens/metronome_screen.dart';

/// GoRouter routes for the metronome feature.
final metronomeRoutes = GoRoute(
  path: '/app/metronome',
  builder: (context, state) {
    final isConductor =
        state.uri.queryParameters['conductor'] == 'true';
    return MetronomeScreen(isConductor: isConductor);
  },
);
