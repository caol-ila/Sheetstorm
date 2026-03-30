import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/tuner/presentation/screens/tuner_screen.dart';

/// Routen-Konstanten für das Stimmgerät.
abstract final class TunerRoutes {
  static const String tuner = '/app/tuner';
}

/// GoRoute-Definition für den Tuner.
final tunerRoute = GoRoute(
  path: TunerRoutes.tuner,
  builder: (context, state) => const TunerScreen(),
);
