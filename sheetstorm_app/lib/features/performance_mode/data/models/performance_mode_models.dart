import 'package:flutter/material.dart';

/// ColorMode für die Notenansicht (AC-30 bis AC-36)
enum ColorMode {
  standard,
  night,
  sepia;

  String get label => switch (this) {
        standard => 'Standard',
        night => 'Nachtmodus',
        sepia => 'Sepia',
      };

  IconData get icon => switch (this) {
        standard => Icons.wb_sunny_outlined,
        night => Icons.nights_stay_outlined,
        sepia => Icons.filter_vintage_outlined,
      };
}

/// Ansichtsmodus je nach Geräteausrichtung (Spec §5)
enum ViewMode {
  /// Einzelne Seite, volle Breite (Phone Portrait)
  singlePage,

  /// Half-Page-Turn: untere Hälfte aktuelle + obere Hälfte nächste (AC-13..AC-20)
  halfPageTurn,

  /// Zwei Seiten nebeneinander (Tablet Landscape, AC §5.2)
  twoPage,
}

/// Annotationsebene (3-Ebenen-System aus decisions.md)
enum AnnotationLayer {
  private,
  voice,
  orchestra;

  String get label => switch (this) {
        AnnotationLayer.private => 'Privat',
        AnnotationLayer.voice => 'Stimme',
        AnnotationLayer.orchestra => 'Orchester',
      };

  Color get color => switch (this) {
        AnnotationLayer.private => const Color(0xFF16A34A),
        AnnotationLayer.voice => const Color(0xFF1A56DB),
        AnnotationLayer.orchestra => const Color(0xFFD97706),
      };

  /// Hellere Farben für Nachtmodus (AC-35)
  Color get nightModeColor => switch (this) {
        AnnotationLayer.private => const Color(0xFF86EFAC),
        AnnotationLayer.voice => const Color(0xFF93C5FD),
        AnnotationLayer.orchestra => const Color(0xFFFCD34D),
      };
}

/// Einzelne Annotation auf einer Seite
class SheetAnnotation {
  const SheetAnnotation({
    required this.id,
    required this.layer,
    required this.relativeX,
    required this.relativeY,
    required this.relativeWidth,
    required this.relativeHeight,
    this.svgPath,
    this.text,
    this.color,
  });

  final String id;
  final AnnotationLayer layer;

  /// Position in relativen Prozentwerten (0.0–1.0)
  final double relativeX;
  final double relativeY;
  final double relativeWidth;
  final double relativeHeight;

  /// SVG path data for drawn annotations
  final String? svgPath;

  /// Text content for text annotations
  final String? text;

  /// Custom color override
  final Color? color;
}

/// Seitenmetadaten mit Cache-Info
class SheetPage {
  const SheetPage({
    required this.pageNumber,
    required this.pieceId,
    this.voiceId,
    this.localFilePath,
    this.downloadUrl,
    this.autoRotationAngle = 0.0,
    this.zoomOverride,
    this.annotations = const [],
  });

  final int pageNumber;
  final String pieceId;
  final String? voiceId;
  final String? localFilePath;
  final String? downloadUrl;

  /// Cached auto-rotation angle in degrees (AC-43..AC-46)
  final double autoRotationAngle;

  /// User zoom override, null = auto-zoom (AC-50)
  final double? zoomOverride;

  final List<SheetAnnotation> annotations;

  SheetPage copyWith({
    double? autoRotationAngle,
    double? zoomOverride,
    List<SheetAnnotation>? annotations,
  }) {
    return SheetPage(
      pageNumber: pageNumber,
      pieceId: pieceId,
      voiceId: voiceId,
      localFilePath: localFilePath,
      downloadUrl: downloadUrl,
      autoRotationAngle: autoRotationAngle ?? this.autoRotationAngle,
      zoomOverride: zoomOverride ?? this.zoomOverride,
      annotations: annotations ?? this.annotations,
    );
  }
}

/// Stimme (Instrument-Part) eines Stücks
class Voice {
  const Voice({
    required this.id,
    required this.name,
    this.isUserInstrument = false,
    this.isFallback = false,
    this.fallbackReason,
  });

  final String id;
  final String name;

  /// True if this matches the user's instruments
  final bool isUserInstrument;

  /// True if auto-selected as fallback (AC §8.3)
  final bool isFallback;
  final String? fallbackReason;
}

/// Setlist-Eintrag für Setlist-Navigation (UX §9)
class SetlistItem {
  const SetlistItem({
    required this.pieceId,
    required this.title,
    required this.orderIndex,
    this.voiceId,
  });

  final String pieceId;
  final String title;
  final int orderIndex;
  final String? voiceId;
}

/// Spielmodus-Einstellungen (Spec §4, Datenmodell §7.3)
class PerformanceModeSettings {
  const PerformanceModeSettings({
    this.halfPageTurn = true,
    this.colorMode = ColorMode.standard,
    this.brightness = 1.0,
    this.zoomOverride,
    this.annotationPrivate = true,
    this.annotationVoice = true,
    this.annotationOrchestra = true,
    this.halfPageSplit = 0.5,
  });

  final bool halfPageTurn;
  final ColorMode colorMode;

  /// 0.6–1.0 (AC-34)
  final double brightness;
  final double? zoomOverride;
  final bool annotationPrivate;
  final bool annotationVoice;
  final bool annotationOrchestra;

  /// Half-page split ratio: 0.4, 0.5, 0.6 (AC-17)
  final double halfPageSplit;

  PerformanceModeSettings copyWith({
    bool? halfPageTurn,
    ColorMode? colorMode,
    double? brightness,
    double? zoomOverride,
    bool? annotationPrivate,
    bool? annotationVoice,
    bool? annotationOrchestra,
    double? halfPageSplit,
  }) {
    return PerformanceModeSettings(
      halfPageTurn: halfPageTurn ?? this.halfPageTurn,
      colorMode: colorMode ?? this.colorMode,
      brightness: brightness ?? this.brightness,
      zoomOverride: zoomOverride ?? this.zoomOverride,
      annotationPrivate: annotationPrivate ?? this.annotationPrivate,
      annotationVoice: annotationVoice ?? this.annotationVoice,
      annotationOrchestra: annotationOrchestra ?? this.annotationOrchestra,
      halfPageSplit: halfPageSplit ?? this.halfPageSplit,
    );
  }
}
