import 'store.dart';

/// Consignação: produto deixado em uma loja.
class Consignment {
  const Consignment({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.quantity,
    required this.quantityReturned,
    required this.placedAt,
    this.notes,
    this.storeName,
    this.productName,
  });

  final String id;
  final String storeId;
  final String productId;
  final int quantity;
  final int quantityReturned;
  final String placedAt;
  final String? notes;
  final String? storeName;
  final String? productName;

  int get quantityRemaining => quantity - quantityReturned;

  static Consignment fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid consignment json');
    final map = Map<String, dynamic>.from(json);
    final store = map['store'];
    final product = map['product'];
    final placedAt = map['placedAt'] ?? map['placed_at'];
    return Consignment(
      id: map['id'] as String? ?? '',
      storeId: map['storeId'] as String? ?? map['store_id'] as String? ?? '',
      productId: map['productId'] as String? ?? map['product_id'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      quantityReturned: (map['quantityReturned'] as num?)?.toInt() ?? (map['quantity_returned'] as num?)?.toInt() ?? 0,
      placedAt: placedAt is String ? placedAt : (placedAt?.toString() ?? ''),
      notes: map['notes'] as String?,
      storeName: store is Map ? store['name'] as String? : null,
      productName: product is Map ? product['name'] as String? : null,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'storeId': storeId,
        'productId': productId,
        'quantity': quantity,
        'placedAt': placedAt,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
