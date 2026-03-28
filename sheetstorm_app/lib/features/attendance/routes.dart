import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/attendance/presentation/screens/attendance_dashboard_screen.dart';

/// Route definitions for Attendance feature.
/// DO NOT modify app_router.dart — these routes are registered separately.

final attendanceRoutes = [
  GoRoute(
    path: 'attendance',
    builder: (context, state) {
      final bandId = state.uri.queryParameters['bandId'] ?? '';
      return AttendanceDashboardScreen(bandId: bandId);
    },
  ),
];
