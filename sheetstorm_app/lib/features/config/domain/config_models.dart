/// Domain models for the 3-level configuration system — Issue #35
///
/// Ebenen: Kapelle (Blau) → Nutzer (Grün) → Gerät (Orange)
/// Override: Gerät > Nutzer > Kapelle > System-Default

/// The three configuration levels in Sheetstorm.
enum ConfigLevel {
  band,
  user,
  device;

  String get label {
    switch (this) {
      case ConfigLevel.band:
        return 'Kapelle';
      case ConfigLevel.user:
        return 'Persönlich';
      case ConfigLevel.device:
        return 'Gerät';
    }
  }

  String get description {
    switch (this) {
      case ConfigLevel.band:
        return 'Kapelle-Einstellung';
      case ConfigLevel.user:
        return 'Deine Einstellung';
      case ConfigLevel.device:
        return 'Geräte-spezifisch';
    }
  }
}

/// A raw configuration entry from any level.
class ConfigEntry {
  final String key;
  final ConfigLevel level;
  final dynamic value;
  final int version;
  final DateTime updatedAt;
  final String? referenceId;

  const ConfigEntry({
    required this.key,
    required this.level,
    required this.value,
    this.version = 1,
    required this.updatedAt,
    this.referenceId,
  });

  factory ConfigEntry.fromJson(Map<String, dynamic> json) => ConfigEntry(
        key: json['key'] as String,
        level: ConfigLevel.values.byName(json['level'] as String),
        value: json['value'],
        version: json['version'] as int? ?? 1,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        referenceId: json['reference_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'level': level.name,
        'value': value,
        'version': version,
        'updated_at': updatedAt.toIso8601String(),
        'reference_id': referenceId,
      };

  ConfigEntry copyWith({
    String? key,
    ConfigLevel? level,
    dynamic value,
    int? version,
    DateTime? updatedAt,
    String? referenceId,
  }) =>
      ConfigEntry(
        key: key ?? this.key,
        level: level ?? this.level,
        value: value ?? this.value,
        version: version ?? this.version,
        updatedAt: updatedAt ?? this.updatedAt,
        referenceId: referenceId ?? this.referenceId,
      );
}

/// A policy that can lock a setting at the Kapelle level.
class ConfigPolicy {
  final String key;
  final dynamic value;
  final bool enforced;
  final DateTime updatedAt;

  const ConfigPolicy({
    required this.key,
    required this.value,
    this.enforced = false,
    required this.updatedAt,
  });

  factory ConfigPolicy.fromJson(Map<String, dynamic> json) => ConfigPolicy(
        key: json['key'] as String,
        value: json['value'],
        enforced: json['enforced'] as bool? ?? false,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'enforced': enforced,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// A fully resolved configuration value with provenance information.
class ResolvedConfigValue {
  final String key;
  final dynamic value;
  final ConfigLevel source;
  final bool isLocked;
  final dynamic bandDefault;
  final dynamic userValue;
  final dynamic deviceValue;
  final dynamic systemDefault;

  const ResolvedConfigValue({
    required this.key,
    required this.value,
    required this.source,
    this.isLocked = false,
    this.bandDefault,
    this.userValue,
    this.deviceValue,
    this.systemDefault,
  });

  /// Whether this value is inherited from a higher level (not set at the current view level).
  bool isInherited(ConfigLevel viewLevel) => source != viewLevel;

  /// Whether the user can override this value.
  bool get canOverride => !isLocked;

  ResolvedConfigValue copyWith({
    String? key,
    dynamic value,
    ConfigLevel? source,
    bool? isLocked,
    dynamic bandDefault,
    dynamic userValue,
    dynamic deviceValue,
    dynamic systemDefault,
  }) =>
      ResolvedConfigValue(
        key: key ?? this.key,
        value: value ?? this.value,
        source: source ?? this.source,
        isLocked: isLocked ?? this.isLocked,
        bandDefault: bandDefault ?? this.bandDefault,
        userValue: userValue ?? this.userValue,
        deviceValue: deviceValue ?? this.deviceValue,
        systemDefault: systemDefault ?? this.systemDefault,
      );
}

/// Pending sync entry for offline changes.
class PendingSyncEntry {
  final int? id;
  final String key;
  final dynamic value;
  final int version;
  final DateTime timestamp;
  final bool synced;

  const PendingSyncEntry({
    this.id,
    required this.key,
    required this.value,
    required this.version,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'version': version,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Undo action for the auto-save toast.
class ConfigUndoAction {
  final String key;
  final ConfigLevel level;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime timestamp;

  const ConfigUndoAction({
    required this.key,
    required this.level,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });
}
