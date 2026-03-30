import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'event_service.g.dart';

@Riverpod(keepAlive: true)
EventService eventService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return EventService(dio);
}

/// HTTP layer for Event/Calendar endpoints.
class EventService {
  final Dio _dio;

  EventService(this._dio);

  // ─── Events CRUD ────────────────────────────────────────────────────────────

  Future<List<Event>> getEvents({
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/v1/termine',
      queryParameters: {
        if (bandId != null) 'kapelle_id': bandId,
        if (type != null) 'typ': type.toJson(),
        if (status != null) 'status': status.toJson(),
      },
    );
    return res.data!
        .map((e) => Event.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Event> getEventDetail(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/termine/$id');
    return Event.fromJson(res.data!);
  }

  Future<Event> createEvent({
    required String bandId,
    required String title,
    required EventType type,
    required DateTime date,
    required String startTime,
    String? endTime,
    String? location,
    String? meetingPoint,
    String? description,
    String? setlistId,
    String? dressCode,
    DateTime? rsvpDeadline,
    bool recurring = false,
    int? recurringWeeks,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/termine',
      data: {
        'kapelle_id': bandId,
        'titel': title,
        'typ': type.toJson(),
        'datum': date.toIso8601String().split('T')[0],
        'start_uhrzeit': startTime,
        if (endTime != null) 'end_uhrzeit': endTime,
        if (location != null) 'ort': location,
        if (meetingPoint != null) 'treffpunkt': meetingPoint,
        if (description != null) 'beschreibung': description,
        if (setlistId != null) 'setlist_id': setlistId,
        if (dressCode != null) 'kleiderordnung': dressCode,
        if (rsvpDeadline != null)
          'zusage_frist': rsvpDeadline.toIso8601String().split('T')[0],
        'wiederkehrend': recurring,
        if (recurringWeeks != null) 'wiederkehrung_wochen': recurringWeeks,
      },
    );
    return Event.fromJson(res.data!);
  }

  Future<Event> updateEvent(
    String id, {
    String? title,
    EventType? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? meetingPoint,
    String? description,
    String? setlistId,
    String? dressCode,
    DateTime? rsvpDeadline,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/termine/$id',
      data: {
        if (title != null) 'titel': title,
        if (type != null) 'typ': type.toJson(),
        if (date != null) 'datum': date.toIso8601String().split('T')[0],
        if (startTime != null) 'start_uhrzeit': startTime,
        if (endTime != null) 'end_uhrzeit': endTime,
        if (location != null) 'ort': location,
        if (meetingPoint != null) 'treffpunkt': meetingPoint,
        if (description != null) 'beschreibung': description,
        if (setlistId != null) 'setlist_id': setlistId,
        if (dressCode != null) 'kleiderordnung': dressCode,
        if (rsvpDeadline != null)
          'zusage_frist': rsvpDeadline.toIso8601String().split('T')[0],
      },
    );
    return Event.fromJson(res.data!);
  }

  Future<void> deleteEvent(String id) async {
    await _dio.delete<void>('/api/v1/termine/$id');
  }

  // ─── RSVP ───────────────────────────────────────────────────────────────────

  Future<Rsvp> submitRsvp(
    String eventId, {
    required RsvpStatus status,
    String? reason,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/termine/$eventId/teilnahme',
      data: {
        'status': status.toJson(),
        if (reason != null) 'begruendung': reason,
      },
    );
    return Rsvp.fromJson(res.data!);
  }

  Future<List<Rsvp>> getRsvps(String eventId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/termine/$eventId/teilnahmen',
    );
    final items = res.data!['items'] as List<dynamic>;
    return items.map((e) => Rsvp.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Rsvp> updateMemberRsvp(
    String eventId,
    String musicianId, {
    required RsvpStatus status,
    String? reason,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/termine/$eventId/teilnahmen/$musicianId',
      data: {
        'status': status.toJson(),
        if (reason != null) 'begruendung': reason,
      },
    );
    return Rsvp.fromJson(res.data!);
  }
}
