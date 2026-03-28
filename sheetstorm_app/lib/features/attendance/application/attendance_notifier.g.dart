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
    extends $NotifierProvider<AttendanceNotifier, AttendanceDashboardState> {
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

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttendanceDashboardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttendanceDashboardState>(value),
    );
  }

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
    r'2495a32c6848f918eae748b54f651781bf5e6733';

final class AttendanceNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AttendanceNotifier,
          AttendanceDashboardState,
          AttendanceDashboardState,
          AttendanceDashboardState,
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
    extends $Notifier<AttendanceDashboardState> {
  late final _$args = ref.$arg as String;
  String get bandId => _$args;

  AttendanceDashboardState build(String bandId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AttendanceDashboardState, AttendanceDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AttendanceDashboardState, AttendanceDashboardState>,
              AttendanceDashboardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
