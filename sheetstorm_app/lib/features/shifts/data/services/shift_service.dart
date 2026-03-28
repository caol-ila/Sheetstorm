import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'shift_service.g.dart';

@Riverpod(keepAlive: true)
ShiftService shiftService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return ShiftService(dio);
}

/// HTTP layer for Shift Planning endpoints.
class ShiftService {
  final Dio _dio;

  ShiftService(this._dio);

  // ─── Shift Plans ────────────────────────────────────────────────────────────

  Future<List<ShiftPlan>> getShiftPlans(String bandId) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/kapellen/$bandId/schichten',
    );
    return res.data!
        .map((e) => ShiftPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ShiftPlan> getShiftPlan(String bandId, String planId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten/$planId',
    );
    return ShiftPlan.fromJson(res.data!);
  }

  Future<ShiftPlan> createShiftPlan(
    String bandId, {
    required String name,
    required DateTime date,
    String? description,
    String? eventId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten',
      data: {
        'name': name,
        'date': date.toIso8601String(),
        if (description != null) 'description': description,
        if (eventId != null) 'event_id': eventId,
      },
    );
    return ShiftPlan.fromJson(res.data!);
  }

  Future<void> deleteShiftPlan(String bandId, String planId) async {
    await _dio.delete<void>('/api/v1/kapellen/$bandId/schichten/$planId');
  }

  // ─── Shifts ─────────────────────────────────────────────────────────────────

  Future<Shift> createShift(
    String bandId,
    String planId, {
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    required int requiredPeople,
    String? description,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots',
      data: {
        'name': name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'required_people': requiredPeople,
        if (description != null) 'description': description,
      },
    );
    return Shift.fromJson(res.data!);
  }

  Future<Shift> updateShift(
    String bandId,
    String planId,
    String shiftId, {
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? requiredPeople,
    String? description,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId',
      data: {
        if (name != null) 'name': name,
        if (startTime != null) 'start_time': startTime.toIso8601String(),
        if (endTime != null) 'end_time': endTime.toIso8601String(),
        if (requiredPeople != null) 'required_people': requiredPeople,
        if (description != null) 'description': description,
      },
    );
    return Shift.fromJson(res.data!);
  }

  Future<void> deleteShift(String bandId, String planId, String shiftId) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId',
    );
  }

  // ─── Assignments ────────────────────────────────────────────────────────────

  Future<ShiftAssignment> selfAssign(
    String bandId,
    String planId,
    String shiftId,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId/self-assign',
    );
    return ShiftAssignment.fromJson(res.data!);
  }

  Future<void> removeSelfAssignment(
    String bandId,
    String planId,
    String shiftId,
  ) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId/self-assign',
    );
  }

  Future<ShiftAssignment> assignMember(
    String bandId,
    String planId,
    String shiftId,
    String musicianId,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId/assign',
      data: {'musician_id': musicianId},
    );
    return ShiftAssignment.fromJson(res.data!);
  }

  Future<void> removeAssignment(
    String bandId,
    String planId,
    String shiftId,
    String assignmentId,
  ) async {
    await _dio.delete<void>(
      '/api/v1/kapellen/$bandId/schichten/$planId/slots/$shiftId/assignments/$assignmentId',
    );
  }
}
