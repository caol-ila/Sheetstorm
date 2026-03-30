import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/attendance/data/models/attendance_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'attendance_service.g.dart';

@Riverpod(keepAlive: true)
AttendanceService attendanceService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return AttendanceService(dio);
}

/// HTTP layer for Attendance Statistics endpoints.
class AttendanceService {
  final Dio _dio;

  AttendanceService(this._dio);

  // ─── Statistics ─────────────────────────────────────────────────────────────

  Future<AttendanceStats> getStatistics(
    String bandId, {
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/statistiken/musiker',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventType != null) 'event_type': eventType,
      },
    );
    return AttendanceStats.fromJson(res.data!);
  }

  Future<List<RegisterAttendance>> getRegisterBreakdown(
    String bandId, {
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/kapellen/$bandId/statistiken/register',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventType != null) 'event_type': eventType,
      },
    );
    return res.data!
        .map((e) => RegisterAttendance.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AttendanceTrend> getTrends(
    String bandId, {
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/statistiken/trends',
      queryParameters: {
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventType != null) 'event_type': eventType,
      },
    );
    return AttendanceTrend.fromJson(res.data!);
  }

  // ─── Export ─────────────────────────────────────────────────────────────────

  Future<ExportData> requestExport(
    String bandId,
    String format, {
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/statistiken/export',
      data: {
        'format': format,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (eventType != null) 'event_type': eventType,
      },
    );
    return ExportData.fromJson(res.data!);
  }

  Future<ExportData> getExportStatus(String bandId, String jobId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/statistiken/export/$jobId',
    );
    return ExportData.fromJson(res.data!);
  }
}
