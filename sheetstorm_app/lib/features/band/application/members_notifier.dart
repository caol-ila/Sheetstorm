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
    String userId,
    List<BandRole> roles,
  ) async {
    final service = ref.read(bandServiceProvider);
    try {
      final updated =
          await service.updateMemberRoles(bandId, userId, roles);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((m) => m.userId == userId ? updated : m).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeMember(String userId) async {
    final service = ref.read(bandServiceProvider);
    try {
      await service.removeMember(bandId, userId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((m) => m.userId != userId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
