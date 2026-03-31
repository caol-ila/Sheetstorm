import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';
import 'package:sheetstorm/features/attendance/data/services/attendance_service.dart';

part 'attendance_notifier.g.dart';

// ─── Attendance Dashboard State ───────────────────────────────────────────────

/// Holds filter params and loaded data for the Attendance dashboard.
///
/// Wrapped in [AsyncValue] by [AttendanceNotifier] — loading and error states
/// are handled by Riverpod's [AsyncNotifier] instead of custom fields.
class AttendanceDashboardState {
  final AttendanceStats? stats;
  final AttendanceTrend? trend;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? eventType;

  const AttendanceDashboardState({
    this.stats,
    this.trend,
    this.startDate,
    this.endDate,
    this.eventType,
  });

  static const _sentinel = Object();

  AttendanceDashboardState copyWith({
    Object? stats = _sentinel,
    Object? trend = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? eventType = _sentinel,
  }) =>
      AttendanceDashboardState(
        stats: stats == _sentinel ? this.stats : stats as AttendanceStats?,
        trend: trend == _sentinel ? this.trend : trend as AttendanceTrend?,
        startDate:
            startDate == _sentinel ? this.startDate : startDate as DateTime?,
        endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
        eventType:
            eventType == _sentinel ? this.eventType : eventType as String?,
      );
}

// ─── Attendance Notifier ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  Future<AttendanceDashboardState> build(String bandId) {
    final now = DateTime.now();
    return _loadData(
      startDate: DateTime(now.year, now.month - 3, now.day),
      endDate: now,
    );
  }

  Future<AttendanceDashboardState> _loadData({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) async {
    final service = ref.read(attendanceServiceProvider);
    final results = await Future.wait([
      service.getStatistics(
        bandId,
        startDate: startDate,
        endDate: endDate,
        eventType: eventType,
      ),
      service.getTrends(
        bandId,
        startDate: startDate,
        endDate: endDate,
        eventType: eventType,
      ),
    ]);
    return AttendanceDashboardState(
      stats: results[0] as AttendanceStats,
      trend: results[1] as AttendanceTrend,
      startDate: startDate,
      endDate: endDate,
      eventType: eventType,
    );
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    final cur = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadData(
        startDate: start,
        endDate: end,
        eventType: cur?.eventType,
      ),
    );
  }

  Future<void> setEventType(String? type) async {
    final cur = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadData(
        startDate: cur?.startDate,
        endDate: cur?.endDate,
        eventType: type,
      ),
    );
  }

  Future<void> refresh() async {
    final cur = state.value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _loadData(
        startDate: cur?.startDate,
        endDate: cur?.endDate,
        eventType: cur?.eventType,
      ),
    );
  }

  /// Clears all active filters and reloads data without any filter constraints.
  Future<void> resetFilter() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadData());
  }

  Future<ExportData?> exportData(String format) async {
    final cur = state.value;
    try {
      final service = ref.read(attendanceServiceProvider);
      return await service.requestExport(
        bandId,
        format,
        startDate: cur?.startDate,
        endDate: cur?.endDate,
        eventType: cur?.eventType,
      );
    } catch (e) {
      return null;
    }
  }
}
