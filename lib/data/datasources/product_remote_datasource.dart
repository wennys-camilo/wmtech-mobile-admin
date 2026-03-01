import '../../core/api_client.dart';
import '../../domain/entities/product.dart';

/// Fonte de dados remota: produtos no backend.
class ProductRemoteDatasource {
  ProductRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static Product _productFromJson(dynamic json) {
    if (json == null || json is! Map) {
      throw FormatException('Invalid product json');
    }
    final map = Map<String, dynamic>.from(json);
    List<String>? images;
    if (map['images'] != null && map['images'] is List) {
      images = (map['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      price: _toDouble(map['price']),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sku: map['sku'] as String?,
      active: map['active'] as bool? ?? true,
      images: images,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  /// GET /products ou /products?all=true
  Future<List<Product>> getProducts({bool includeInactive = false}) async {
    final path =
        includeInactive ? '/products?all=true' : '/products';
    final list = await _api.get<List<dynamic>>(
      path,
      (v) => v is List ? v : [],
    );
    return list.map((e) => _productFromJson(e)).toList();
  }

  /// POST /products
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
    String? sku,
    bool active = true,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'price': price,
      'stock': stock,
      'active': active,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (sku != null && sku.isNotEmpty) body['sku'] = sku;
    if (images != null && images.isNotEmpty) body['images'] = images;

    return _api.post<Product>(
      '/products',
      body,
      _productFromJson,
    );
  }

  /// PATCH /products/:id
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? description,
    double? price,
    int? stock,
    String? sku,
    bool? active,
    List<String>? images,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    if (sku != null) body['sku'] = sku;
    if (active != null) body['active'] = active;
    if (images != null) body['images'] = images;

    return _api.patch<Product>(
      '/products/$id',
      body,
      _productFromJson,
    );
  }
}
