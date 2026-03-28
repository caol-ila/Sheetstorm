/// All configuration keys and their system defaults — Issue #35
///
/// Reference: docs/konfigurationskonzept.md § 2–4
/// Reference: docs/feature-specs/konfigurationssystem-spec.md § 3

import 'package:sheetstorm/features/config/domain/config_models.dart';

/// Metadata for a single configuration key.
class ConfigKeyDef {
  final String key;
  final String label;
  final String? description;
  final ConfigLevel level;
  final String category;
  final dynamic systemDefault;
  final ConfigWidgetType widgetType;
  final List<String>? options;
  final double? min;
  final double? max;

  const ConfigKeyDef({
    required this.key,
    required this.label,
    this.description,
    required this.level,
    required this.category,
    required this.systemDefault,
    this.widgetType = ConfigWidgetType.text,
    this.options,
    this.min,
    this.max,
  });
}

/// Widget type used to render a config entry.
enum ConfigWidgetType {
  text,
  toggle,
  dropdown,
  slider,
  number,
  roleSelector,
  colorPicker,
  segmented,
}

/// Categories for grouping settings in the UI.
abstract final class ConfigCategory {
  static const String general = 'Allgemein';
  static const String display = 'Darstellung';
  static const String audio = 'Audio';
  static const String performanceMode = 'Spielmodus';
  static const String notifications = 'Notifications';
  static const String ai = 'AI & Import';
  static const String permissions = 'Mitglieder & Rollen';
  static const String policies = 'Policies';
  static const String touch = 'Touch & Gesten';
  static const String footPedal = 'Fußpedal';
  static const String storage = 'Speicher & Cache';
  static const String profile = 'Profil & Konto';
  static const String instruments = 'Instrumente & Stimmen';
}

/// All known configuration keys with defaults and metadata.
abstract final class ConfigKeys {
  // ─── Kapelle ────────────────────────────────────────────────────────────────

  static const bandName = ConfigKeyDef(
    key: 'band.name',
    label: 'Kapellenname',
    level: ConfigLevel.band,
    category: ConfigCategory.general,
    systemDefault: '',
  );

  static const bandLanguage = ConfigKeyDef(
    key: 'band.language',
    label: 'Sprache des Archivs',
    level: ConfigLevel.band,
    category: ConfigCategory.general,
    systemDefault: 'de',
    widgetType: ConfigWidgetType.dropdown,
    options: ['de', 'en'],
  );

  static const bandAiEnabled = ConfigKeyDef(
    key: 'band.ai.enabled',
    label: 'AI-Features aktiviert',
    level: ConfigLevel.band,
    category: ConfigCategory.ai,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const bandAiProvider = ConfigKeyDef(
    key: 'band.ai.provider',
    label: 'AI-Provider',
    level: ConfigLevel.band,
    category: ConfigCategory.ai,
    systemDefault: null,
    widgetType: ConfigWidgetType.dropdown,
    options: ['azure_vision', 'openai_vision', 'google_vision'],
  );

  static const bandTuningPitch = ConfigKeyDef(
    key: 'band.tuning_pitch',
    label: 'Kammerton A (Hz)',
    description: 'Standard-Kammerton für die Kapelle',
    level: ConfigLevel.band,
    category: ConfigCategory.general,
    systemDefault: 442,
    widgetType: ConfigWidgetType.number,
    min: 430,
    max: 450,
  );

  static const bandMetronomeBpm = ConfigKeyDef(
    key: 'band.metronome.default_bpm',
    label: 'Standard-BPM',
    level: ConfigLevel.band,
    category: ConfigCategory.general,
    systemDefault: 120,
    widgetType: ConfigWidgetType.number,
    min: 20,
    max: 300,
  );

  static const bandSheetMusicUpload = ConfigKeyDef(
    key: 'band.permissions.sheet_music_upload',
    label: 'Noten-Upload erlaubt für',
    level: ConfigLevel.band,
    category: ConfigCategory.permissions,
    systemDefault: const ['admin', 'dirigent', 'notenwart'],
    widgetType: ConfigWidgetType.roleSelector,
  );

  static const bandSetlistCreate = ConfigKeyDef(
    key: 'band.permissions.setlist_create',
    label: 'Setlist erstellen erlaubt für',
    level: ConfigLevel.band,
    category: ConfigCategory.permissions,
    systemDefault: const ['admin', 'dirigent', 'notenwart'],
    widgetType: ConfigWidgetType.roleSelector,
  );

  // ─── Policies ──────────────────────────────────────────────────────────────

  static const policyForceLocale = ConfigKeyDef(
    key: 'policy.force_locale',
    label: 'Sprache erzwingen',
    description: 'Alle Mitglieder verwenden die Kapellen-Sprache',
    level: ConfigLevel.band,
    category: ConfigCategory.policies,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const policyForceDarkMode = ConfigKeyDef(
    key: 'policy.force_dark_mode',
    label: 'Dark Mode erzwingen',
    description: 'Nachtmodus bei Konzerten für alle erzwingen',
    level: ConfigLevel.band,
    category: ConfigCategory.policies,
    systemDefault: null,
    widgetType: ConfigWidgetType.dropdown,
    options: ['null', 'true', 'false'],
  );

  static const policyAllowUserAiKeys = ConfigKeyDef(
    key: 'policy.allow_user_ai_keys',
    label: 'Eigene AI-Keys erlauben',
    description: 'Nutzer dürfen eigene AI-Schlüssel verwenden',
    level: ConfigLevel.band,
    category: ConfigCategory.policies,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const policyForceTuningPitch = ConfigKeyDef(
    key: 'policy.force_tuning_pitch',
    label: 'Kammerton erzwingen',
    description: 'Kammerton kann nicht lokal überschrieben werden',
    level: ConfigLevel.band,
    category: ConfigCategory.policies,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Nutzer ────────────────────────────────────────────────────────────────

  static const userTheme = ConfigKeyDef(
    key: 'user.theme',
    label: 'Theme',
    level: ConfigLevel.user,
    category: ConfigCategory.display,
    systemDefault: 'system',
    widgetType: ConfigWidgetType.segmented,
    options: ['light', 'dark', 'system'],
  );

  static const userLanguage = ConfigKeyDef(
    key: 'user.language',
    label: 'Sprache der App',
    level: ConfigLevel.user,
    category: ConfigCategory.display,
    systemDefault: 'de',
    widgetType: ConfigWidgetType.dropdown,
    options: ['de', 'en'],
  );

  static const userHalfPageTurn = ConfigKeyDef(
    key: 'user.performance_mode.half_page_turn',
    label: 'Half-Page-Turn',
    description: 'Halbes Blatt wenden statt ganzes',
    level: ConfigLevel.user,
    category: ConfigCategory.performanceMode,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const userHalfPageRatio = ConfigKeyDef(
    key: 'user.performance_mode.half_page_ratio',
    label: 'Teilungsverhältnis',
    level: ConfigLevel.user,
    category: ConfigCategory.performanceMode,
    systemDefault: 0.5,
    widgetType: ConfigWidgetType.slider,
    min: 0.3,
    max: 0.7,
  );

  static const userSwipeDirection = ConfigKeyDef(
    key: 'user.performance_mode.swipe_direction',
    label: 'Wisch-Richtung',
    level: ConfigLevel.user,
    category: ConfigCategory.performanceMode,
    systemDefault: 'horizontal',
    widgetType: ConfigWidgetType.segmented,
    options: ['horizontal', 'vertikal'],
  );

  static const userAnnotationColor = ConfigKeyDef(
    key: 'user.annotation.default_color',
    label: 'Standard-Stiftfarbe',
    level: ConfigLevel.user,
    category: ConfigCategory.display,
    systemDefault: '#FF0000',
    widgetType: ConfigWidgetType.colorPicker,
  );

  static const userNotificationsEvents = ConfigKeyDef(
    key: 'user.notifications.events',
    label: 'Probe-Erinnerungen',
    level: ConfigLevel.user,
    category: ConfigCategory.notifications,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const userNotificationsSheetMusic = ConfigKeyDef(
    key: 'user.notifications.new_sheet_music',
    label: 'Neue Noten verfügbar',
    level: ConfigLevel.user,
    category: ConfigCategory.notifications,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const userNotificationsAnnotation = ConfigKeyDef(
    key: 'user.notifications.annotation_update',
    label: 'Orchester-annotations',
    level: ConfigLevel.user,
    category: ConfigCategory.notifications,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Gerät ─────────────────────────────────────────────────────────────────

  static const deviceBrightness = ConfigKeyDef(
    key: 'device.display.brightness',
    label: 'Helligkeit',
    level: ConfigLevel.device,
    category: ConfigCategory.display,
    systemDefault: 1.0,
    widgetType: ConfigWidgetType.slider,
    min: 0.5,
    max: 1.5,
  );

  static const deviceFontSize = ConfigKeyDef(
    key: 'device.display.font_size',
    label: 'Schriftgröße',
    level: ConfigLevel.device,
    category: ConfigCategory.display,
    systemDefault: 'mittel',
    widgetType: ConfigWidgetType.segmented,
    options: ['klein', 'mittel', 'gross', 'sehr_gross'],
  );

  static const deviceAutoRotation = ConfigKeyDef(
    key: 'device.display.auto_rotation',
    label: 'Auto-Rotation',
    level: ConfigLevel.device,
    category: ConfigCategory.display,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const deviceTouchZones = ConfigKeyDef(
    key: 'device.touch.zones',
    label: 'Tap-Zonen-Aufteilung',
    description: 'Links/Rechts-Verteilung für Seitenwechsel',
    level: ConfigLevel.device,
    category: ConfigCategory.touch,
    systemDefault: 0.4,
    widgetType: ConfigWidgetType.slider,
    min: 0.2,
    max: 0.5,
  );

  static const deviceTouchSensitivity = ConfigKeyDef(
    key: 'device.touch.sensitivity',
    label: 'Wisch-Empfindlichkeit',
    level: ConfigLevel.device,
    category: ConfigCategory.touch,
    systemDefault: 'mittel',
    widgetType: ConfigWidgetType.segmented,
    options: ['gering', 'mittel', 'hoch'],
  );

  static const deviceTunerTuningPitch = ConfigKeyDef(
    key: 'device.tuner.tuning_pitch',
    label: 'Tuner-Referenzton (Hz)',
    level: ConfigLevel.device,
    category: ConfigCategory.audio,
    systemDefault: 440,
    widgetType: ConfigWidgetType.number,
    min: 430,
    max: 450,
  );

  static const deviceMetronomeLatency = ConfigKeyDef(
    key: 'device.metronome.latency_compensation',
    label: 'Latenz-Kompensation (ms)',
    level: ConfigLevel.device,
    category: ConfigCategory.audio,
    systemDefault: 0,
    widgetType: ConfigWidgetType.number,
    min: -100,
    max: 100,
  );

  static const deviceFootPedalActive = ConfigKeyDef(
    key: 'device.foot_pedal.active',
    label: 'Fußpedal aktiviert',
    level: ConfigLevel.device,
    category: ConfigCategory.footPedal,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const deviceOfflineMaxStorage = ConfigKeyDef(
    key: 'device.offline.max_storage_mb',
    label: 'Maximaler Offline-Cache (MB)',
    level: ConfigLevel.device,
    category: ConfigCategory.storage,
    systemDefault: 500,
    widgetType: ConfigWidgetType.slider,
    min: 100,
    max: 5000,
  );

  static const deviceOfflineAutoDownload = ConfigKeyDef(
    key: 'device.offline.auto_download',
    label: 'Noten automatisch herunterladen',
    level: ConfigLevel.device,
    category: ConfigCategory.storage,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const deviceOfflineWifiOnly = ConfigKeyDef(
    key: 'device.offline.wifi_only',
    label: 'Downloads nur über WLAN',
    level: ConfigLevel.device,
    category: ConfigCategory.storage,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Lookup ────────────────────────────────────────────────────────────────

  static final Map<String, ConfigKeyDef> _all = {
    for (final def in allKeys) def.key: def,
  };

  static ConfigKeyDef? lookup(String key) => _all[key];

  static dynamic getDefault(String key) => _all[key]?.systemDefault;

  static List<ConfigKeyDef> get allKeys => [
        // Kapelle
        bandName, bandLanguage, bandAiEnabled, bandAiProvider,
        bandTuningPitch, bandMetronomeBpm, bandSheetMusicUpload,
        bandSetlistCreate,
        // Policies
        policyForceLocale, policyForceDarkMode, policyAllowUserAiKeys,
        policyForceTuningPitch,
        // Nutzer
        userTheme, userLanguage, userHalfPageTurn, userHalfPageRatio,
        userSwipeDirection, userAnnotationColor,
        userNotificationsEvents, userNotificationsSheetMusic,
        userNotificationsAnnotation,
        // Gerät
        deviceBrightness, deviceFontSize, deviceAutoRotation,
        deviceTouchZones, deviceTouchSensitivity, deviceTunerTuningPitch,
        deviceMetronomeLatency, deviceFootPedalActive, deviceOfflineMaxStorage,
        deviceOfflineAutoDownload, deviceOfflineWifiOnly,
      ];

  static List<ConfigKeyDef> forLevel(ConfigLevel level) =>
      allKeys.where((k) => k.level == level).toList();

  /// Group keys by category for a given level.
  static Map<String, List<ConfigKeyDef>> groupedByCategory(ConfigLevel level) {
    final keys = forLevel(level);
    final grouped = <String, List<ConfigKeyDef>>{};
    for (final key in keys) {
      grouped.putIfAbsent(key.category, () => []).add(key);
    }
    return grouped;
  }
}
