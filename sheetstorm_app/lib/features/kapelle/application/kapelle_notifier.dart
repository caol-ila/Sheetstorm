import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/kapelle/data/models/kapelle_models.dart';
import 'package:sheetstorm/features/kapelle/data/services/kapelle_service.dart';

part 'kapelle_notifier.g.dart';

const _activeKapelleKey = 'active_kapelle_id';

// ─── Active Kapelle (persisted selection) ─────────────────────────────────────

@Riverpod(keepAlive: true)
class ActiveKapelleNotifier extends _$ActiveKapelleNotifier {
  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeKapelleKey);
    if (id != null) {
      state = id;
    }
  }

  Future<void> setActive(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKapelleKey, id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKapelleKey);
  }
}

// ─── Kapelle List ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class KapelleListNotifier extends _$KapelleListNotifier {
  @override
  Future<List<Kapelle>> build() async {
    final service = ref.read(kapelleServiceProvider);
    return service.getKapellen();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(kapelleServiceProvider);
      return service.getKapellen();
    });
  }

  Future<Kapelle?> createKapelle({
    required String name,
    String? beschreibung,
    String? ort,
  }) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      final kapelle = await service.createKapelle(
        name: name,
        beschreibung: beschreibung,
        ort: ort,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, kapelle]);
      return kapelle;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteKapelle(String id) async {
    final service = ref.read(kapelleServiceProvider);
    try {
      await service.deleteKapelle(id);
      final current = state.value ?? [];
      state = AsyncData(current.where((k) => k.id != id).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
