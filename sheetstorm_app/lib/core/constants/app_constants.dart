/// App-weite Konstanten
abstract final class AppConstants {
  // App-Metadaten
  static const String appName = 'Sheetstorm';
  static const String appVersion = '0.1.0';
  static const String packageName = 'com.sheetstorm';

  // Deep-Link-Schema (decisions.md: sheetstorm://bibliothek/[id])
  static const String deepLinkScheme = 'sheetstorm';

  // Konfigurationsebenen (decisions.md: Kapelle → Nutzer → Gerät)
  static const String configLevelKapelle = 'kapelle';
  static const String configLevelNutzer = 'nutzer';
  static const String configLevelGerat = 'gerat';

  // Pagination
  static const int defaultPageSize = 20;

  // Offline-Cache
  static const int maxOfflineDays = 30;

  // Spielmodus
  static const int halfPageTurnThresholdPx = 40;
  static const int pageJumpAnimationMs = 250;

  // Onboarding (max 5 Fragen — decisions.md)
  static const int onboardingMaxSteps = 5;

  // Undo-Toast-Dauer (decisions.md: 5 Sekunden)
  static const int undoToastDurationSeconds = 5;

  // Kontextmenü max. 5 Optionen (decisions.md)
  static const int contextMenuMaxItems = 5;
}
