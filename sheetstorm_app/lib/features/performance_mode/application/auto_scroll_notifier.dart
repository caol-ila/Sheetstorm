import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auto_scroll_notifier.g.dart';

/// Status of the auto-scroll feature.
enum AutoScrollStatus {
  /// Not active — scroll is not running.
  idle,

  /// Actively scrolling.
  playing,

  /// Temporarily paused (user interaction or manual pause).
  paused,
}

/// Speed mode for auto-scroll.
enum AutoScrollMode {
  /// User sets speed factor manually (0.5×–3.0×).
  manual,

  /// Speed derived from BPM, bars-per-line, and page geometry.
  bpm,
}

/// Immutable state for auto-scroll (Feature-Spec §6, UX-Spec §4–§5).
class AutoScrollState {
  const AutoScrollState({
    this.status = AutoScrollStatus.idle,
    this.mode = AutoScrollMode.manual,
    this.speedFactor = 1.0,
    this.bpm = 120,
    this.barsPerLine = 4,
    this.leadInBars = 2,
    this.pauseOnTouch = true,
    this.startDelaySeconds = 3.0,
  });

  final AutoScrollStatus status;
  final AutoScrollMode mode;

  /// Manual speed multiplier: 0.5–3.0 (UX §4.2).
  final double speedFactor;

  /// Beats per minute for BPM mode (Feature-Spec §6.2).
  final int bpm;

  /// Bars per visible line for BPM calculation (Feature-Spec §6.2).
  final int barsPerLine;

  /// Lead-in bars for BPM mode look-ahead (Feature-Spec §6.3).
  final int leadInBars;

  /// Pause scroll on user touch (UX §5.4 Option A).
  final bool pauseOnTouch;

  /// Seconds to wait before scroll starts (US-01 AC3).
  final double startDelaySeconds;

  // ─── Convenience getters ────────────────────────────────────────────────

  bool get isPlaying => status == AutoScrollStatus.playing;
  bool get isPaused => status == AutoScrollStatus.paused;
  bool get isIdle => status == AutoScrollStatus.idle;

  /// Display label for the current speed setting (UX §4.2).
  String get speedLabel => switch (mode) {
        AutoScrollMode.manual => '${speedFactor.toStringAsFixed(speedFactor.truncateToDouble() == speedFactor ? 0 : 1)}×',
        AutoScrollMode.bpm => '$bpm BPM',
      };

  // ─── Speed calculation (Feature-Spec §6) ────────────────────────────────

  /// Manual speed in px/s: speedFactor × (screenHeight / 10).
  double calculateManualSpeed({required double screenHeight}) {
    final baseSpeed = screenHeight / 10.0;
    return speedFactor * baseSpeed;
  }

  /// BPM-based speed in px/s (Feature-Spec §6.2).
  double calculateBpmSpeed({
    required double pageHeightPx,
    required int estimatedLinesPerPage,
  }) {
    final beatDurationSeconds = 60.0 / bpm;
    final lineDurationSeconds = beatDurationSeconds * barsPerLine;
    final lineHeightPx = pageHeightPx / estimatedLinesPerPage;
    return lineHeightPx / lineDurationSeconds;
  }

  /// Returns the effective scroll speed based on the current mode.
  double effectiveSpeed({
    required double screenHeight,
    required double pageHeightPx,
    required int estimatedLinesPerPage,
  }) {
    return switch (mode) {
      AutoScrollMode.manual => calculateManualSpeed(screenHeight: screenHeight),
      AutoScrollMode.bpm => calculateBpmSpeed(
          pageHeightPx: pageHeightPx,
          estimatedLinesPerPage: estimatedLinesPerPage,
        ),
    };
  }

  AutoScrollState copyWith({
    AutoScrollStatus? status,
    AutoScrollMode? mode,
    double? speedFactor,
    int? bpm,
    int? barsPerLine,
    int? leadInBars,
    bool? pauseOnTouch,
    double? startDelaySeconds,
  }) {
    return AutoScrollState(
      status: status ?? this.status,
      mode: mode ?? this.mode,
      speedFactor: speedFactor ?? this.speedFactor,
      bpm: bpm ?? this.bpm,
      barsPerLine: barsPerLine ?? this.barsPerLine,
      leadInBars: leadInBars ?? this.leadInBars,
      pauseOnTouch: pauseOnTouch ?? this.pauseOnTouch,
      startDelaySeconds: startDelaySeconds ?? this.startDelaySeconds,
    );
  }
}

/// Notifier managing auto-scroll state transitions and settings.
@riverpod
class AutoScroll extends _$AutoScroll {
  @override
  AutoScrollState build() => const AutoScrollState();

  // ─── Playback controls ──────────────────────────────────────────────────

  void play() {
    if (state.status == AutoScrollStatus.playing) return;
    state = state.copyWith(status: AutoScrollStatus.playing);
  }

  void pause() {
    if (state.status != AutoScrollStatus.playing) return;
    state = state.copyWith(status: AutoScrollStatus.paused);
  }

  void stop() {
    if (state.status == AutoScrollStatus.idle) return;
    state = state.copyWith(status: AutoScrollStatus.idle);
  }

  void toggle() {
    switch (state.status) {
      case AutoScrollStatus.idle:
      case AutoScrollStatus.paused:
        play();
      case AutoScrollStatus.playing:
        pause();
    }
  }

  void reset() {
    state = const AutoScrollState();
  }

  // ─── Speed / mode controls ─────────────────────────────────────────────

  void setSpeedFactor(double factor) {
    state = state.copyWith(speedFactor: factor.clamp(0.5, 3.0));
  }

  void incrementSpeed() {
    setSpeedFactor(state.speedFactor + 0.1);
  }

  void decrementSpeed() {
    setSpeedFactor(state.speedFactor - 0.1);
  }

  void setMode(AutoScrollMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setBpm(int bpm) {
    state = state.copyWith(bpm: bpm.clamp(20, 300));
  }

  void setBarsPerLine(int bars) {
    state = state.copyWith(barsPerLine: bars.clamp(1, 8));
  }

  void setLeadInBars(int bars) {
    state = state.copyWith(leadInBars: bars.clamp(0, 4));
  }

  void togglePauseOnTouch() {
    state = state.copyWith(pauseOnTouch: !state.pauseOnTouch);
  }

  // ─── User interaction ───────────────────────────────────────────────────

  /// Called when the user touches/swipes the sheet during auto-scroll.
  /// Pauses if pauseOnTouch is enabled (UX §5.4 Option A).
  void onUserInteraction() {
    if (state.status == AutoScrollStatus.playing && state.pauseOnTouch) {
      pause();
    }
  }
}
