import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';

part 'mitglieder_notifier.g.dart';

@riverpod
class MitgliederNotifier extends _$MitgliederNotifier {
  @override
  Future<List<Mitglied>> build(String kapelleId) async {
    final service = ref.read(kapelleServiceProvider);
    return service.getMitglieder(kapelleId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(kapelleServiceProvider);
      return service.getMitglieder(kapelleId);
    });
  }

  Future<bool> updateRoles(
    String musikerId,
    List<KapelleRolle> rollen,
  ) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final updated =
          await service.updateMemberRoles(kapelleId, musikerId, rollen);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((m) => m.musikerId == musikerId ? updated : m).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> removeMember(String musikerId) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      await service.removeMember(kapelleId, musikerId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((m) => m.musikerId != musikerId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
