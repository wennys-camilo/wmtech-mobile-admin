/// Entidade de domínio: categoria (espelho do backend).
class Category {
  const Category({required this.id, required this.name});

  final String id;
  final String name;

  static Category fromJson(dynamic json) {
    if (json == null || json is! Map) {
      throw FormatException('Invalid category json');
    }
    final map = Map<String, dynamic>.from(json);
    return Category(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}
