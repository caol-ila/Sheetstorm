// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TaskListNotifier)
final taskListProvider = TaskListNotifierFamily._();

final class TaskListNotifierProvider
    extends $AsyncNotifierProvider<TaskListNotifier, List<BandTask>> {
  TaskListNotifierProvider._({
    required TaskListNotifierFamily super.from,
    required ({String bandId, TaskStatus? status}) super.argument,
  }) : super(
         retry: null,
         name: r'taskListProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskListNotifierHash();

  @override
  String toString() {
    return r'taskListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TaskListNotifier create() => TaskListNotifier();

  @override
  bool operator ==(Object other) {
    return other is TaskListNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskListNotifierHash() => r'c2d22ca23d10f83380da0f98cf708c6279a08d1c';

final class TaskListNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskListNotifier,
          AsyncValue<List<BandTask>>,
          List<BandTask>,
          FutureOr<List<BandTask>>,
          ({String bandId, TaskStatus? status})
        > {
  TaskListNotifierFamily._()
    : super(
        retry: null,
        name: r'taskListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  TaskListNotifierProvider call({required String bandId, TaskStatus? status}) =>
      TaskListNotifierProvider._(
        argument: (bandId: bandId, status: status),
        from: this,
      );

  @override
  String toString() => r'taskListProvider';
}

abstract class _$TaskListNotifier extends $AsyncNotifier<List<BandTask>> {
  late final _$args = ref.$arg as ({String bandId, TaskStatus? status});
  String get bandId => _$args.bandId;
  TaskStatus? get status => _$args.status;

  FutureOr<List<BandTask>> build({required String bandId, TaskStatus? status});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<BandTask>>, List<BandTask>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<BandTask>>, List<BandTask>>,
              AsyncValue<List<BandTask>>,
              Object?,
              Object?
            >;
    element.handleCreate(
      ref,
      () => build(bandId: _$args.bandId, status: _$args.status),
    );
  }
}

@ProviderFor(TaskDetailNotifier)
final taskDetailProvider = TaskDetailNotifierFamily._();

final class TaskDetailNotifierProvider
    extends $AsyncNotifierProvider<TaskDetailNotifier, BandTask> {
  TaskDetailNotifierProvider._({
    required TaskDetailNotifierFamily super.from,
    required (String, {String bandId}) super.argument,
  }) : super(
         retry: null,
         name: r'taskDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$taskDetailNotifierHash();

  @override
  String toString() {
    return r'taskDetailProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  TaskDetailNotifier create() => TaskDetailNotifier();

  @override
  bool operator ==(Object other) {
    return other is TaskDetailNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$taskDetailNotifierHash() =>
    r'a50c1f60dbccb7ebf20c3ee8437202db19120bce';

final class TaskDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TaskDetailNotifier,
          AsyncValue<BandTask>,
          BandTask,
          FutureOr<BandTask>,
          (String, {String bandId})
        > {
  TaskDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'taskDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TaskDetailNotifierProvider call(String taskId, {required String bandId}) =>
      TaskDetailNotifierProvider._(
        argument: (taskId, bandId: bandId),
        from: this,
      );

  @override
  String toString() => r'taskDetailProvider';
}

abstract class _$TaskDetailNotifier extends $AsyncNotifier<BandTask> {
  late final _$args = ref.$arg as (String, {String bandId});
  String get taskId => _$args.$1;
  String get bandId => _$args.bandId;

  FutureOr<BandTask> build(String taskId, {required String bandId});
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BandTask>, BandTask>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BandTask>, BandTask>,
              AsyncValue<BandTask>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args.$1, bandId: _$args.bandId));
  }
}
