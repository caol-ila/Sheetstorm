import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';

part 'register_notifier.g.dart';

@riverpod
class RegisterNotifier extends _$RegisterNotifier {
  @override
  Future<List<Register>> build(String kapelleId) async {
    final service = ref.read(kapelleServiceProvider);
    return service.getRegister(kapelleId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(kapelleServiceProvider);
      return service.getRegister(kapelleId);
    });
  }

  Future<Register?> create({
    required String name,
    String? beschreibung,
    String? farbe,
  }) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final register = await service.createRegister(
        kapelleId,
        name,
        beschreibung: beschreibung,
        farbe: farbe,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, register]);
      return register;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> updateRegister({
    required String registerId,
    required String name,
    String? beschreibung,
    String? farbe,
  }) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final updated = await service.updateRegister(
        kapelleId,
        registerId,
        name,
        beschreibung: beschreibung,
        farbe: farbe,
      );
      final current = state.value ?? [];
      state = AsyncData(
        current.map((r) => r.id == registerId ? updated : r).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> delete(String registerId) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      await service.deleteRegister(kapelleId, registerId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((r) => r.id != registerId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
