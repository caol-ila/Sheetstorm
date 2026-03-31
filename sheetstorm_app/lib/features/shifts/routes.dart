import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/shifts/presentation/screens/shift_plan_screen.dart';
import 'package:sheetstorm/features/shifts/presentation/screens/shift_detail_screen.dart';

/// Route definitions for Shift Planning feature.
/// DO NOT modify app_router.dart — these routes are registered separately.

final shiftRoutes = [
  GoRoute(
    path: 'shifts',
    builder: (context, state) {
      final bandId = state.pathParameters['bandId'] ?? '';
      return ShiftPlanScreen(
        bandId: bandId,
        planId: state.uri.queryParameters['planId'] ?? '',
      );
    },
  ),
  GoRoute(
    path: 'shift/detail/:planId/:shiftId',
    builder: (context, state) {
      final bandId = state.pathParameters['bandId'] ?? '';
      final planId = state.pathParameters['planId'] ?? '';
      final shiftId = state.pathParameters['shiftId'] ?? '';
      return ShiftDetailScreen(
        bandId: bandId,
        planId: planId,
        shiftId: shiftId,
      );
    },
  ),
];
