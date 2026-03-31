/// Gemeinsames Author-Datenmodell für Communication-Feature (Posts & Polls).
///
/// Vorher wurde die identische Klasse sowohl in post_models.dart als auch
/// in poll_models.dart definiert — DRY-Verletzung und potentielle
/// Import-Konflikte. Diese Klasse ersetzt beide Duplikate (CR#2).
class Author {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  const Author({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'role': role,
      };
}
