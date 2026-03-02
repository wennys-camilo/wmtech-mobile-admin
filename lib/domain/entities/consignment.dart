/// Consignação: produto deixado em uma loja.
/// countAtStore = contagem atual na loja (conferência); quantitySold e totalSalesValue vêm da API quando countAtStore está preenchido.
class Consignment {
  const Consignment({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.quantity,
    required this.placedAt,
    this.notes,
    this.storeName,
    this.productName,
    this.countAtStore,
    this.quantitySold,
    this.unitPriceAtPlacement,
    this.totalSalesValue,
  });

  final String id;
  final String storeId;
  final String productId;
  final int quantity;
  final String placedAt;
  final String? notes;
  final String? storeName;
  final String? productName;
  /// Contagem atual na loja (conferência). Null = não conferido.
  final int? countAtStore;
  /// Quantidade vendida (quantity - countAtStore quando countAtStore preenchido).
  final int? quantitySold;
  /// Preço unitário no dia da colocação.
  final double? unitPriceAtPlacement;
  /// Valor total vendidos (unitPriceAtPlacement * quantitySold).
  final double? totalSalesValue;

  static Consignment fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid consignment json');
    final map = Map<String, dynamic>.from(json);
    final store = map['store'];
    final product = map['product'];
    final placedAt = map['placedAt'] ?? map['placed_at'];
    final countAtStoreRaw = map['countAtStore'] ?? map['count_at_store'];
    final quantitySoldRaw = map['quantitySold'];
    final unitPriceRaw = map['unitPriceAtPlacement'] ?? map['unit_price_at_placement'];
    final totalSalesRaw = map['totalSalesValue'];
    return Consignment(
      id: map['id'] as String? ?? '',
      storeId: map['storeId'] as String? ?? map['store_id'] as String? ?? '',
      productId: map['productId'] as String? ?? map['product_id'] as String? ?? '',
      quantity: _toInt(map['quantity']) ?? 0,
      placedAt: placedAt is String ? placedAt : (placedAt?.toString() ?? ''),
      notes: map['notes'] as String?,
      storeName: store is Map ? store['name'] as String? : null,
      productName: product is Map ? product['name'] as String? : null,
      countAtStore: _toInt(countAtStoreRaw),
      quantitySold: _toInt(quantitySoldRaw),
      unitPriceAtPlacement: _toDouble(unitPriceRaw),
      totalSalesValue: _toDouble(totalSalesRaw),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'storeId': storeId,
        'productId': productId,
        'quantity': quantity,
        'placedAt': placedAt,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
