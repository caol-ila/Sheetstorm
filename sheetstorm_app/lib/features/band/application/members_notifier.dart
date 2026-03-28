import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/data/services/band_service.dart';

part 'members_notifier.g.dart';

@riverpod
class MembersNotifier extends _$MembersNotifier {
  @override
  Future<List<Member>> build(String bandId) async {
    final service = ref.read(bandServiceProvider);
    return service.getMembers(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(bandServiceProvider);
      return service.getMembers(bandId);
    });
  }

  Future<bool> updateRoles(
    String musicianId,
    List<BandRole> roles,
  ) async {
    final service = ref.read(bandServiceProvider);
    try {
      final updated =
          await service.updateMemberRoles(bandId, musicianId, roles);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((m) => m.musicianId == musicianId ? updated : m).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeMember(String musicianId) async {
    final service = ref.read(bandServiceProvider);
    try {
      await service.removeMember(bandId, musicianId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((m) => m.musicianId != musicianId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
