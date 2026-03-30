// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AttendanceNotifier)
final attendanceProvider = AttendanceNotifierFamily._();

final class AttendanceNotifierProvider
    extends
        $AsyncNotifierProvider<AttendanceNotifier, AttendanceDashboardState> {
  AttendanceNotifierProvider._({
    required AttendanceNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'attendanceProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$attendanceNotifierHash();

  @override
  String toString() {
    return r'attendanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AttendanceNotifier create() => AttendanceNotifier();

  @override
  bool operator ==(Object other) {
    return other is AttendanceNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$attendanceNotifierHash() =>
    r'1e8b81bc092960dbcb0c93f8c422f86a0f101323';

final class AttendanceNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AttendanceNotifier,
          AsyncValue<AttendanceDashboardState>,
          AttendanceDashboardState,
          FutureOr<AttendanceDashboardState>,
          String
        > {
  AttendanceNotifierFamily._()
    : super(
        retry: null,
        name: r'attendanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  AttendanceNotifierProvider call(String bandId) =>
      AttendanceNotifierProvider._(argument: bandId, from: this);

  @override
  String toString() => r'attendanceProvider';
}

abstract class _$AttendanceNotifier
    extends $AsyncNotifier<AttendanceDashboardState> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  FutureOr<AttendanceDashboardState> build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<AttendanceDashboardState>,
              AttendanceDashboardState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<AttendanceDashboardState>,
                AttendanceDashboardState
              >,
              AsyncValue<AttendanceDashboardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
