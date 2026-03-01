/// Loja/parceiro onde produtos são consignados.
class Store {
  const Store({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
  });

  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;

  static Store fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid store json');
    final map = Map<String, dynamic>.from(json);
    return Store(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactName: map['contactName'] as String? ?? map['contact_name'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (contactName != null) 'contactName': contactName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      };
}
