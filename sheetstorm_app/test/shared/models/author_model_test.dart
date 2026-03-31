import 'package:flutter_test/flutter_test.dart';
import 'package:sheetstorm/shared/models/author_model.dart';

/// Verifiziert die gemeinsame Author-Klasse (CR#2 — DRY-Fix).
///
/// Vorher: identische Author-Klasse sowohl in poll_models.dart als auch
/// in post_models.dart — Import-Konflikte und Wartungsaufwand.
/// Nachher: eine kanonische Klasse in shared/models/author_model.dart.
void main() {
  group('Author (shared model)', () {
    test('fromJson erstellt korrektes Objekt', () {
      final json = {
        'id': 'user-1',
        'name': 'Max Mustermann',
        'avatarUrl': 'https://example.com/avatar.png',
        'role': 'Dirigent',
      };

      final author = Author.fromJson(json);

      expect(author.id, 'user-1');
      expect(author.name, 'Max Mustermann');
      expect(author.avatarUrl, 'https://example.com/avatar.png');
      expect(author.role, 'Dirigent');
    });

    test('fromJson behandelt optionale Felder als null', () {
      final json = {
        'id': 'user-2',
        'name': 'Erika Mustermann',
      };

      final author = Author.fromJson(json);

      expect(author.id, 'user-2');
      expect(author.name, 'Erika Mustermann');
      expect(author.avatarUrl, isNull);
      expect(author.role, isNull);
    });

    test('toJson gibt vollständiges Map zurück', () {
      const author = Author(
        id: 'user-3',
        name: 'Hans',
        avatarUrl: 'https://example.com/hans.jpg',
        role: 'Musiker',
      );

      final json = author.toJson();

      expect(json['id'], 'user-3');
      expect(json['name'], 'Hans');
      expect(json['avatarUrl'], 'https://example.com/hans.jpg');
      expect(json['role'], 'Musiker');
    });

    test('toJson enthält null-Felder', () {
      const author = Author(id: 'user-4', name: 'Grete');

      final json = author.toJson();

      expect(json.containsKey('avatarUrl'), isTrue);
      expect(json['avatarUrl'], isNull);
      expect(json.containsKey('role'), isTrue);
      expect(json['role'], isNull);
    });
  });
}
