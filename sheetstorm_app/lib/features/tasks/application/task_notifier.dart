import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/tasks/data/models/task_models.dart';
import 'package:sheetstorm/features/tasks/data/services/task_service.dart';

part 'task_notifier.g.dart';

// ─── Task List Notifier ────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class TaskListNotifier extends _$TaskListNotifier {
  @override
  Future<List<BandTask>> build({
    required String bandId,
    TaskStatus? status,
  }) async {
    final service = ref.read(taskServiceProvider);
    return service.getTasks(bandId: bandId, status: status);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(taskServiceProvider);
      return service.getTasks(bandId: bandId, status: status);
    });
  }

  Future<BandTask?> createTask({
    required String title,
    required String bandId,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? eventId,
    List<String>? assigneeIds,
  }) async {
    final service = ref.read(taskServiceProvider);
    try {
      final task = await service.createTask(
        CreateTaskRequest(
          title: title,
          bandId: bandId,
          description: description,
          dueDate: dueDate,
          priority: priority,
          eventId: eventId,
          assigneeIds: assigneeIds,
        ),
      );
      final current = state.value ?? [];
      state = AsyncData([...current, task]);
      return task;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    final service = ref.read(taskServiceProvider);
    try {
      await service.deleteTask(taskId);
      final current = state.value ?? [];
      state = AsyncData(current.where((t) => t.id != taskId).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  List<BandTask> filterByStatus(TaskStatus filterStatus) {
    final tasks = state.value ?? [];
    return tasks.where((t) => t.status == filterStatus).toList();
  }
}

// ─── Task Detail Notifier ─────────────────────────────────────────────────────

@riverpod
class TaskDetailNotifier extends _$TaskDetailNotifier {
  @override
  Future<BandTask> build(String taskId) async {
    final service = ref.read(taskServiceProvider);
    return service.getTaskDetail(taskId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(taskServiceProvider);
      return service.getTaskDetail(taskId);
    });
  }

  Future<bool> updateStatus(TaskStatus newStatus) async {
    final service = ref.read(taskServiceProvider);
    try {
      final updated = await service.updateTaskStatus(taskId, newStatus);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateTask({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? eventId,
  }) async {
    final service = ref.read(taskServiceProvider);
    try {
      final updated = await service.updateTask(
        taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        eventId: eventId,
      );
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateAssignees(List<String> memberIds) async {
    final service = ref.read(taskServiceProvider);
    try {
      final updated = await service.updateAssignees(taskId, memberIds);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
