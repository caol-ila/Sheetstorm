import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'task_service.g.dart';

@Riverpod(keepAlive: true)
TaskService taskService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return TaskService(dio);
}

/// HTTP layer for task management endpoints.
class TaskService {
  final Dio _dio;

  TaskService(this._dio);

  // --- Tasks CRUD -----------------------------------------------------------

  Future<List<BandTask>> getTasks({
    required String bandId,
    TaskStatus? status,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/bands/$bandId/tasks',
      queryParameters: {
        if (status != null) 'status': status.toJson(),
      },
    );
    return res.data!
        .map((e) => BandTask.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BandTask> getTaskDetail(String bandId, String taskId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/bands/$bandId/tasks/$taskId',
    );
    return BandTask.fromJson(res.data!);
  }

  Future<BandTask> createTask(CreateTaskRequest request) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/bands/${request.bandId}/tasks',
      data: request.toJson(),
    );
    return BandTask.fromJson(res.data!);
  }

  Future<BandTask> updateTask(
    String bandId,
    String taskId, {
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? eventId,
  }) async {
    final req = UpdateTaskRequest(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      eventId: eventId,
    );
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/bands/$bandId/tasks/$taskId',
      data: req.toJson(),
    );
    return BandTask.fromJson(res.data!);
  }

  Future<BandTask> updateTaskStatus(
    String bandId,
    String taskId,
    TaskStatus status,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/api/bands/$bandId/tasks/$taskId/status',
      data: {'status': status.toJson()},
    );
    return BandTask.fromJson(res.data!);
  }

  Future<void> deleteTask(String bandId, String taskId) async {
    await _dio.delete<void>('/api/bands/$bandId/tasks/$taskId');
  }

  Future<BandTask> updateAssignees(
    String bandId,
    String taskId,
    List<String> memberIds,
  ) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/bands/$bandId/tasks/$taskId/assignees',
      data: {'assigneeIds': memberIds},
    );
    return BandTask.fromJson(res.data!);
  }
}