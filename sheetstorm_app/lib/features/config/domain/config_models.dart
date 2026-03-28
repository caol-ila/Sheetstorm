/// Domain models for the 3-level configuration system — Issue #35
///
/// Ebenen: Kapelle (Blau) → Nutzer (Grün) → Gerät (Orange)
/// Override: Gerät > Nutzer > Kapelle > System-Default

/// The three configuration levels in Sheetstorm.
enum ConfigEbene {
  kapelle,
  nutzer,
  geraet;

  String get label {
    switch (this) {
      case ConfigEbene.kapelle:
        return 'Kapelle';
      case ConfigEbene.nutzer:
        return 'Persönlich';
      case ConfigEbene.geraet:
        return 'Gerät';
    }
  }

  String get beschreibung {
    switch (this) {
      case ConfigEbene.kapelle:
        return 'Kapelle-Einstellung';
      case ConfigEbene.nutzer:
        return 'Deine Einstellung';
      case ConfigEbene.geraet:
        return 'Geräte-spezifisch';
    }
  }
}

/// A raw configuration entry from any level.
class ConfigEntry {
  final String schluessel;
  final ConfigEbene ebene;
  final dynamic wert;
  final int version;
  final DateTime aktualisiertAm;
  final String? referenzId;

  const ConfigEntry({
    required this.schluessel,
    required this.ebene,
    required this.wert,
    this.version = 1,
    required this.aktualisiertAm,
    this.referenzId,
  });

  factory ConfigEntry.fromJson(Map<String, dynamic> json) => ConfigEntry(
        schluessel: json['schluessel'] as String,
        ebene: ConfigEbene.values.byName(json['ebene'] as String),
        wert: json['wert'],
        version: json['version'] as int? ?? 1,
        aktualisiertAm: json['aktualisiert_am'] != null
            ? DateTime.parse(json['aktualisiert_am'] as String)
            : DateTime.now(),
        referenzId: json['referenz_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'schluessel': schluessel,
        'ebene': ebene.name,
        'wert': wert,
        'version': version,
        'aktualisiert_am': aktualisiertAm.toIso8601String(),
        'referenz_id': referenzId,
      };

  ConfigEntry copyWith({
    String? schluessel,
    ConfigEbene? ebene,
    dynamic wert,
    int? version,
    DateTime? aktualisiertAm,
    String? referenzId,
  }) =>
      ConfigEntry(
        schluessel: schluessel ?? this.schluessel,
        ebene: ebene ?? this.ebene,
        wert: wert ?? this.wert,
        version: version ?? this.version,
        aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
        referenzId: referenzId ?? this.referenzId,
      );
}

/// A policy that can lock a setting at the Kapelle level.
class ConfigPolicy {
  final String schluessel;
  final dynamic wert;
  final bool enforced;
  final DateTime aktualisiertAm;

  const ConfigPolicy({
    required this.schluessel,
    required this.wert,
    this.enforced = false,
    required this.aktualisiertAm,
  });

  factory ConfigPolicy.fromJson(Map<String, dynamic> json) => ConfigPolicy(
        schluessel: json['schluessel'] as String,
        wert: json['wert'],
        enforced: json['enforced'] as bool? ?? false,
        aktualisiertAm: json['aktualisiert_am'] != null
            ? DateTime.parse(json['aktualisiert_am'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'schluessel': schluessel,
        'wert': wert,
        'enforced': enforced,
        'aktualisiert_am': aktualisiertAm.toIso8601String(),
      };
}

/// A fully resolved configuration value with provenance information.
class ResolvedConfigValue {
  final String schluessel;
  final dynamic wert;
  final ConfigEbene herkunft;
  final bool istGesperrt;
  final dynamic kapelleDefault;
  final dynamic nutzerWert;
  final dynamic geraetWert;
  final dynamic systemDefault;

  const ResolvedConfigValue({
    required this.schluessel,
    required this.wert,
    required this.herkunft,
    this.istGesperrt = false,
    this.kapelleDefault,
    this.nutzerWert,
    this.geraetWert,
    this.systemDefault,
  });

  /// Whether this value is inherited from a higher level (not set at the current view level).
  bool isInherited(ConfigEbene viewLevel) => herkunft != viewLevel;

  /// Whether the user can override this value.
  bool get canOverride => !istGesperrt;

  ResolvedConfigValue copyWith({
    String? schluessel,
    dynamic wert,
    ConfigEbene? herkunft,
    bool? istGesperrt,
    dynamic kapelleDefault,
    dynamic nutzerWert,
    dynamic geraetWert,
    dynamic systemDefault,
  }) =>
      ResolvedConfigValue(
        schluessel: schluessel ?? this.schluessel,
        wert: wert ?? this.wert,
        herkunft: herkunft ?? this.herkunft,
        istGesperrt: istGesperrt ?? this.istGesperrt,
        kapelleDefault: kapelleDefault ?? this.kapelleDefault,
        nutzerWert: nutzerWert ?? this.nutzerWert,
        geraetWert: geraetWert ?? this.geraetWert,
        systemDefault: systemDefault ?? this.systemDefault,
      );
}

/// Pending sync entry for offline changes.
class PendingSyncEntry {
  final int? id;
  final String schluessel;
  final dynamic wert;
  final int version;
  final DateTime timestamp;
  final bool synced;

  const PendingSyncEntry({
    this.id,
    required this.schluessel,
    required this.wert,
    required this.version,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'schluessel': schluessel,
        'wert': wert,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Undo action for the auto-save toast.
class ConfigUndoAction {
  final String schluessel;
  final ConfigEbene ebene;
  final dynamic alterWert;
  final dynamic neuerWert;
  final DateTime zeitstempel;

  const ConfigUndoAction({
    required this.schluessel,
    required this.ebene,
    required this.alterWert,
    required this.neuerWert,
    required this.zeitstempel,
  });
}
