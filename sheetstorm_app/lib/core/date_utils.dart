/// ISO 8601-konforme Hilfsfunktionen für Datums-Berechnungen.
library;

/// Berechnet die ISO-8601-Wochennummer für ein gegebenes Datum.
///
/// Korrekte Behandlung von Randwerten:
/// - Woche 53 (z.B. 31.12.2015 → KW 53)
/// - Jahresübergänge (z.B. 30.12.2024 → KW 1 des Jahres 2025)
int isoWeekNumber(DateTime date) {
  // Donnerstag der gleichen ISO-Woche
  final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
  // KW 1 enthält immer den 4. Januar
  final jan4 = DateTime(thursday.year, 1, 4);
  final jan4Thursday =
      jan4.add(Duration(days: DateTime.thursday - jan4.weekday));
  return ((thursday.difference(jan4Thursday).inDays) / 7).floor() + 1;
}
