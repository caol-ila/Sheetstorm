import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/data/models/band_models.dart';
import 'package:sheetstorm/features/band/data/services/band_service.dart';

part 'invitations_notifier.g.dart';

@riverpod
class InvitationsNotifier extends _$InvitationsNotifier {
  @override
  Future<List<Invitation>> build(String bandId) async {
    final service = ref.read(bandServiceProvider);
    return service.getInvitations(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(bandServiceProvider);
      return service.getInvitations(bandId);
    });
  }

  Future<Invitation?> createEmail({
    required String email,
    required BandRole role,
    int expiryDays = 7,
    String? message,
  }) async {
    final service = ref.read(bandServiceProvider);
    try {
      final invitation = await service.createEmailInvitation(
        bandId,
        email,
        role,
        expiryDays: expiryDays,
        message: message,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, invitation]);
      return invitation;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<Invitation?> createLink({
    required BandRole role,
    int expiryDays = 7,
  }) async {
    final service = ref.read(bandServiceProvider);
    try {
      final invitation = await service.createLinkInvitation(
        bandId,
        role,
        expiryDays: expiryDays,
      );
      final current = state.value ?? [];
      state = AsyncData([...current, invitation]);
      return invitation;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> revoke(String invitationId) async {
    final service = ref.read(bandServiceProvider);
    try {
      await service.revokeInvitation(bandId, invitationId);
      final current = state.value ?? [];
      state = AsyncData(
        current.where((e) => e.id != invitationId).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
