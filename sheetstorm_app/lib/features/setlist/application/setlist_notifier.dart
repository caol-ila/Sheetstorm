import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/features/setlist/data/services/setlist_service.dart';

part 'setlist_notifier.g.dart';

// ─── Setlist List ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class SetlistListNotifier extends _$SetlistListNotifier {
  @override
  Future<List<Setlist>> build() async {
    final bandId = ref.watch(activeBandProvider);
    if (bandId == null) return const [];
    final service = ref.read(setlistServiceProvider);
    final page = await service.getSetlists(bandId);
    return page.items;
  }

  String? get _bandId => ref.read(activeBandProvider);

  Future<void> refresh() async {
    final bandId = _bandId;
    if (bandId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(setlistServiceProvider);
      final page = await service.getSetlists(bandId);
      return page.items;
    });
  }

  Future<void> search(String query) async {
    final bandId = _bandId;
    if (bandId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(setlistServiceProvider);
      final page = await service.getSetlists(bandId, suche: query);
      return page.items;
    });
  }

  Future<void> filter({SetlistTyp? typ, String? sortierung}) async {
    final bandId = _bandId;
    if (bandId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(setlistServiceProvider);
      final page = await service.getSetlists(
        bandId,
        typ: typ,
        sortierung: sortierung,
      );
      return page.items;
    });
  }

  Future<Setlist?> createSetlist({
    required String name,
    required SetlistTyp typ,
    String? datum,
    String? startzeit,
    String? beschreibung,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return null;
    final service = ref.read(setlistServiceProvider);
    try {
      final setlist = await service.createSetlist(
        bandId,
        name: name,
        typ: typ,
        datum: datum,
        startzeit: startzeit,
        beschreibung: beschreibung,
      );
      final current = state.value ?? [];
      state = AsyncData([setlist, ...current]);
      return setlist;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteSetlist(String setlistId) async {
    final bandId = _bandId;
    if (bandId == null) return false;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.deleteSetlist(bandId, setlistId);
      final current = state.value ?? [];
      state = AsyncData(current.where((s) => s.id != setlistId).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<Setlist?> duplicateSetlist(
    String setlistId, {
    String? name,
    String? datum,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return null;
    final service = ref.read(setlistServiceProvider);
    try {
      final duplicate = await service.duplicateSetlist(
        bandId,
        setlistId,
        name: name,
        datum: datum,
      );
      final current = state.value ?? [];
      state = AsyncData([duplicate, ...current]);
      return duplicate;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

// ─── Setlist Detail (family by setlistId) ─────────────────────────────────────

@riverpod
class SetlistDetailNotifier extends _$SetlistDetailNotifier {
  @override
  Future<Setlist> build(String setlistId) async {
    final bandId = ref.watch(activeBandProvider);
    if (bandId == null) throw StateError('Keine aktive Kapelle');
    final service = ref.read(setlistServiceProvider);
    return service.getSetlist(bandId, setlistId);
  }

  String? get _bandId => ref.read(activeBandProvider);

  Future<void> refresh() async {
    final bandId = _bandId;
    if (bandId == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(setlistServiceProvider);
      return service.getSetlist(bandId, setlistId);
    });
  }

  Future<void> addStueck({
    required String stueckId,
    int? geschaetzteDauerSekunden,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.addStueck(
        bandId,
        setlistId,
        stueckId: stueckId,
        geschaetzteDauerSekunden: geschaetzteDauerSekunden,
      );
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addPlatzhalter({
    required String titel,
    String? komponist,
    String? notizen,
    int? geschaetzteDauerSekunden,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.addPlatzhalter(
        bandId,
        setlistId,
        titel: titel,
        komponist: komponist,
        notizen: notizen,
        geschaetzteDauerSekunden: geschaetzteDauerSekunden,
      );
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addPause({
    String titel = 'Pause',
    required int dauerSekunden,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.addPause(
        bandId,
        setlistId,
        titel: titel,
        dauerSekunden: dauerSekunden,
      );
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteEntry(String entryId) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.deleteEntry(bandId, setlistId, entryId);
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reorderEntries(List<SetlistEntry> newOrder) async {
    final bandId = _bandId;
    if (bandId == null) return;

    // Optimistic update
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(eintraege: newOrder));
    }

    final service = ref.read(setlistServiceProvider);
    try {
      await service.reorderEntries(
        bandId,
        setlistId,
        newOrder
            .asMap()
            .entries
            .map((e) => (id: e.value.id, position: e.key + 1))
            .toList(),
      );
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
      // Revert on failure
      if (current != null) state = AsyncData(current);
    }
  }

  Future<void> convertToStueck(String entryId, String stueckId) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      await service.convertToStueck(bandId, setlistId, entryId, stueckId);
      await refresh();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateMetadata({
    String? name,
    SetlistTyp? typ,
    String? datum,
    String? startzeit,
    String? beschreibung,
  }) async {
    final bandId = _bandId;
    if (bandId == null) return;
    final service = ref.read(setlistServiceProvider);
    try {
      final updated = await service.updateSetlist(
        bandId,
        setlistId,
        name: name,
        typ: typ,
        datum: datum,
        startzeit: startzeit,
        beschreibung: beschreibung,
      );
      state = AsyncData(updated);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
