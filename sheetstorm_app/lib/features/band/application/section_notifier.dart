import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/data/services/band_service.dart';

part 'section_notifier.g.dart';

@riverpod
class SectionNotifier extends _$SectionNotifier {
  @override
  Future<List<Section>> build(String bandId) async {
    final service = ref.read(bandServiceProvider);
    return service.getSection(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(bandServiceProvider);
      return service.getSection(bandId);
    });
  }

  Future<Section?> create({
    required String name,
    String? description,
    String? color,
  }) async {
    final service = ref.read(bandServiceProvider);
    try {
      final sections = await service.createSection(
        bandId,
        name,
        description: description,
        color: color,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, sections]);
      return sections;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> updateSection({
    required String registerId,
    required String name,
    String? description,
    String? color,
  }) async {
    final service = ref.read(bandServiceProvider);
    try {
      final updated = await service.updateSection(
        bandId,
        registerId,
        name,
        description: description,
        color: color,
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
    final service = ref.read(bandServiceProvider);
    try {
      await service.deleteSection(bandId, registerId);
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
