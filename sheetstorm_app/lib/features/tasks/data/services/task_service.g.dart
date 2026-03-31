// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(taskService)
final taskServiceProvider = TaskServiceProvider._();

final class TaskServiceProvider
    extends $FunctionalProvider<TaskService, TaskService, TaskService>
    with $Provider<TaskService> {
  TaskServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'taskServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$taskServiceHash();

  @$internal
  @override
  $ProviderElement<TaskService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TaskService create(Ref ref) {
    return taskService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TaskService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TaskService>(value),
    );
  }
}

String _$taskServiceHash() => r'420acad091b2ba10b0c327a08086eecd6903adee';
