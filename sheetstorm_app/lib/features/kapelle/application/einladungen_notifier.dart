import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';

part 'einladungen_notifier.g.dart';

@riverpod
class EinladungenNotifier extends _$EinladungenNotifier {
  @override
  Future<List<Einladung>> build(String kapelleId) async {
    final service = ref.read(kapelleServiceProvider);
    return service.getEinladungen(kapelleId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(kapelleServiceProvider);
      return service.getEinladungen(kapelleId);
    });
  }

  Future<Einladung?> createEmail({
    required String email,
    required KapelleRolle rolle,
    int ablaufTage = 7,
    String? nachricht,
  }) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final einladung = await service.createEmailEinladung(
        kapelleId,
        email,
        rolle,
        ablaufTage: ablaufTage,
        nachricht: nachricht,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, einladung]);
      return einladung;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Einladung?> createLink({
    required KapelleRolle rolle,
    int ablaufTage = 7,
  }) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final einladung = await service.createLinkEinladung(
        kapelleId,
        rolle,
        ablaufTage: ablaufTage,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, einladung]);
      return einladung;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> revoke(String einladungId) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      await service.revokeEinladung(kapelleId, einladungId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((e) => e.id != einladungId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
