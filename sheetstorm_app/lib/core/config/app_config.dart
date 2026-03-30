import 'package:flutter/foundation.dart';

/// App-weite Konfigurationsschalter.
///
/// Produktionswerte werden durch Build-Flags überschrieben.
/// Dev-Flags sind nur in Debug-Builds aktiv.
abstract final class AppConfig {
  /// Dev-Modus: E-Mail-Bestätigung automatisch überspringen.
  /// Ermöglicht schnelle Test-Registrierungen ohne E-Mail-Zugang.
  /// In Release-Builds immer `false`.
  static const bool devAutoVerifyEmail = kDebugMode;

  /// Backend API base URL.
  /// Debug → lokaler Dev-Server; Release → Produktion.
  static const String apiBaseUrl = kDebugMode
      ? 'http://localhost:5273'
      : 'https://api.sheetstorm.app/v1';
}
