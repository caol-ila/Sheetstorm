// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attendanceService)
final attendanceServiceProvider = AttendanceServiceProvider._();

final class AttendanceServiceProvider
    extends
        $FunctionalProvider<
          AttendanceService,
          AttendanceService,
          AttendanceService
        >
    with $Provider<AttendanceService> {
  AttendanceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceServiceHash();

  @$internal
  @override
  $ProviderElement<AttendanceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AttendanceService create(Ref ref) {
    return attendanceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttendanceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttendanceService>(value),
    );
  }
}

String _$attendanceServiceHash() => r'aabf1ebe25ead246d2fa3c559ca81b4c14e99a32';
