import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';

part 'performance_mode_notifier.g.dart';

/// Core state for the Spielmodus screen.
class PerformanceModeState {
  const PerformanceModeState({
    this.currentPage = 0,
    this.totalPages = 0,
    this.overlayVisible = false,
    this.uiLocked = false,
    this.viewMode = ViewMode.singlePage,
    this.halfPageStep = 0,
    this.pages = const [],
    this.voices = const [],
    this.currentVoiceId,
    this.setlist,
    this.currentSetlistIndex,
    this.autoScrollActive = false,
    this.autoScrollSpeed = 30.0,
    this.isLoading = true,
    this.errorMessage,
    this.pageZoomMemory = const {},
  });

  final int currentPage;
  final int totalPages;
  final bool overlayVisible;
  final bool uiLocked;
  final ViewMode viewMode;

  /// 0 = showing full page, 1 = showing half-page-turn split
  final int halfPageStep;

  final List<SheetPage> pages;
  final List<Voice> voices;
  final String? currentVoiceId;
  final List<SetlistItem>? setlist;
  final int? currentSetlistIndex;
  final bool autoScrollActive;

  /// Auto-scroll speed: pixels per second
  final double autoScrollSpeed;
  final bool isLoading;
  final String? errorMessage;

  /// Zoom override per page number (AC-50)
  final Map<int, double> pageZoomMemory;

  /// Current setlist item title for overlay display
  String get currentTitle {
    if (setlist != null && currentSetlistIndex != null) {
      return setlist![currentSetlistIndex!].title;
    }
    return '';
  }

  String get pageIndicator {
    if (setlist != null && currentSetlistIndex != null) {
      return 'Stück ${currentSetlistIndex! + 1} / ${setlist!.length}';
    }
    return 'Seite ${currentPage + 1} / $totalPages';
  }

  bool get isFirstPage => currentPage <= 0;
  bool get isLastPage => currentPage >= totalPages - 1;

  PerformanceModeState copyWith({
    int? currentPage,
    int? totalPages,
    bool? overlayVisible,
    bool? uiLocked,
    ViewMode? viewMode,
    int? halfPageStep,
    List<SheetPage>? pages,
    List<Voice>? voices,
    String? currentVoiceId,
    List<SetlistItem>? setlist,
    int? currentSetlistIndex,
    bool? autoScrollActive,
    double? autoScrollSpeed,
    bool? isLoading,
    String? errorMessage,
    Map<int, double>? pageZoomMemory,
  }) {
    return PerformanceModeState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      overlayVisible: overlayVisible ?? this.overlayVisible,
      uiLocked: uiLocked ?? this.uiLocked,
      viewMode: viewMode ?? this.viewMode,
      halfPageStep: halfPageStep ?? this.halfPageStep,
      pages: pages ?? this.pages,
      voices: voices ?? this.voices,
      currentVoiceId: currentVoiceId ?? this.currentVoiceId,
      setlist: setlist ?? this.setlist,
      currentSetlistIndex: currentSetlistIndex ?? this.currentSetlistIndex,
      autoScrollActive: autoScrollActive ?? this.autoScrollActive,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      pageZoomMemory: pageZoomMemory ?? this.pageZoomMemory,
    );
  }
}

/// Family provider: one notifier instance per sheetId.
@riverpod
class PerformanceModeNotifier extends _$PerformanceModeNotifier {
  Timer? _overlayAutoHideTimer;
  late String _sheetId;

  @override
  PerformanceModeState build(String sheetId) {
    _sheetId = sheetId;
    ref.onDispose(() => _overlayAutoHideTimer?.cancel());
    Future<void>.microtask(_loadSheetMusic);
    return const PerformanceModeState();
  }

  /// Loads sheet music metadata — in production this would come from the API/cache.
  Future<void> _loadSheetMusic() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!ref.mounted) return;

    const pageCount = 8;
    final pages = List.generate(
      pageCount,
      (i) => SheetPage(
        pageNumber: i,
        pieceId: _sheetId,
        voiceId: 'default',
      ),
    );

    final voices = [
      const Voice(id: 'kl2', name: '2. Klarinette', isUserInstrument: true),
      const Voice(id: 'kl1', name: '1. Klarinette', isUserInstrument: true),
      const Voice(id: 'tr1', name: 'Trompete 1'),
      const Voice(id: 'tr2', name: 'Trompete 2'),
      const Voice(id: 'fl', name: 'Flügelhorn'),
      const Voice(id: 'hr', name: 'Horn in F'),
      const Voice(id: 'tb', name: 'Tuba'),
    ];

    state = state.copyWith(
      pages: pages,
      totalPages: pageCount,
      voices: voices,
      currentVoiceId: 'kl2',
      isLoading: false,
    );
  }

  // ─── Page Navigation (AC-06..AC-12) ─────────────────────────────────────────

  void nextPage() {
    if (state.isLastPage && state.halfPageStep == 0) {
      _advanceSetlist();
      HapticFeedback.lightImpact();
      return;
    }

    if (state.viewMode == ViewMode.halfPageTurn) {
      _nextHalfPage();
    } else if (state.viewMode == ViewMode.twoPage) {
      _nextTwoPages();
    } else {
      _nextFullPage();
    }
  }

  void previousPage() {
    if (state.isFirstPage && state.halfPageStep == 0) {
      HapticFeedback.lightImpact();
      return;
    }

    if (state.viewMode == ViewMode.halfPageTurn) {
      _previousHalfPage();
    } else if (state.viewMode == ViewMode.twoPage) {
      _previousTwoPages();
    } else {
      _previousFullPage();
    }
  }

  void _nextFullPage() {
    if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.currentPage + 1);
    }
  }

  void _previousFullPage() {
    if (state.currentPage > 0) {
      state = state.copyWith(currentPage: state.currentPage - 1);
    }
  }

  void _nextTwoPages() {
    final next = state.currentPage + 2;
    if (next < state.totalPages) {
      state = state.copyWith(currentPage: next);
    } else if (state.currentPage < state.totalPages - 1) {
      state = state.copyWith(currentPage: state.totalPages - 1);
    }
  }

  void _previousTwoPages() {
    final prev = state.currentPage - 2;
    state = state.copyWith(currentPage: prev.clamp(0, state.totalPages - 1));
  }

  /// Half-page-turn (AC-13..AC-20):
  /// Step 0 → Step 1 (show bottom current + top next)
  /// Step 1 → Step 0, advance page
  void _nextHalfPage() {
    if (state.halfPageStep == 0) {
      if (state.currentPage < state.totalPages - 1) {
        state = state.copyWith(halfPageStep: 1);
      }
    } else {
      state = state.copyWith(
        currentPage: state.currentPage + 1,
        halfPageStep: 0,
      );
    }
  }

  void _previousHalfPage() {
    if (state.halfPageStep == 1) {
      state = state.copyWith(halfPageStep: 0);
    } else if (state.currentPage > 0) {
      state = state.copyWith(
        currentPage: state.currentPage - 1,
        halfPageStep: 1,
      );
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < state.totalPages) {
      state = state.copyWith(currentPage: page, halfPageStep: 0);
    }
  }

  // ─── Overlay (AC-52..AC-56) ────────────────────────────────────────────────

  void toggleOverlay() {
    if (state.uiLocked) return;

    final newVisible = !state.overlayVisible;
    state = state.copyWith(overlayVisible: newVisible);

    if (newVisible) {
      _startOverlayAutoHide();
    } else {
      _overlayAutoHideTimer?.cancel();
    }
  }

  void hideOverlay() {
    _overlayAutoHideTimer?.cancel();
    state = state.copyWith(overlayVisible: false);
  }

  /// Resets auto-hide timer on overlay interaction (AC-54)
  void resetOverlayTimer() {
    _startOverlayAutoHide();
  }

  void _startOverlayAutoHide() {
    _overlayAutoHideTimer?.cancel();
    _overlayAutoHideTimer = Timer(const Duration(seconds: 4), () {
      if (state.overlayVisible) {
        state = state.copyWith(overlayVisible: false);
      }
    });
  }

  // ─── UI Lock (AC-05, UX §14) ──────────────────────────────────────────────

  void toggleUiLock() {
    state = state.copyWith(
      uiLocked: !state.uiLocked,
      overlayVisible: false,
    );
  }

  void unlockUi() {
    state = state.copyWith(uiLocked: false);
  }

  // ─── View Mode ─────────────────────────────────────────────────────────────

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode, halfPageStep: 0);
  }

  /// Auto-detect view mode based on orientation (AC-57..AC-60)
  void updateViewModeForOrientation({
    required bool isLandscape,
    required double screenWidth,
    required bool halfPageTurnEnabled,
  }) {
    ViewMode newMode;
    if (isLandscape && screenWidth >= 600) {
      newMode = ViewMode.twoPage;
    } else if (halfPageTurnEnabled && !isLandscape) {
      newMode = ViewMode.halfPageTurn;
    } else {
      newMode = ViewMode.singlePage;
    }
    if (newMode != state.viewMode) {
      state = state.copyWith(viewMode: newMode, halfPageStep: 0);
    }
  }

  // ─── Stimme (AC-37..AC-42) ────────────────────────────────────────────────

  void changeVoice(String voiceId) {
    state = state.copyWith(
      currentVoiceId: voiceId,
      currentPage: 0,
      halfPageStep: 0,
    );
    hideOverlay();
  }

  // ─── Setlist Navigation (UX §9) ──────────────────────────────────────────

  void loadSetlist(List<SetlistItem> items) {
    state = state.copyWith(
      setlist: items,
      currentSetlistIndex: 0,
    );
  }

  void goToSetlistItem(int index) {
    if (state.setlist == null) return;
    if (index >= 0 && index < state.setlist!.length) {
      state = state.copyWith(
        currentSetlistIndex: index,
        currentPage: 0,
        halfPageStep: 0,
      );
      hideOverlay();
    }
  }

  void _advanceSetlist() {
    if (state.setlist == null || state.currentSetlistIndex == null) return;
    final next = state.currentSetlistIndex! + 1;
    if (next < state.setlist!.length) {
      goToSetlistItem(next);
    }
  }

  // ─── Auto-Scroll ─────────────────────────────────────────────────────────

  void toggleAutoScroll() {
    state = state.copyWith(autoScrollActive: !state.autoScrollActive);
  }

  void setAutoScrollSpeed(double speed) {
    state = state.copyWith(autoScrollSpeed: speed.clamp(10.0, 200.0));
  }

  // ─── Zoom Memory (AC-50, AC-51) ───────────────────────────────────────────

  void setPageZoom(int pageNumber, double zoom) {
    final memory = Map<int, double>.from(state.pageZoomMemory);
    memory[pageNumber] = zoom;
    state = state.copyWith(pageZoomMemory: memory);
  }

  void resetPageZoom(int pageNumber) {
    final memory = Map<int, double>.from(state.pageZoomMemory);
    memory.remove(pageNumber);
    state = state.copyWith(pageZoomMemory: memory);
  }
}
