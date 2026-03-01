/// Entidade de domínio: seção (ex.: Ofertas do dia, Novidades).
class Section {
  const Section({required this.id, required this.name});

  final String id;
  final String name;

  static Section fromJson(dynamic json) {
    if (json == null || json is! Map) {
      throw FormatException('Invalid section json');
    }
    final map = Map<String, dynamic>.from(json);
    return Section(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
    );
  }
}
