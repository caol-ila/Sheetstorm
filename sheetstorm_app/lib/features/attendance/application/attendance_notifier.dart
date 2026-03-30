import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';
import 'package:sheetstorm/features/attendance/data/services/attendance_service.dart';

part 'attendance_notifier.g.dart';

// ─── Attendance Dashboard State ───────────────────────────────────────────────

class AttendanceDashboardState {
  final AttendanceStats? stats;
  final AttendanceTrend? trend;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? eventType;
  final bool isLoading;
  final String? error;

  const AttendanceDashboardState({
    this.stats,
    this.trend,
    this.startDate,
    this.endDate,
    this.eventType,
    this.isLoading = false,
    this.error,
  });

  static const _sentinel = Object();

  AttendanceDashboardState copyWith({
    Object? stats = _sentinel,
    Object? trend = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? eventType = _sentinel,
    bool? isLoading,
    Object? error = _sentinel,
  }) =>
      AttendanceDashboardState(
        stats: stats == _sentinel ? this.stats : stats as AttendanceStats?,
        trend: trend == _sentinel ? this.trend : trend as AttendanceTrend?,
        startDate:
            startDate == _sentinel ? this.startDate : startDate as DateTime?,
        endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
        eventType:
            eventType == _sentinel ? this.eventType : eventType as String?,
        isLoading: isLoading ?? this.isLoading,
        error: error == _sentinel ? this.error : error as String?,
      );
}

// ─── Attendance Notifier ──────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  AttendanceDashboardState build(String bandId) {
    // Default: Last 3 months
    final now = DateTime.now();
    final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
    
    final initialState = AttendanceDashboardState(
      startDate: threeMonthsAgo,
      endDate: now,
    );

    // Load data asynchronously
    _loadData();

    return initialState;
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final service = ref.read(attendanceServiceProvider);
      
      final statsResult = await service.getStatistics(
        bandId,
        startDate: state.startDate,
        endDate: state.endDate,
        eventType: state.eventType,
      );

      final trendResult = await service.getTrends(
        bandId,
        startDate: state.startDate,
        endDate: state.endDate,
        eventType: state.eventType,
      );

      state = state.copyWith(
        stats: statsResult,
        trend: trendResult,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Laden der Statistiken',
      );
    }
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    state = state.copyWith(startDate: start, endDate: end);
    await _loadData();
  }

  Future<void> setEventType(String? type) async {
    state = state.copyWith(eventType: type);
    await _loadData();
  }

  Future<void> refresh() async {
    await _loadData();
  }

  Future<ExportData?> exportData(String format) async {
    try {
      final service = ref.read(attendanceServiceProvider);
      return await service.requestExport(
        bandId,
        format,
        startDate: state.startDate,
        endDate: state.endDate,
        eventType: state.eventType,
      );
    } catch (e) {
      return null;
    }
  }
}
