/// All configuration keys and their system defaults — Issue #35
///
/// Reference: docs/konfigurationskonzept.md § 2–4
/// Reference: docs/feature-specs/konfigurationssystem-spec.md § 3

import 'package:sheetstorm/features/config/domain/config_models.dart';

/// Metadata for a single configuration key.
class ConfigKeyDef {
  final String schluessel;
  final String label;
  final String? beschreibung;
  final ConfigEbene ebene;
  final String kategorie;
  final dynamic systemDefault;
  final ConfigWidgetType widgetType;
  final List<String>? optionen;
  final double? min;
  final double? max;

  const ConfigKeyDef({
    required this.schluessel,
    required this.label,
    this.beschreibung,
    required this.ebene,
    required this.kategorie,
    required this.systemDefault,
    this.widgetType = ConfigWidgetType.text,
    this.optionen,
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
abstract final class ConfigKategorie {
  static const String allgemein = 'Allgemein';
  static const String darstellung = 'Darstellung';
  static const String audio = 'Audio';
  static const String spielmodus = 'Spielmodus';
  static const String benachrichtigungen = 'Benachrichtigungen';
  static const String ai = 'AI & Import';
  static const String berechtigungen = 'Mitglieder & Rollen';
  static const String policies = 'Policies';
  static const String touch = 'Touch & Gesten';
  static const String fusspedal = 'Fußpedal';
  static const String speicher = 'Speicher & Cache';
  static const String profil = 'Profil & Konto';
  static const String instrumente = 'Instrumente & Stimmen';
}

/// All known configuration keys with defaults and metadata.
abstract final class ConfigKeys {
  // ─── Kapelle ────────────────────────────────────────────────────────────────

  static const kapelleName = ConfigKeyDef(
    schluessel: 'kapelle.name',
    label: 'Kapellenname',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.allgemein,
    systemDefault: '',
  );

  static const kapelleSprache = ConfigKeyDef(
    schluessel: 'kapelle.sprache',
    label: 'Sprache des Archivs',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.allgemein,
    systemDefault: 'de',
    widgetType: ConfigWidgetType.dropdown,
    optionen: ['de', 'en'],
  );

  static const kapelleAiEnabled = ConfigKeyDef(
    schluessel: 'kapelle.ai.enabled',
    label: 'AI-Features aktiviert',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.ai,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const kapelleAiProvider = ConfigKeyDef(
    schluessel: 'kapelle.ai.provider',
    label: 'AI-Provider',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.ai,
    systemDefault: null,
    widgetType: ConfigWidgetType.dropdown,
    optionen: ['azure_vision', 'openai_vision', 'google_vision'],
  );

  static const kapelleKammerton = ConfigKeyDef(
    schluessel: 'kapelle.kammerton',
    label: 'Kammerton A (Hz)',
    beschreibung: 'Standard-Kammerton für die Kapelle',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.allgemein,
    systemDefault: 442,
    widgetType: ConfigWidgetType.number,
    min: 430,
    max: 450,
  );

  static const kapelleMetronomBpm = ConfigKeyDef(
    schluessel: 'kapelle.metronom.default_bpm',
    label: 'Standard-BPM',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.allgemein,
    systemDefault: 120,
    widgetType: ConfigWidgetType.number,
    min: 20,
    max: 300,
  );

  static const kapelleNotenUpload = ConfigKeyDef(
    schluessel: 'kapelle.berechtigungen.noten_upload',
    label: 'Noten-Upload erlaubt für',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.berechtigungen,
    systemDefault: const ['admin', 'dirigent', 'notenwart'],
    widgetType: ConfigWidgetType.roleSelector,
  );

  static const kapelleSetlistErstellen = ConfigKeyDef(
    schluessel: 'kapelle.berechtigungen.setlist_erstellen',
    label: 'Setlist erstellen erlaubt für',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.berechtigungen,
    systemDefault: const ['admin', 'dirigent', 'notenwart'],
    widgetType: ConfigWidgetType.roleSelector,
  );

  // ─── Policies ──────────────────────────────────────────────────────────────

  static const policyForceLocale = ConfigKeyDef(
    schluessel: 'policy.force_locale',
    label: 'Sprache erzwingen',
    beschreibung: 'Alle Mitglieder verwenden die Kapellen-Sprache',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.policies,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const policyForceDarkMode = ConfigKeyDef(
    schluessel: 'policy.force_dark_mode',
    label: 'Dark Mode erzwingen',
    beschreibung: 'Nachtmodus bei Konzerten für alle erzwingen',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.policies,
    systemDefault: null,
    widgetType: ConfigWidgetType.dropdown,
    optionen: ['null', 'true', 'false'],
  );

  static const policyAllowUserAiKeys = ConfigKeyDef(
    schluessel: 'policy.allow_user_ai_keys',
    label: 'Eigene AI-Keys erlauben',
    beschreibung: 'Nutzer dürfen eigene AI-Schlüssel verwenden',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.policies,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const policyForceKammerton = ConfigKeyDef(
    schluessel: 'policy.force_kammerton',
    label: 'Kammerton erzwingen',
    beschreibung: 'Kammerton kann nicht lokal überschrieben werden',
    ebene: ConfigEbene.kapelle,
    kategorie: ConfigKategorie.policies,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Nutzer ────────────────────────────────────────────────────────────────

  static const nutzerTheme = ConfigKeyDef(
    schluessel: 'nutzer.theme',
    label: 'Theme',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: 'system',
    widgetType: ConfigWidgetType.segmented,
    optionen: ['light', 'dark', 'system'],
  );

  static const nutzerSprache = ConfigKeyDef(
    schluessel: 'nutzer.sprache',
    label: 'Sprache der App',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: 'de',
    widgetType: ConfigWidgetType.dropdown,
    optionen: ['de', 'en'],
  );

  static const nutzerHalfPageTurn = ConfigKeyDef(
    schluessel: 'nutzer.spielmodus.half_page_turn',
    label: 'Half-Page-Turn',
    beschreibung: 'Halbes Blatt wenden statt ganzes',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.spielmodus,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const nutzerHalfPageRatio = ConfigKeyDef(
    schluessel: 'nutzer.spielmodus.half_page_ratio',
    label: 'Teilungsverhältnis',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.spielmodus,
    systemDefault: 0.5,
    widgetType: ConfigWidgetType.slider,
    min: 0.3,
    max: 0.7,
  );

  static const nutzerSwipeRichtung = ConfigKeyDef(
    schluessel: 'nutzer.spielmodus.swipe_richtung',
    label: 'Wisch-Richtung',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.spielmodus,
    systemDefault: 'horizontal',
    widgetType: ConfigWidgetType.segmented,
    optionen: ['horizontal', 'vertikal'],
  );

  static const nutzerAnnotationFarbe = ConfigKeyDef(
    schluessel: 'nutzer.annotation.default_farbe',
    label: 'Standard-Stiftfarbe',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: '#FF0000',
    widgetType: ConfigWidgetType.colorPicker,
  );

  static const nutzerBenachrichtigungenTermine = ConfigKeyDef(
    schluessel: 'nutzer.benachrichtigungen.termine',
    label: 'Probe-Erinnerungen',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.benachrichtigungen,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const nutzerBenachrichtigungenNoten = ConfigKeyDef(
    schluessel: 'nutzer.benachrichtigungen.noten_neu',
    label: 'Neue Noten verfügbar',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.benachrichtigungen,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const nutzerBenachrichtigungenAnnotation = ConfigKeyDef(
    schluessel: 'nutzer.benachrichtigungen.annotation_update',
    label: 'Orchester-Annotationen',
    ebene: ConfigEbene.nutzer,
    kategorie: ConfigKategorie.benachrichtigungen,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Gerät ─────────────────────────────────────────────────────────────────

  static const geraetHelligkeit = ConfigKeyDef(
    schluessel: 'geraet.display.helligkeit',
    label: 'Helligkeit',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: 1.0,
    widgetType: ConfigWidgetType.slider,
    min: 0.5,
    max: 1.5,
  );

  static const geraetSchriftgroesse = ConfigKeyDef(
    schluessel: 'geraet.display.schriftgroesse',
    label: 'Schriftgröße',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: 'mittel',
    widgetType: ConfigWidgetType.segmented,
    optionen: ['klein', 'mittel', 'gross', 'sehr_gross'],
  );

  static const geraetAutoRotation = ConfigKeyDef(
    schluessel: 'geraet.display.auto_rotation',
    label: 'Auto-Rotation',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.darstellung,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const geraetTouchZonen = ConfigKeyDef(
    schluessel: 'geraet.touch.zonen',
    label: 'Tap-Zonen-Aufteilung',
    beschreibung: 'Links/Rechts-Verteilung für Seitenwechsel',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.touch,
    systemDefault: 0.4,
    widgetType: ConfigWidgetType.slider,
    min: 0.2,
    max: 0.5,
  );

  static const geraetTouchEmpfindlichkeit = ConfigKeyDef(
    schluessel: 'geraet.touch.empfindlichkeit',
    label: 'Wisch-Empfindlichkeit',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.touch,
    systemDefault: 'mittel',
    widgetType: ConfigWidgetType.segmented,
    optionen: ['gering', 'mittel', 'hoch'],
  );

  static const geraetTunerKammerton = ConfigKeyDef(
    schluessel: 'geraet.tuner.kammerton',
    label: 'Tuner-Referenzton (Hz)',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.audio,
    systemDefault: 440,
    widgetType: ConfigWidgetType.number,
    min: 430,
    max: 450,
  );

  static const geraetMetronomLatenz = ConfigKeyDef(
    schluessel: 'geraet.metronom.latenz_kompensation',
    label: 'Latenz-Kompensation (ms)',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.audio,
    systemDefault: 0,
    widgetType: ConfigWidgetType.number,
    min: -100,
    max: 100,
  );

  static const geraetFusspedalAktiv = ConfigKeyDef(
    schluessel: 'geraet.fusspedal.aktiv',
    label: 'Fußpedal aktiviert',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.fusspedal,
    systemDefault: false,
    widgetType: ConfigWidgetType.toggle,
  );

  static const geraetOfflineMaxSpeicher = ConfigKeyDef(
    schluessel: 'geraet.offline.max_speicher_mb',
    label: 'Maximaler Offline-Cache (MB)',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.speicher,
    systemDefault: 500,
    widgetType: ConfigWidgetType.slider,
    min: 100,
    max: 5000,
  );

  static const geraetOfflineAutoDownload = ConfigKeyDef(
    schluessel: 'geraet.offline.auto_download',
    label: 'Noten automatisch herunterladen',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.speicher,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  static const geraetOfflineNurWifi = ConfigKeyDef(
    schluessel: 'geraet.offline.nur_wifi',
    label: 'Downloads nur über WLAN',
    ebene: ConfigEbene.geraet,
    kategorie: ConfigKategorie.speicher,
    systemDefault: true,
    widgetType: ConfigWidgetType.toggle,
  );

  // ─── Lookup ────────────────────────────────────────────────────────────────

  static final Map<String, ConfigKeyDef> _all = {
    for (final def in allKeys) def.schluessel: def,
  };

  static ConfigKeyDef? lookup(String key) => _all[key];

  static dynamic getDefault(String key) => _all[key]?.systemDefault;

  static List<ConfigKeyDef> get allKeys => [
        // Kapelle
        kapelleName, kapelleSprache, kapelleAiEnabled, kapelleAiProvider,
        kapelleKammerton, kapelleMetronomBpm, kapelleNotenUpload,
        kapelleSetlistErstellen,
        // Policies
        policyForceLocale, policyForceDarkMode, policyAllowUserAiKeys,
        policyForceKammerton,
        // Nutzer
        nutzerTheme, nutzerSprache, nutzerHalfPageTurn, nutzerHalfPageRatio,
        nutzerSwipeRichtung, nutzerAnnotationFarbe,
        nutzerBenachrichtigungenTermine, nutzerBenachrichtigungenNoten,
        nutzerBenachrichtigungenAnnotation,
        // Gerät
        geraetHelligkeit, geraetSchriftgroesse, geraetAutoRotation,
        geraetTouchZonen, geraetTouchEmpfindlichkeit, geraetTunerKammerton,
        geraetMetronomLatenz, geraetFusspedalAktiv, geraetOfflineMaxSpeicher,
        geraetOfflineAutoDownload, geraetOfflineNurWifi,
      ];

  static List<ConfigKeyDef> forEbene(ConfigEbene ebene) =>
      allKeys.where((k) => k.ebene == ebene).toList();

  /// Group keys by category for a given level.
  static Map<String, List<ConfigKeyDef>> groupedByKategorie(ConfigEbene ebene) {
    final keys = forEbene(ebene);
    final grouped = <String, List<ConfigKeyDef>>{};
    for (final key in keys) {
      grouped.putIfAbsent(key.kategorie, () => []).add(key);
    }
    return grouped;
  }
}
