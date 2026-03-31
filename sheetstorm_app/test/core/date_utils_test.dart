import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/core/date_utils.dart';

void main() {
  group('isoWeekNumber', () {
    test('30.12.2024 → KW 1 des Jahres 2025', () {
      expect(isoWeekNumber(DateTime(2024, 12, 30)), 1);
    });

    test('29.12.2024 → KW 52 des Jahres 2024', () {
      expect(isoWeekNumber(DateTime(2024, 12, 29)), 52);
    });

    test('31.12.2015 → KW 53 des Jahres 2015', () {
      expect(isoWeekNumber(DateTime(2015, 12, 31)), 53);
    });

    test('01.01.2025 → KW 1', () {
      expect(isoWeekNumber(DateTime(2025, 1, 1)), 1);
    });

    test('04.01.2025 → KW 1 (4. Januar ist immer in KW 1)', () {
      expect(isoWeekNumber(DateTime(2025, 1, 4)), 1);
    });

    test('06.01.2025 → KW 2', () {
      expect(isoWeekNumber(DateTime(2025, 1, 6)), 2);
    });

    test('01.01.2016 → KW 53 des Jahres 2015', () {
      expect(isoWeekNumber(DateTime(2016, 1, 1)), 53);
    });

    test('28.12.2020 → KW 53 des Jahres 2020', () {
      expect(isoWeekNumber(DateTime(2020, 12, 28)), 53);
    });
  });
}
