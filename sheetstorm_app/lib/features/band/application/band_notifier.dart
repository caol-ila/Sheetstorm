import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/data/services/band_service.dart';

part 'band_notifier.g.dart';

const _activeBandKey = 'active_band_id';

// ─── Active Kapelle (persisted selection) ─────────────────────────────────────

@Riverpod(keepAlive: true)
class ActiveBandNotifier extends _$ActiveBandNotifier {
  @override
  String? build() {
    _loadFromPrefs();
    return null;
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeBandKey);
    if (id != null) {
      state = id;
    }
  }

  Future<void> setActive(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeBandKey, id);
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeBandKey);
  }
}

// ─── Kapelle List ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class BandListNotifier extends _$BandListNotifier {
  @override
  Future<List<Band>> build() async {
    final service = ref.read(bandServiceProvider);
    return service.getBands();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(bandServiceProvider);
      return service.getBands();
    });
  }

  Future<Band?> createBand({
    required String name,
    String? description,
    String? location,
  }) async {
    final service = ref.read(bandServiceProvider);
    try {
      final band = await service.createBand(
        name: name,
        description: description,
        location: location,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, band]);
      return band;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteBand(String id) async {
    final service = ref.read(bandServiceProvider);
    try {
      await service.deleteBand(id);
      final current = state.value ?? [];
      state = AsyncData(current.where((k) => k.id != id).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
