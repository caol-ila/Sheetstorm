import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AnnotationToolbarState {
  const AnnotationToolbarState({
    this.activeTool = AnnotationTool.pencil,
    this.activeLevel = AnnotationLevel.privat,
    this.strokeThickness = StrokeThickness.normal,
    this.opacity = 1.0,
    this.previousTool,
    this.isStampPickerOpen = false,
    this.selectedStampCategory = 'dynamik',
    this.selectedStampValue,
    this.toolbarDockPosition = ToolbarDock.bottom,
    this.isToolbarVisible = true,
  });

  final AnnotationTool activeTool;
  final AnnotationLevel activeLevel;
  final StrokeThickness strokeThickness;
  final double opacity;

  /// Letztes Werkzeug vor Radierer (für Apple Pencil Doppeltipp)
  final AnnotationTool? previousTool;

  /// Stempel-Picker offen?
  final bool isStampPickerOpen;
  final String selectedStampCategory;
  final String? selectedStampValue;

  /// Toolbar-Position (verschiebbar auf Tablet)
  final ToolbarDock toolbarDockPosition;
  final bool isToolbarVisible;

  /// Effektive Opazität basierend auf Werkzeug
  double get effectiveOpacity =>
      activeTool == AnnotationTool.highlighter ? 0.4 : opacity;

  /// Effektive Strichdicke basierend auf Werkzeug
  double get effectiveStrokeWidth =>
      activeTool == AnnotationTool.highlighter
          ? strokeThickness.width * 4.0 // Textmarker ist breiter
          : strokeThickness.width;

  AnnotationToolbarState copyWith({
    AnnotationTool? activeTool,
    AnnotationLevel? activeLevel,
    StrokeThickness? strokeThickness,
    double? opacity,
    AnnotationTool? previousTool,
    bool? isStampPickerOpen,
    String? selectedStampCategory,
    String? selectedStampValue,
    ToolbarDock? toolbarDockPosition,
    bool? isToolbarVisible,
  }) =>
      AnnotationToolbarState(
        activeTool: activeTool ?? this.activeTool,
        activeLevel: activeLevel ?? this.activeLevel,
        strokeThickness: strokeThickness ?? this.strokeThickness,
        opacity: opacity ?? this.opacity,
        previousTool: previousTool ?? this.previousTool,
        isStampPickerOpen: isStampPickerOpen ?? this.isStampPickerOpen,
        selectedStampCategory:
            selectedStampCategory ?? this.selectedStampCategory,
        selectedStampValue: selectedStampValue ?? this.selectedStampValue,
        toolbarDockPosition: toolbarDockPosition ?? this.toolbarDockPosition,
        isToolbarVisible: isToolbarVisible ?? this.isToolbarVisible,
      );
}

enum ToolbarDock { left, right, top, bottom }

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AnnotationToolbarNotifier extends Notifier<AnnotationToolbarState> {
  @override
  AnnotationToolbarState build() => const AnnotationToolbarState();

  void selectTool(AnnotationTool tool) {
    if (tool == AnnotationTool.stamp) {
      state = state.copyWith(
        activeTool: tool,
        previousTool: state.activeTool,
        isStampPickerOpen: true,
      );
    } else {
      state = state.copyWith(
        activeTool: tool,
        previousTool: state.activeTool,
        isStampPickerOpen: false,
      );
    }
  }

  void selectLevel(AnnotationLevel level) {
    state = state.copyWith(activeLevel: level);
  }

  void setStrokeThickness(StrokeThickness thickness) {
    state = state.copyWith(strokeThickness: thickness);
  }

  void setOpacity(double opacity) {
    state = state.copyWith(opacity: opacity.clamp(0.0, 1.0).toDouble());
  }

  /// Apple Pencil Doppeltipp: zwischen letztem Werkzeug und Radierer wechseln
  void toggleEraser() {
    if (state.activeTool == AnnotationTool.eraser) {
      state = state.copyWith(
        activeTool: state.previousTool ?? AnnotationTool.pencil,
      );
    } else {
      state = state.copyWith(
        activeTool: AnnotationTool.eraser,
        previousTool: state.activeTool,
      );
    }
  }

  void selectStamp(String category, String value) {
    state = state.copyWith(
      selectedStampCategory: category,
      selectedStampValue: value,
      isStampPickerOpen: false,
    );
  }

  void toggleStampPicker() {
    state = state.copyWith(isStampPickerOpen: !state.isStampPickerOpen);
  }

  void closeStampPicker() {
    state = state.copyWith(isStampPickerOpen: false);
  }

  void setDockPosition(ToolbarDock position) {
    state = state.copyWith(toolbarDockPosition: position);
  }

  void showToolbar() {
    state = state.copyWith(isToolbarVisible: true);
  }

  void hideToolbar() {
    state = state.copyWith(isToolbarVisible: false);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final annotationToolbarProvider = NotifierProvider<
    AnnotationToolbarNotifier, AnnotationToolbarState>(
  AnnotationToolbarNotifier.new,
);
