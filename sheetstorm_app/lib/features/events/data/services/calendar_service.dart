import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'calendar_service.g.dart';

@Riverpod(keepAlive: true)
CalendarService calendarService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return CalendarService(dio);
}

/// HTTP layer for Calendar endpoints.
class CalendarService {
  final Dio _dio;

  CalendarService(this._dio);

  // ─── Calendar Queries ───────────────────────────────────────────────────────

  Future<List<CalendarEntry>> getCalendarEntries({
    String? bandId,
    required DateTime from,
    required DateTime to,
    EventType? type,
    RsvpStatus? status,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/kalender',
      queryParameters: {
        if (bandId != null) 'kapelle_id': bandId,
        'von': from.toIso8601String().split('T')[0],
        'bis': to.toIso8601String().split('T')[0],
        if (type != null) 'typ': type.toJson(),
        if (status != null) 'status': status.toJson(),
      },
    );
    final items = res.data!['items'] as List<dynamic>;
    return items
        .map((e) => CalendarEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get events for a specific month range
  Future<List<CalendarEntry>> getMonthEntries({
    required DateTime month,
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  }) async {
    final from = DateTime(month.year, month.month, 1);
    final to = DateTime(month.year, month.month + 1, 0);
    return getCalendarEntries(
      bandId: bandId,
      from: from,
      to: to,
      type: type,
      status: status,
    );
  }

  /// Get events for a specific week range
  Future<List<CalendarEntry>> getWeekEntries({
    required DateTime weekStart,
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  }) async {
    final to = weekStart.add(const Duration(days: 6));
    return getCalendarEntries(
      bandId: bandId,
      from: weekStart,
      to: to,
      type: type,
      status: status,
    );
  }
}
