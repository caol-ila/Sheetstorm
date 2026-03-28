/// Vordefinierte Stempel-Bibliothek (UX-Spec §3.5)
///
/// Stempel-Kategorien für häufig verwendete annotations in Blaskapellen.

class StampCategory {
  const StampCategory({
    required this.id,
    required this.label,
    required this.stamps,
  });

  final String id;
  final String label;
  final List<StampDefinition> stamps;
}

class StampDefinition {
  const StampDefinition({
    required this.value,
    this.displayText,
    this.unicode,
  });

  /// Interner Wert (z.B. 'pp', 'mf', 'staccato')
  final String value;

  /// Angezeigter Text (falls anders als value)
  final String? displayText;

  /// Unicode-Zeichen (falls vorhanden, z.B. 𝆏 für piano)
  final String? unicode;

  String get display => displayText ?? value;
}

/// Alle verfügbaren Stempel
abstract final class StampCatalog {
  static const List<StampCategory> categories = [
    dynamik,
    artikulation,
    atem,
    navigation,
  ];

  static const dynamik = StampCategory(
    id: 'dynamik',
    label: 'Dynamik',
    stamps: [
      StampDefinition(value: 'pp', displayText: '𝆏𝆏'),
      StampDefinition(value: 'p', displayText: '𝆏'),
      StampDefinition(value: 'mp', displayText: '𝆐𝆏'),
      StampDefinition(value: 'mf', displayText: '𝆐𝆑'),
      StampDefinition(value: 'f', displayText: '𝆑'),
      StampDefinition(value: 'ff', displayText: '𝆑𝆑'),
      StampDefinition(value: 'fff', displayText: '𝆑𝆑𝆑'),
      StampDefinition(value: 'sfz'),
      StampDefinition(value: 'sfp'),
      StampDefinition(value: 'fp'),
      StampDefinition(value: 'cresc.'),
      StampDefinition(value: 'dim.'),
    ],
  );

  static const artikulation = StampCategory(
    id: 'artikulation',
    label: 'Artikulation',
    stamps: [
      StampDefinition(value: 'staccato', displayText: '•'),
      StampDefinition(value: 'akzent', displayText: '>'),
      StampDefinition(value: 'marcato', displayText: '^'),
      StampDefinition(value: 'tremolo', displayText: '~'),
      StampDefinition(value: 'triller', displayText: 'tr'),
      StampDefinition(value: 'gliss', displayText: 'gliss.'),
    ],
  );

  static const atem = StampCategory(
    id: 'atem',
    label: 'Atemzeichen',
    stamps: [
      StampDefinition(value: 'einatmen', displayText: "'"),
      StampDefinition(value: 'luftdruck', displayText: 'V'),
      StampDefinition(value: 'komma_atem', displayText: ','),
    ],
  );

  static const navigation = StampCategory(
    id: 'navigation',
    label: 'Navigation',
    stamps: [
      StampDefinition(value: 'dc', displayText: 'D.C.'),
      StampDefinition(value: 'ds', displayText: 'D.S.'),
      StampDefinition(value: 'coda', displayText: '𝄌'),
      StampDefinition(value: 'fine', displayText: 'Fine'),
      StampDefinition(value: 'segno', displayText: '𝄋'),
      StampDefinition(value: 'volta1', displayText: '[1.]'),
      StampDefinition(value: 'volta2', displayText: '[2.]'),
    ],
  );

  /// Stempel nach Kategorie+Wert finden
  static StampDefinition? find(String category, String value) {
    for (final cat in categories) {
      if (cat.id == category) {
        for (final stamp in cat.stamps) {
          if (stamp.value == value) return stamp;
        }
      }
    }
    return null;
  }
}
