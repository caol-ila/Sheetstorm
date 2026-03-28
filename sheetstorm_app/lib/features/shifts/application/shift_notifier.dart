import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/shifts/data/models/shift_models.dart';
import 'package:sheetstorm/features/shifts/data/services/shift_service.dart';

part 'shift_notifier.g.dart';

// ─── Shift Plan List Notifier ─────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class ShiftPlanListNotifier extends _$ShiftPlanListNotifier {
  @override
  Future<List<ShiftPlan>> build(String bandId) async {
    return _loadPlans();
  }

  Future<List<ShiftPlan>> _loadPlans() async {
    final service = ref.read(shiftServiceProvider);
    return service.getShiftPlans(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadPlans);
  }

  Future<ShiftPlan?> createPlan({
    required String name,
    required DateTime date,
    String? description,
    String? eventId,
  }) async {
    final service = ref.read(shiftServiceProvider);
    try {
      final plan = await service.createShiftPlan(
        bandId,
        name: name,
        date: date,
        description: description,
        eventId: eventId,
      );
      await refresh();
      return plan;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deletePlan(String planId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.deleteShiftPlan(bandId, planId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Shift Plan Detail Notifier (Family) ─────────────────────────────────────

@riverpod
class ShiftPlanNotifier extends _$ShiftPlanNotifier {
  @override
  Future<ShiftPlan> build(String bandId, String planId) async {
    final service = ref.read(shiftServiceProvider);
    return service.getShiftPlan(bandId, planId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(shiftServiceProvider);
      return service.getShiftPlan(bandId, planId);
    });
  }

  Future<Shift?> createShift({
    required String name,
    required DateTime startTime,
    required DateTime endTime,
    required int requiredPeople,
    String? description,
  }) async {
    final service = ref.read(shiftServiceProvider);
    try {
      final shift = await service.createShift(
        bandId,
        planId,
        name: name,
        startTime: startTime,
        endTime: endTime,
        requiredPeople: requiredPeople,
        description: description,
      );
      await refresh();
      return shift;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteShift(String shiftId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.deleteShift(bandId, planId, shiftId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> selfAssign(String shiftId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.selfAssign(bandId, planId, shiftId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeSelfAssignment(String shiftId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.removeSelfAssignment(bandId, planId, shiftId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> assignMember(String shiftId, String musicianId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.assignMember(bandId, planId, shiftId, musicianId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeAssignment(String shiftId, String assignmentId) async {
    final service = ref.read(shiftServiceProvider);
    try {
      await service.removeAssignment(bandId, planId, shiftId, assignmentId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── My Shifts Provider ───────────────────────────────────────────────────────

@riverpod
Future<List<Shift>> myShifts(Ref ref, String bandId, String myMusicianId) async {
  final plansAsync = ref.watch(shiftPlanListProvider(bandId));
  
  return plansAsync.when(
    data: (plans) {
      final myShifts = <Shift>[];
      for (final plan in plans) {
        for (final shift in plan.shifts) {
          if (shift.assignments
              .any((assignment) => assignment.musicianId == myMusicianId)) {
            myShifts.add(shift);
          }
        }
      }
      return myShifts;
    },
    loading: () => [],
    error: (_, __) => [],
  );
}

// ─── Open Shifts Provider ─────────────────────────────────────────────────────

@riverpod
Future<List<Shift>> openShifts(Ref ref, String bandId) async {
  final plansAsync = ref.watch(shiftPlanListProvider(bandId));
  
  return plansAsync.when(
    data: (plans) {
      final openShifts = <Shift>[];
      for (final plan in plans) {
        for (final shift in plan.shifts) {
          if (!shift.isFull && shift.status == ShiftStatus.open) {
            openShifts.add(shift);
          }
        }
      }
      return openShifts;
    },
    loading: () => [],
    error: (_, __) => [],
  );
}
