import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';
import 'package:sheetstorm/features/communication/data/services/poll_service.dart';

part 'poll_notifier.g.dart';

// ─── Poll List ────────────────────────────────────────────────────────────────

@riverpod
class PollListNotifier extends _$PollListNotifier {
  @override
  Future<List<Poll>> build(String bandId) async {
    final service = ref.read(pollServiceProvider);
    return service.getPolls(bandId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(pollServiceProvider);
      return service.getPolls(bandId);
    });
  }

  Future<Poll?> createPoll({
    required String question,
    required List<String> options,
    DateTime? deadline,
    bool isAnonymous = true,
    bool isMultiSelect = false,
    bool showResultsAfterVoting = true,
    List<String>? targetSectionIds,
  }) async {
    final service = ref.read(pollServiceProvider);
    try {
      final poll = await service.createPoll(
        bandId,
        question: question,
        options: options,
        deadline: deadline,
        isAnonymous: isAnonymous,
        isMultiSelect: isMultiSelect,
        showResultsAfterVoting: showResultsAfterVoting,
        targetSectionIds: targetSectionIds,
      );
      final current = state.value ?? [];
      state = AsyncData([poll, ...current]);
      return poll;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<bool> closePoll(String pollId) async {
    final service = ref.read(pollServiceProvider);
    try {
      final updated = await service.closePoll(bandId, pollId);
      final current = state.value ?? [];
      state = AsyncData(
        current.map((p) => p.id == pollId ? updated : p).toList(),
      );
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

// ─── Poll Detail ──────────────────────────────────────────────────────────────

@riverpod
class PollDetailNotifier extends _$PollDetailNotifier {
  @override
  Future<Poll> build(String bandId, String pollId) async {
    final service = ref.read(pollServiceProvider);
    return service.getPollDetail(bandId, pollId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(pollServiceProvider);
      return service.getPollDetail(bandId, pollId);
    });
  }

  Future<bool> vote(List<String> optionIds) async {
    final service = ref.read(pollServiceProvider);
    try {
      final updated = await service.vote(bandId, pollId, optionIds);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> closePoll() async {
    final service = ref.read(pollServiceProvider);
    try {
      final updated = await service.closePoll(bandId, pollId);
      state = AsyncData(updated);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}
