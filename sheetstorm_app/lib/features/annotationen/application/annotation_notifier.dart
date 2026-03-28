import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sheetstorm/features/annotationen/data/models/annotation_models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AnnotationState {
  const AnnotationState({
    this.annotations = const [],
    this.layerVisibility = const LayerVisibility(),
    this.undoStack = const [],
    this.redoStack = const [],
    this.isAnnotationMode = false,
    this.currentPageIndex = 0,
  });

  /// Alle Annotationen für das aktuelle Stück
  final List<Annotation> annotations;

  /// Layer-Sichtbarkeit (non-destruktiv)
  final LayerVisibility layerVisibility;

  /// Undo-Stack (session-lokal)
  final List<UndoAction> undoStack;

  /// Redo-Stack (session-lokal)
  final List<UndoAction> redoStack;

  /// Ob der Annotationsmodus aktiv ist
  final bool isAnnotationMode;

  /// Aktuelle Seitennummer
  final int currentPageIndex;

  /// Sichtbare Annotationen für aktuelle Seite (gefiltert nach Sichtbarkeit)
  List<Annotation> get visibleAnnotations => annotations
      .where((a) =>
          a.pageIndex == currentPageIndex &&
          layerVisibility.isVisible(a.level))
      .toList();

  /// Alle Annotationen für eine bestimmte Seite
  List<Annotation> annotationsForPage(int page) =>
      annotations.where((a) => a.pageIndex == page).toList();

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  AnnotationState copyWith({
    List<Annotation>? annotations,
    LayerVisibility? layerVisibility,
    List<UndoAction>? undoStack,
    List<UndoAction>? redoStack,
    bool? isAnnotationMode,
    int? currentPageIndex,
  }) =>
      AnnotationState(
        annotations: annotations ?? this.annotations,
        layerVisibility: layerVisibility ?? this.layerVisibility,
        undoStack: undoStack ?? this.undoStack,
        redoStack: redoStack ?? this.redoStack,
        isAnnotationMode: isAnnotationMode ?? this.isAnnotationMode,
        currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

/// Manages annotation state for a single Stück (piece).
/// Provider uses `family` to scope per stuckId.
class AnnotationNotifier extends Notifier<AnnotationState> {
  @override
  AnnotationState build() => const AnnotationState();

  /// Annotationsmodus ein-/ausschalten
  void toggleAnnotationMode() {
    state = state.copyWith(isAnnotationMode: !state.isAnnotationMode);
  }

  void enterAnnotationMode() {
    state = state.copyWith(isAnnotationMode: true);
  }

  void exitAnnotationMode() {
    state = state.copyWith(isAnnotationMode: false);
  }

  /// Aktuelle Seite setzen
  void setPage(int pageIndex) {
    state = state.copyWith(currentPageIndex: pageIndex);
  }

  // ─── CRUD ───────────────────────────────────────────────────────────────────

  /// Neue Annotation hinzufügen (mit Undo-Tracking)
  void addAnnotation(Annotation annotation) {
    final updated = [...state.annotations, annotation];
    final undoAction = UndoAction(
      type: UndoActionType.add,
      annotation: annotation,
    );
    state = state.copyWith(
      annotations: updated,
      undoStack: [...state.undoStack, undoAction],
      redoStack: [], // Redo-Stack leeren nach neuer Aktion
    );
  }

  /// Annotation entfernen (mit Undo-Tracking)
  void removeAnnotation(String annotationId) {
    final matches = state.annotations.where((a) => a.id == annotationId);
    if (matches.isEmpty) return;
    final annotation = matches.first;

    final updated = state.annotations.where((a) => a.id != annotationId).toList();
    final undoAction = UndoAction(
      type: UndoActionType.remove,
      annotation: annotation,
    );
    state = state.copyWith(
      annotations: updated,
      undoStack: [...state.undoStack, undoAction],
      redoStack: [],
    );
  }

  /// Abgeschlossenen Strich als Annotation hinzufügen
  void commitStroke({
    required List<StrokePoint> points,
    required AnnotationLevel level,
    required AnnotationTool tool,
    required double strokeWidth,
    required double opacity,
  }) {
    if (points.isEmpty) return;

    final bbox = Annotation.computeBBox(points);
    final annotation = Annotation(
      id: _generateId(),
      level: level,
      tool: tool,
      pageIndex: state.currentPageIndex,
      bbox: bbox,
      createdAt: DateTime.now(),
      points: List.unmodifiable(points),
      opacity: opacity,
      strokeWidth: strokeWidth,
    );
    addAnnotation(annotation);
  }

  /// Text-Annotation hinzufügen
  void addTextAnnotation({
    required String text,
    required double x,
    required double y,
    required AnnotationLevel level,
  }) {
    if (text.isEmpty) return;

    final annotation = Annotation(
      id: _generateId(),
      level: level,
      tool: AnnotationTool.text,
      pageIndex: state.currentPageIndex,
      bbox: BBox(x: x, y: y, width: 0.15, height: 0.03),
      createdAt: DateTime.now(),
      text: text.length > 200 ? text.substring(0, 200) : text,
    );
    addAnnotation(annotation);
  }

  /// Stempel-Annotation hinzufügen
  void addStampAnnotation({
    required String category,
    required String value,
    required double x,
    required double y,
    required AnnotationLevel level,
  }) {
    final annotation = Annotation(
      id: _generateId(),
      level: level,
      tool: AnnotationTool.stamp,
      pageIndex: state.currentPageIndex,
      bbox: BBox(x: x - 0.02, y: y - 0.015, width: 0.04, height: 0.03),
      createdAt: DateTime.now(),
      stampCategory: category,
      stampValue: value,
    );
    addAnnotation(annotation);
  }

  /// Radieren: Lösche Annotationen, die den Radierer-Pfad schneiden
  void eraseAt({
    required double x,
    required double y,
    required double radius,
    required AnnotationLevel activeLevel,
  }) {
    final toRemove = <String>[];
    for (final a in state.visibleAnnotations) {
      // Nur eigene Ebene radierbar (UX-Spec: Radierer nur für eigene Annotationen)
      if (a.level != activeLevel) continue;

      if (_hitTest(a, x, y, radius)) {
        toRemove.add(a.id);
      }
    }
    for (final id in toRemove) {
      removeAnnotation(id);
    }
  }

  bool _hitTest(Annotation a, double x, double y, double radius) {
    // Für Punkt-basierte Annotationen: prüfe ob ein Punkt nah genug ist
    if (a.points.isNotEmpty) {
      for (final p in a.points) {
        final dx = p.x - x;
        final dy = p.y - y;
        if (dx * dx + dy * dy <= radius * radius) return true;
      }
      return false;
    }
    // Für BBox-basierte Annotationen (Text, Stempel)
    return x >= a.bbox.x &&
        x <= a.bbox.x + a.bbox.width &&
        y >= a.bbox.y &&
        y <= a.bbox.y + a.bbox.height;
  }

  // ─── Undo / Redo ────────────────────────────────────────────────────────────

  void undo() {
    if (!state.canUndo) return;
    final action = state.undoStack.last;
    final newUndoStack = state.undoStack.sublist(0, state.undoStack.length - 1);

    List<Annotation> newAnnotations;
    switch (action.type) {
      case UndoActionType.add:
        // Undo add → remove
        newAnnotations =
            state.annotations.where((a) => a.id != action.annotation.id).toList();
      case UndoActionType.remove:
        // Undo remove → add back
        newAnnotations = [...state.annotations, action.annotation];
    }

    // Push original action to redo (redo re-executes the original)
    state = state.copyWith(
      annotations: newAnnotations,
      undoStack: newUndoStack,
      redoStack: [...state.redoStack, action],
    );
  }

  void redo() {
    if (!state.canRedo) return;
    final action = state.redoStack.last;
    final newRedoStack = state.redoStack.sublist(0, state.redoStack.length - 1);

    // Execute the action as-is (redo = re-do what was originally done)
    List<Annotation> newAnnotations;
    switch (action.type) {
      case UndoActionType.add:
        newAnnotations = [...state.annotations, action.annotation];
      case UndoActionType.remove:
        newAnnotations =
            state.annotations.where((a) => a.id != action.annotation.id).toList();
    }

    // Push same action back to undo stack
    state = state.copyWith(
      annotations: newAnnotations,
      undoStack: [...state.undoStack, action],
      redoStack: newRedoStack,
    );
  }

  // ─── Layer Visibility ───────────────────────────────────────────────────────

  void toggleLayerVisibility(AnnotationLevel level) {
    state = state.copyWith(
      layerVisibility: state.layerVisibility.toggle(level),
    );
  }

  void setLayerVisibility(LayerVisibility visibility) {
    state = state.copyWith(layerVisibility: visibility);
  }

  // ─── Level Change ───────────────────────────────────────────────────────────

  /// Annotation in andere Ebene verschieben (UX-Spec §4.6)
  void changeAnnotationLevel(String annotationId, AnnotationLevel newLevel) {
    final idx = state.annotations.indexWhere((a) => a.id == annotationId);
    if (idx == -1) return;

    final old = state.annotations[idx];
    final updated = old.copyWith(level: newLevel);
    final newAnnotations = [...state.annotations];
    newAnnotations[idx] = updated;

    state = state.copyWith(annotations: newAnnotations);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  static final _random = Random();
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'annot_${timestamp}_$rand';
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

/// Scoped per stuckId (Stück-ID)
final annotationProvider = NotifierProvider.family<
    AnnotationNotifier, AnnotationState, String>(
  (_) => AnnotationNotifier(),
);
