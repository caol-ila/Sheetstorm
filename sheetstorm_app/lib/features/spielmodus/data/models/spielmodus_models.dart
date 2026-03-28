import 'package:flutter/material.dart';

/// Farbmodus für die Notenansicht (AC-30 bis AC-36)
enum Farbmodus {
  standard,
  nacht,
  sepia;

  String get label => switch (this) {
        standard => 'Standard',
        nacht => 'Nachtmodus',
        sepia => 'Sepia',
      };

  IconData get icon => switch (this) {
        standard => Icons.wb_sunny_outlined,
        nacht => Icons.nights_stay_outlined,
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
  privat,
  stimme,
  orchester;

  String get label => switch (this) {
        privat => 'Privat',
        stimme => 'Stimme',
        orchester => 'Orchester',
      };

  Color get color => switch (this) {
        privat => const Color(0xFF16A34A),
        stimme => const Color(0xFF1A56DB),
        orchester => const Color(0xFFD97706),
      };

  /// Hellere Farben für Nachtmodus (AC-35)
  Color get nightModeColor => switch (this) {
        privat => const Color(0xFF86EFAC),
        stimme => const Color(0xFF93C5FD),
        orchester => const Color(0xFFFCD34D),
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
    required this.stueckId,
    this.stimmeId,
    this.localFilePath,
    this.downloadUrl,
    this.autoRotationAngle = 0.0,
    this.zoomOverride,
    this.annotations = const [],
  });

  final int pageNumber;
  final String stueckId;
  final String? stimmeId;
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
      stueckId: stueckId,
      stimmeId: stimmeId,
      localFilePath: localFilePath,
      downloadUrl: downloadUrl,
      autoRotationAngle: autoRotationAngle ?? this.autoRotationAngle,
      zoomOverride: zoomOverride ?? this.zoomOverride,
      annotations: annotations ?? this.annotations,
    );
  }
}

/// Stimme (Instrument-Part) eines Stücks
class Stimme {
  const Stimme({
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
    required this.stueckId,
    required this.title,
    required this.orderIndex,
    this.stimmeId,
  });

  final String stueckId;
  final String title;
  final int orderIndex;
  final String? stimmeId;
}

/// Spielmodus-Einstellungen (Spec §4, Datenmodell §7.3)
class SpielmodusEinstellungen {
  const SpielmodusEinstellungen({
    this.halfPageTurn = true,
    this.farbmodus = Farbmodus.standard,
    this.helligkeit = 1.0,
    this.zoomOverride,
    this.annotationPrivat = true,
    this.annotationStimme = true,
    this.annotationOrchester = true,
    this.halfPageSplit = 0.5,
  });

  final bool halfPageTurn;
  final Farbmodus farbmodus;

  /// 0.6–1.0 (AC-34)
  final double helligkeit;
  final double? zoomOverride;
  final bool annotationPrivat;
  final bool annotationStimme;
  final bool annotationOrchester;

  /// Half-page split ratio: 0.4, 0.5, 0.6 (AC-17)
  final double halfPageSplit;

  SpielmodusEinstellungen copyWith({
    bool? halfPageTurn,
    Farbmodus? farbmodus,
    double? helligkeit,
    double? zoomOverride,
    bool? annotationPrivat,
    bool? annotationStimme,
    bool? annotationOrchester,
    double? halfPageSplit,
  }) {
    return SpielmodusEinstellungen(
      halfPageTurn: halfPageTurn ?? this.halfPageTurn,
      farbmodus: farbmodus ?? this.farbmodus,
      helligkeit: helligkeit ?? this.helligkeit,
      zoomOverride: zoomOverride ?? this.zoomOverride,
      annotationPrivat: annotationPrivat ?? this.annotationPrivat,
      annotationStimme: annotationStimme ?? this.annotationStimme,
      annotationOrchester: annotationOrchester ?? this.annotationOrchester,
      halfPageSplit: halfPageSplit ?? this.halfPageSplit,
    );
  }
}
