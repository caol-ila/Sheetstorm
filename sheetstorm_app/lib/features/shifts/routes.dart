import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/shifts/presentation/screens/shift_plan_screen.dart';
import 'package:sheetstorm/features/shifts/presentation/screens/shift_detail_screen.dart';

/// Route definitions for Shift Planning feature.
/// DO NOT modify app_router.dart — these routes are registered separately.

final shiftRoutes = [
  GoRoute(
    path: 'shifts',
    builder: (context, state) {
      final bandId = state.uri.queryParameters['bandId'] ?? '';
      return ShiftPlanScreen(
        bandId: bandId,
        planId: state.uri.queryParameters['planId'] ?? '',
      );
    },
  ),
  GoRoute(
    path: 'shift/detail',
    builder: (context, state) {
      final args = state.extra as Map<String, dynamic>;
      return ShiftDetailScreen(
        bandId: args['bandId'] as String,
        planId: args['planId'] as String,
        shift: args['shift'],
      );
    },
  ),
];
