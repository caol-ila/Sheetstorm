import 'package:go_router/go_router.dart';
import 'package:sheetstorm/features/tasks/presentation/screens/create_task_screen.dart';
import 'package:sheetstorm/features/tasks/presentation/screens/task_detail_screen.dart';
import 'package:sheetstorm/features/tasks/presentation/screens/task_list_screen.dart';

/// Task-Management routes for integration into app_router.dart
///
/// DO NOT modify app_router.dart directly. Instead, export these routes
/// and integrate them manually.
final taskRoutes = [
  GoRoute(
    path: '/app/tasks/:bandId',
    builder: (context, state) => TaskListScreen(
      bandId: state.pathParameters['bandId']!,
    ),
  ),
  GoRoute(
    path: '/app/tasks/:bandId/new',
    builder: (context, state) => CreateTaskScreen(
      bandId: state.pathParameters['bandId']!,
    ),
  ),
  GoRoute(
    path: '/app/tasks/:bandId/:taskId',
    builder: (context, state) => TaskDetailScreen(
      bandId: state.pathParameters['bandId']!,
      taskId: state.pathParameters['taskId']!,
    ),
  ),
];
