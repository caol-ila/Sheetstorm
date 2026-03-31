import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/substitute/data/models/substitute_models.dart';
import 'package:sheetstorm/features/substitute/data/services/substitute_service.dart';part 'substitute_notifier.g.dart';

// ─── Substitute List Notifier ─────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class SubstituteListNotifier extends _$SubstituteListNotifier {
  @override
  Future<List<SubstituteAccess>> build(String bandId) async {
    return _loadAccess();
  }

  Future<List<SubstituteAccess>> _loadAccess() async {
    final service = ref.read(substituteServiceProvider);
    return service.listAccess(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_loadAccess);
  }

  Future<SubstituteLink?> createAccess({
    required String name,
    required String instrument,
    required String voice,
    String? eventId,
    DateTime? expiresAt,
    String? note,
  }) async {
    final service = ref.read(substituteServiceProvider);
    try {
      final link = await service.createAccessLink(
        bandId,
        name: name,
        instrument: instrument,
        voice: voice,
        eventId: eventId,
        expiresAt: expiresAt,
        note: note,
      );
      
      // Refresh list
      await refresh();
      
      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> revokeAccess(String accessId) async {
    final service = ref.read(substituteServiceProvider);
    try {
      await service.revokeAccess(bandId, accessId);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> extendExpiry(String accessId, DateTime newExpiresAt) async {
    final service = ref.read(substituteServiceProvider);
    try {
      await service.extendExpiry(bandId, accessId, newExpiresAt);
      await refresh();
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Active Substitutes Filter ────────────────────────────────────────────────

@riverpod
List<SubstituteAccess> activeSubstitutes(
  Ref ref,
  String bandId,
) {
  final accessList = ref.watch(substituteListProvider(bandId));
  return accessList.when(
    data: (list) => list.where((access) => access.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}
