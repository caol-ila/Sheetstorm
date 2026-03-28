import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/band/application/band_notifier.dart';
import 'package:sheetstorm/features/setlist/data/models/setlist_models.dart';
import 'package:sheetstorm/features/setlist/data/services/setlist_service.dart';

part 'setlist_player_notifier.g.dart';

// ─── Player State ─────────────────────────────────────────────────────────────

enum PlayerStatus { idle, loading, playing, paused, finished }

class SetlistPlayerState {
  final PlayerStatus status;
  final SpielmodusData? data;
  final int currentIndex;
  final bool autoAdvance;
  final String? error;

  const SetlistPlayerState({
    this.status = PlayerStatus.idle,
    this.data,
    this.currentIndex = 0,
    this.autoAdvance = false,
    this.error,
  });

  SpielmodusStueck? get currentStueck {
    if (data == null || playableItems.isEmpty) return null;
    if (currentIndex < 0 || currentIndex >= playableItems.length) return null;
    return playableItems[currentIndex];
  }

  /// Only stuecke that can be played (not skipped placeholders).
  List<SpielmodusStueck> get playableItems =>
      data?.stuecke.where((s) => s.isPlayable).toList() ?? const [];

  int get totalPlayable => playableItems.length;

  bool get isFirst => currentIndex <= 0;
  bool get isLast => currentIndex >= totalPlayable - 1;

  /// Progress string like "Stück 3/12".
  String get progressLabel {
    if (totalPlayable == 0) return '';
    return 'Stück ${currentIndex + 1}/$totalPlayable';
  }

  SetlistPlayerState copyWith({
    PlayerStatus? status,
    SpielmodusData? data,
    int? currentIndex,
    bool? autoAdvance,
    String? error,
  }) =>
      SetlistPlayerState(
        status: status ?? this.status,
        data: data ?? this.data,
        currentIndex: currentIndex ?? this.currentIndex,
        autoAdvance: autoAdvance ?? this.autoAdvance,
        error: error ?? this.error,
      );
}

// ─── Player Notifier ──────────────────────────────────────────────────────────

@riverpod
class SetlistPlayerNotifier extends _$SetlistPlayerNotifier {
  Timer? _autoAdvanceTimer;

  @override
  SetlistPlayerState build(String setlistId) {
    ref.onDispose(_disposeTimers);
    return const SetlistPlayerState();
  }

  void _disposeTimers() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  /// Load setlist data for player mode and start playing.
  Future<void> startPlaying({String? stimmeId}) async {
    state = state.copyWith(status: PlayerStatus.loading);
    final bandId = ref.read(activeBandProvider);
    if (bandId == null) {
      state = state.copyWith(
        status: PlayerStatus.idle,
        error: 'Keine aktive Kapelle',
      );
      return;
    }

    try {
      final service = ref.read(setlistServiceProvider);
      final data = await service.getSpielmodusDaten(
        bandId,
        setlistId,
        stimmeId: stimmeId,
      );
      state = state.copyWith(
        status: PlayerStatus.playing,
        data: data,
        currentIndex: 0,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlayerStatus.idle,
        error: 'Setlist konnte nicht geladen werden',
      );
    }
  }

  /// Navigate to the next playable entry.
  void next() {
    if (state.isLast) {
      state = state.copyWith(status: PlayerStatus.finished);
      _cancelAutoAdvance();
      return;
    }
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    _restartAutoAdvanceIfNeeded();
  }

  /// Navigate to the previous playable entry.
  void previous() {
    if (state.isFirst) return;
    state = state.copyWith(currentIndex: state.currentIndex - 1);
    _restartAutoAdvanceIfNeeded();
  }

  /// Jump to a specific playable entry index.
  void jumpTo(int index) {
    if (index < 0 || index >= state.totalPlayable) return;
    final wasFinished = state.status == PlayerStatus.finished;
    state = state.copyWith(
      currentIndex: index,
      status: wasFinished ? PlayerStatus.playing : state.status,
    );
    _restartAutoAdvanceIfNeeded();
  }

  /// Toggle pause/play.
  void togglePause() {
    if (state.status == PlayerStatus.playing) {
      state = state.copyWith(status: PlayerStatus.paused);
      _cancelAutoAdvance();
    } else if (state.status == PlayerStatus.paused) {
      state = state.copyWith(status: PlayerStatus.playing);
      _restartAutoAdvanceIfNeeded();
    }
  }

  /// Toggle auto-advance mode.
  void toggleAutoAdvance() {
    final newValue = !state.autoAdvance;
    state = state.copyWith(autoAdvance: newValue);
    if (newValue) {
      _restartAutoAdvanceIfNeeded();
    } else {
      _cancelAutoAdvance();
    }
  }

  /// Restart from the beginning.
  void restart() {
    state = state.copyWith(
      status: PlayerStatus.playing,
      currentIndex: 0,
    );
    _restartAutoAdvanceIfNeeded();
  }

  /// Stop the player.
  void stop() {
    _disposeTimers();
    state = const SetlistPlayerState();
  }

  void _cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  void _restartAutoAdvanceIfNeeded() {
    _cancelAutoAdvance();
    if (!state.autoAdvance || state.status != PlayerStatus.playing) return;

    final current = state.currentStueck;
    if (current == null) return;

    // Default auto-advance after 30 seconds if no duration info
    const defaultDuration = Duration(seconds: 30);
    _autoAdvanceTimer = Timer(defaultDuration, next);
  }
}
