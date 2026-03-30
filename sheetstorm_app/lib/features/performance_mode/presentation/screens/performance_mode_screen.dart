import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/core/theme/app_colors.dart';
import 'package:sheetstorm/core/theme/app_tokens.dart';
import 'package:sheetstorm/features/performance_mode/application/auto_scroll_notifier.dart';
import 'package:sheetstorm/features/performance_mode/application/performance_mode_notifier.dart';
import 'package:sheetstorm/features/performance_mode/application/performance_mode_settings_notifier.dart';
import 'package:sheetstorm/features/performance_mode/data/models/performance_mode_models.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/auto_scroll_control_bar.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/context_settings_sheet.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/half_page_turn_view.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/night_mode_filter.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/page_gesture_detector.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/setlist_navigation_sheet.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/sheet_music_page_view.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/performance_mode_overlay.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/voice_bottom_sheet.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/two_page_view.dart';
import 'package:sheetstorm/features/performance_mode/presentation/widgets/ui_lock_overlay.dart';
import 'package:sheetstorm/features/annotations/application/annotation_notifier.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/annotation_layer.dart';
import 'package:sheetstorm/features/annotations/presentation/widgets/layer_toggle_panel.dart';

/// Performance-Modus Screen — Focus-First (ux-design.md § 1.1)
///
/// Core features:
/// - Fullscreen distraction-free sheet music display (AC-01..AC-05)
/// - Asymmetric tap zones: 40% back / 60% forward (AC-06..AC-12)
/// - Half-page-turn with configurable split (AC-13..AC-20)
/// - Two-page mode for tablet landscape (Spec §5.2)
/// - Night/Sepia mode with brightness control (AC-30..AC-36)
/// - Overlay with stimme, settings, lock (AC-52..AC-56)
/// - UI Lock mode (AC-05)
/// - Keyboard/mouse support for desktop (AC-09, AC-10)
/// - Setlist navigation (UX §9)
/// - Auto-scroll for continuous play
/// - Zoom memory per page (AC-50)
class PerformanceModeScreen extends ConsumerStatefulWidget {
  const PerformanceModeScreen({super.key, required this.sheetId});
  final String sheetId;

  @override
  ConsumerState<PerformanceModeScreen> createState() => _PerformanceModeScreenState();
}

class _PerformanceModeScreenState extends ConsumerState<PerformanceModeScreen>
    with WidgetsBindingObserver {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fullscreen + Wake Lock (AC-01, AC-03)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Request focus for keyboard events (AC-09)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Handle orientation changes (AC-57..AC-60)
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateViewMode();
    });
  }

  void _updateViewMode() {
    final size = MediaQuery.sizeOf(context);
    final settings = ref.read(performanceModeSettingsProvider);
    ref.read(performanceModeProvider(widget.sheetId).notifier)
        .updateViewModeForOrientation(
      isLandscape: size.width > size.height,
      screenWidth: size.width,
      halfPageTurnEnabled: settings.halfPageTurn,
    );
  }

  /// Keyboard navigation (AC-09, AC-10)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final notifier =
        ref.read(performanceModeProvider(widget.sheetId).notifier);

    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight ||
      LogicalKeyboardKey.space ||
      LogicalKeyboardKey.pageDown =>
        () {
          notifier.nextPage();
          return KeyEventResult.handled;
        }(),
      LogicalKeyboardKey.arrowLeft ||
      LogicalKeyboardKey.pageUp =>
        () {
          notifier.previousPage();
          return KeyEventResult.handled;
        }(),
      LogicalKeyboardKey.escape =>
        () {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }(),
      LogicalKeyboardKey.keyF =>
        () {
          notifier.toggleOverlay();
          return KeyEventResult.handled;
        }(),
      _ => KeyEventResult.ignored,
    };
  }

  @override
  Widget build(BuildContext context) {
    final spielState = ref.watch(performanceModeProvider(widget.sheetId));
    final settings = ref.watch(performanceModeSettingsProvider);
    final autoScrollState = ref.watch(autoScrollProvider);
    final notifier =
        ref.read(performanceModeProvider(widget.sheetId).notifier);
    final settingsNotifier =
        ref.read(performanceModeSettingsProvider.notifier);
    final autoScrollNotifier = ref.read(autoScrollProvider.notifier);

    // Determine background color based on ColorMode
    final bgColor = switch (settings.colorMode) {
      ColorMode.standard => AppColors.background,
      ColorMode.night => AppColors.darkBackground,
      ColorMode.sepia => const Color(0xFFF5E6D0),
    };

    // Update view mode on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && spielState.viewMode == ViewMode.singlePage) {
        _updateViewMode();
      }
    });

    if (spielState.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (spielState.errorMessage != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                spielState.errorMessage!,
                style: TextStyle(
                  color: settings.colorMode == ColorMode.night
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Zurück'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        // Mouse scroll support (AC-10)
        child: Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dy > 0) {
                notifier.nextPage();
              } else if (event.scrollDelta.dy < 0) {
                notifier.previousPage();
              }
            }
          },
          child: Stack(
            children: [
              // ── Sheet Music Content ──────────────────────────────────────
              Positioned.fill(
                child: NightModeFilter(
                  colorMode: settings.colorMode,
                  brightness: settings.brightness,
                  child: _buildPageContent(spielState, settings),
                ),
              ),

              // ── Gesture Detection Layer ──────────────────────────────────
              Positioned.fill(
                child: PageGestureDetector(
                  isLocked: spielState.uiLocked,
                  onNextPage: () {
                    autoScrollNotifier.onUserInteraction();
                    notifier.nextPage();
                  },
                  onPreviousPage: () {
                    autoScrollNotifier.onUserInteraction();
                    notifier.previousPage();
                  },
                  onToggleOverlay: notifier.toggleOverlay,
                  onDoubleTap: () =>
                      notifier.resetPageZoom(spielState.currentPage),
                  onZoomChanged: (zoom) =>
                      notifier.setPageZoom(spielState.currentPage, zoom),
                ),
              ),

              // ── Overlay (top + bottom bars) ──────────────────────────────
              PerformanceModeOverlay(
                visible: spielState.overlayVisible,
                pageIndicator: spielState.pageIndicator,
                nightModeIcon: settings.colorMode.icon,
                nightModeLabel: settings.colorMode.label,
                onBack: () => Navigator.of(context).pop(),
                onSettings: () => _showSettings(context, settings, settingsNotifier),
                onStimme: () => _showStimmeSheet(context, spielState, notifier),
                onNightMode: settingsNotifier.cycleColorMode,
                onLock: notifier.toggleUiLock,
                onPageIndicatorTap: () =>
                    _showSetlistNav(context, spielState, notifier),
                onInteraction: notifier.resetOverlayTimer,
              ),

              // ── UI Lock Overlay ──────────────────────────────────────────
              UiLockOverlay(
                isLocked: spielState.uiLocked,
                onUnlockTriggered: notifier.unlockUi,
              ),

              // ── Auto-Scroll Control Bar (UX §2.2, 48px bottom) ──────────
              if (!autoScrollState.isIdle || spielState.autoScrollActive)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AutoScrollControlBar(),
                ),

              // ── Page indicator (subtle, bottom center) ───────────────────
              if (!spielState.overlayVisible &&
                  !spielState.uiLocked &&
                  autoScrollState.isIdle)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: _PageDots(
                    currentPage: spielState.currentPage,
                    totalPages: spielState.totalPages,
                    isNightMode: settings.colorMode == ColorMode.night,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the main page content based on current ViewMode.
  Widget _buildPageContent(
    PerformanceModeState spielState,
    PerformanceModeSettings settings,
  ) {
    if (spielState.pages.isEmpty) {
      return Center(
        child: Text(
          'Keine Seiten verfügbar',
          style: TextStyle(
            color: settings.colorMode == ColorMode.night
                ? Colors.white54
                : AppColors.textSecondary,
          ),
        ),
      );
    }

    final currentPage = spielState.pages[spielState.currentPage];

    return switch (spielState.viewMode) {
      ViewMode.halfPageTurn => _buildHalfPageView(spielState, settings, currentPage),
      ViewMode.twoPage => _buildTwoPageView(spielState, settings, currentPage),
      ViewMode.singlePage => _buildSinglePageView(spielState, settings, currentPage),
    };
  }

  Widget _buildSinglePageView(
    PerformanceModeState spielState,
    PerformanceModeSettings settings,
    SheetPage currentPage,
  ) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppCurves.enter,
      switchOutCurve: AppCurves.exit,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: SheetMusicPageView(
        key: ValueKey('page_${spielState.currentPage}'),
        page: currentPage,
        colorMode: settings.colorMode,
        zoomOverride: spielState.pageZoomMemory[spielState.currentPage],
      ),
    );
  }

  Widget _buildHalfPageView(
    PerformanceModeState spielState,
    PerformanceModeSettings settings,
    SheetPage currentPage,
  ) {
    // In half-page step 0: show full current page
    // In half-page step 1: show bottom current + top next (AC-13)
    if (spielState.halfPageStep == 0) {
      return SheetMusicPageView(
        key: ValueKey('page_${spielState.currentPage}_full'),
        page: currentPage,
        colorMode: settings.colorMode,
      );
    }

    final nextPage = spielState.currentPage + 1 < spielState.totalPages
        ? spielState.pages[spielState.currentPage + 1]
        : null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: HalfPageTurnView(
        key: ValueKey('half_${spielState.currentPage}_${spielState.halfPageStep}'),
        currentPage: currentPage,
        nextPage: nextPage,
        colorMode: settings.colorMode,
        splitRatio: settings.halfPageSplit,
      ),
    );
  }

  Widget _buildTwoPageView(
    PerformanceModeState spielState,
    PerformanceModeSettings settings,
    SheetPage currentPage,
  ) {
    final rightPage = spielState.currentPage + 1 < spielState.totalPages
        ? spielState.pages[spielState.currentPage + 1]
        : null;

    return AnimatedSwitcher(
      duration: AppDurations.fast,
      child: TwoPageView(
        key: ValueKey('two_${spielState.currentPage}'),
        leftPage: currentPage,
        rightPage: rightPage,
        colorMode: settings.colorMode,
      ),
    );
  }

  // ─── Bottom Sheets ─────────────────────────────────────────────────────────

  void _showSettings(
    BuildContext context,
    PerformanceModeSettings settings,
    PerformanceModeSettingsNotifier settingsNotifier,
  ) {
    final notifier =
        ref.read(performanceModeProvider(widget.sheetId).notifier);
    notifier.resetOverlayTimer();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContextSettingsSheet(
        settings: settings,
        onHalfPageTurnChanged: () {
          settingsNotifier.toggleHalfPageTurn();
          _updateViewMode();
        },
        onColorModeChanged: settingsNotifier.setColorMode,
        onHelligkeitChanged: settingsNotifier.setBrightness,
        onAnnotationLayerChanged: settingsNotifier.toggleAnnotationLayer,
        onHalfPageSplitChanged: settingsNotifier.setHalfPageSplit,
      ),
    );
  }

  void _showStimmeSheet(
    BuildContext context,
    PerformanceModeState spielState,
    PerformanceModeNotifier notifier,
  ) {
    notifier.resetOverlayTimer();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceBottomSheet(
        voices: spielState.voices,
        currentVoiceId: spielState.currentVoiceId,
        onStimmeSelected: notifier.changeVoice,
      ),
    );
  }

  void _showSetlistNav(
    BuildContext context,
    PerformanceModeState spielState,
    PerformanceModeNotifier notifier,
  ) {
    if (spielState.setlist == null || spielState.setlist!.isEmpty) return;
    notifier.resetOverlayTimer();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetlistNavigationSheet(
        setlist: spielState.setlist!,
        currentIndex: spielState.currentSetlistIndex ?? 0,
        onItemSelected: notifier.goToSetlistItem,
      ),
    );
  }
}

/// Minimal page position indicator dots
class _PageDots extends StatelessWidget {
  const _PageDots({
    required this.currentPage,
    required this.totalPages,
    required this.isNightMode,
  });

  final int currentPage;
  final int totalPages;
  final bool isNightMode;

  @override
  Widget build(BuildContext context) {
    // Only show dots for reasonable page counts
    if (totalPages <= 1 || totalPages > 20) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (i) {
        final isActive = i == currentPage;
        final color = isNightMode ? Colors.white : Colors.black;
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: isActive ? 8 : 4,
          height: 4,
          decoration: BoxDecoration(
            color: color.withOpacity(isActive ? 0.5 : 0.15),
            borderRadius: AppSpacing.roundedFull,
          ),
        );
      }),
    );
  }
}
