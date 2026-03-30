import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/media_links/data/models/media_link_models.dart';
import 'package:sheetstorm/features/media_links/data/services/media_link_service.dart';

part 'media_link_notifier.g.dart';

@riverpod
class MediaLinkNotifier extends _$MediaLinkNotifier {
  @override
  Future<List<MediaLink>> build(String kapelleId, String stueckId) async {
    final service = ref.read(mediaLinkServiceProvider);
    return service.getLinks(kapelleId, stueckId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(mediaLinkServiceProvider);
      return service.getLinks(kapelleId, stueckId);
    });
  }

  Future<MediaLink?> addLink(String url) async {
    final service = ref.read(mediaLinkServiceProvider);
    try {
      final link = await service.addLink(
        kapelleId: kapelleId,
        stueckId: stueckId,
        url: url,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, link]);
      return link;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> deleteLink(String linkId) async {
    final service = ref.read(mediaLinkServiceProvider);
    try {
      await service.deleteLink(
        kapelleId: kapelleId,
        stueckId: stueckId,
        linkId: linkId,
      );
      final current = state.value ?? [];
      state = AsyncData(current.where((l) => l.id != linkId).toList());
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<List<MediaLinkVorschlag>> getVorschlaege() async {
    final service = ref.read(mediaLinkServiceProvider);
    return service.getVorschlaege(
      kapelleId: kapelleId,
      stueckId: stueckId,
    );
  }
}
