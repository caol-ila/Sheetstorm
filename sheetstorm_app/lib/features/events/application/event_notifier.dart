import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/events/data/models/event_models.dart';
import 'package:sheetstorm/features/events/data/services/event_service.dart';

part 'event_notifier.g.dart';

// ─── Event List Notifier ────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class EventListNotifier extends _$EventListNotifier {
  @override
  Future<List<Event>> build({
    String? bandId,
    EventType? type,
    RsvpStatus? status,
  }) async {
    final service = ref.read(eventServiceProvider);
    return service.getEvents(bandId: bandId, type: type, status: status);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(eventServiceProvider);
      return service.getEvents(
        bandId: bandId,
        type: type,
        status: status,
      );
    });
  }

  Future<Event?> createEvent({
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
    final service = ref.read(eventServiceProvider);
    try {
      final event = await service.createEvent(
        bandId: bandId,
        title: title,
        type: type,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        meetingPoint: meetingPoint,
        description: description,
        setlistId: setlistId,
        dressCode: dressCode,
        rsvpDeadline: rsvpDeadline,
        recurring: recurring,
        recurringWeeks: recurringWeeks,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, event]);
      return event;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteEvent(String id) async {
    final service = ref.read(eventServiceProvider);
    try {
      await service.deleteEvent(id);
      final current = state.value ?? [];
      state = AsyncData(current.where((e) => e.id != id).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Event Detail Notifier (family by eventId) ──────────────────────────────

@riverpod
class EventDetailNotifier extends _$EventDetailNotifier {
  @override
  Future<Event> build(String eventId) async {
    final service = ref.read(eventServiceProvider);
    return service.getEventDetail(eventId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(eventServiceProvider);
      return service.getEventDetail(eventId);
    });
  }

  Future<bool> updateEvent({
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
    final service = ref.read(eventServiceProvider);
    try {
      final updated = await service.updateEvent(
        eventId,
        title: title,
        type: type,
        date: date,
        startTime: startTime,
        endTime: endTime,
        location: location,
        meetingPoint: meetingPoint,
        description: description,
        setlistId: setlistId,
        dressCode: dressCode,
        rsvpDeadline: rsvpDeadline,
      );
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> submitRsvp({
    required RsvpStatus status,
    String? reason,
  }) async {
    final service = ref.read(eventServiceProvider);
    try {
      await service.submitRsvp(eventId, status: status, reason: reason);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── RSVP List Notifier (family by eventId) ─────────────────────────────────

@riverpod
class RsvpListNotifier extends _$RsvpListNotifier {
  @override
  Future<List<Rsvp>> build(String eventId) async {
    final service = ref.read(eventServiceProvider);
    return service.getRsvps(eventId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(eventServiceProvider);
      return service.getRsvps(eventId);
    });
  }

  List<Rsvp> filterByStatus(RsvpStatus status) {
    final rsvps = state.value ?? [];
    return rsvps.where((r) => r.status == status).toList();
  }
}
