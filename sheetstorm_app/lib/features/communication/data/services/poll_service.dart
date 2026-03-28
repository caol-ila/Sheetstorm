import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/communication/data/models/poll_models.dart';
import 'package:sheetstorm/shared/services/api_client.dart';

part 'poll_service.g.dart';

@Riverpod(keepAlive: true)
PollService pollService(Ref ref) {
  final dio = ref.read(apiClientProvider);
  return PollService(dio);
}

/// HTTP layer for Polls endpoints.
class PollService {
  final Dio _dio;

  PollService(this._dio);

  // ─── Polls CRUD ───────────────────────────────────────────────────────────

  Future<List<Poll>> getPolls(
    String bandId, {
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/polls',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
      },
    );
    final polls = res.data!['polls'] as List<dynamic>;
    return polls
        .map((e) => Poll.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Poll> getPollDetail(String bandId, String pollId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/polls/$pollId',
    );
    return Poll.fromJson(res.data!);
  }

  Future<Poll> createPoll(
    String bandId, {
    required String question,
    required List<String> options,
    DateTime? deadline,
    bool isAnonymous = true,
    bool isMultiSelect = false,
    bool showResultsAfterVoting = true,
    List<String>? targetSectionIds,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/polls',
      data: {
        'question': question,
        'options': options,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
        'isAnonymous': isAnonymous,
        'isMultiSelect': isMultiSelect,
        'showResultsAfterVoting': showResultsAfterVoting,
        if (targetSectionIds != null) 'targetSectionIds': targetSectionIds,
      },
    );
    return Poll.fromJson(res.data!);
  }

  Future<Poll> vote(
    String bandId,
    String pollId,
    List<String> optionIds,
  ) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/polls/$pollId/vote',
      data: {'optionIds': optionIds},
    );
    return Poll.fromJson(res.data!);
  }

  Future<Poll> closePoll(String bandId, String pollId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/bands/$bandId/polls/$pollId/close',
    );
    return Poll.fromJson(res.data!);
  }
}
