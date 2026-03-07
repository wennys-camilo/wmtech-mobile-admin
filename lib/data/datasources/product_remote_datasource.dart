import '../../core/api_client.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/section.dart';

/// Fonte de dados remota: produtos no backend.
class ProductRemoteDatasource {
  ProductRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static List<Category>? _parseCategories(dynamic list) {
    if (list == null || list is! List) return null;
    return list
        .map((e) {
          try {
            return Category.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Category>()
        .toList();
  }

  static List<Section>? _parseSections(dynamic list) {
    if (list == null || list is! List) return null;
    return list
        .map((e) {
          try {
            return Section.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Section>()
        .toList();
  }

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
    final categories = _parseCategories(map['categories']);
    final sections = _parseSections(map['sections']);
    final weightKg = map['weightKg'] ?? map['weight_kg'];
    final widthCm = map['widthCm'] ?? map['width_cm'];
    final heightCm = map['heightCm'] ?? map['height_cm'];
    final lengthCm = map['lengthCm'] ?? map['length_cm'];
    final compareAtPrice = map['compareAtPrice'] ?? map['compare_at_price'];
    final couponCode = map['couponCode'] as String? ?? map['coupon_code'] as String?;
    final couponActiveRaw = map['couponActive'] ?? map['coupon_active'];
    final couponActive = couponActiveRaw is bool ? couponActiveRaw : false;
    return Product(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      price: _toDouble(map['price']),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      sku: map['sku'] as String?,
      active: map['active'] as bool? ?? true,
      images: images,
      categories: categories,
      sections: sections,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      weightKg: weightKg != null ? _toDouble(weightKg) : null,
      widthCm: widthCm != null ? (widthCm is num ? widthCm.toInt() : int.tryParse(widthCm.toString())) : null,
      heightCm: heightCm != null ? (heightCm is num ? heightCm.toInt() : int.tryParse(heightCm.toString())) : null,
      lengthCm: lengthCm != null ? (lengthCm is num ? lengthCm.toInt() : int.tryParse(lengthCm.toString())) : null,
      compareAtPrice: compareAtPrice != null ? _toDouble(compareAtPrice) : null,
      couponCode: (couponCode == null || couponCode.trim().isEmpty) ? null : couponCode.trim(),
      couponActive: couponActive,
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
    List<String>? categoryIds,
    List<String>? sectionIds,
    required double weightKg,
    required int widthCm,
    required int heightCm,
    required int lengthCm,
    double? compareAtPrice,
    String? couponCode,
    bool couponActive = false,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'price': price,
      'stock': stock,
      'active': active,
      'weightKg': weightKg,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'lengthCm': lengthCm,
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (sku != null && sku.isNotEmpty) body['sku'] = sku;
    if (images != null && images.isNotEmpty) body['images'] = images;
    if (categoryIds != null && categoryIds.isNotEmpty) body['categoryIds'] = categoryIds;
    if (sectionIds != null && sectionIds.isNotEmpty) body['sectionIds'] = sectionIds;
    if (compareAtPrice != null && compareAtPrice > 0) body['compareAtPrice'] = compareAtPrice;
    if (couponCode != null && couponCode.trim().isNotEmpty) body['couponCode'] = couponCode.trim();
    body['couponActive'] = couponActive;

    return _api.post<Product>(
      '/products',
      body,
      _productFromJson,
    );
  }

  /// DELETE /products/:id
  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
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
    List<String>? categoryIds,
    List<String>? sectionIds,
    double? weightKg,
    int? widthCm,
    int? heightCm,
    int? lengthCm,
    double? compareAtPrice,
    bool setCompareAtPrice = false,
    String? couponCode,
    bool? couponActive,
    bool setCouponFields = false,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (price != null) body['price'] = price;
    if (stock != null) body['stock'] = stock;
    if (sku != null) body['sku'] = sku;
    if (active != null) body['active'] = active;
    if (images != null) body['images'] = images;
    if (categoryIds != null) body['categoryIds'] = categoryIds;
    if (sectionIds != null) body['sectionIds'] = sectionIds;
    if (weightKg != null) body['weightKg'] = weightKg;
    if (widthCm != null) body['widthCm'] = widthCm;
    if (heightCm != null) body['heightCm'] = heightCm;
    if (lengthCm != null) body['lengthCm'] = lengthCm;
    if (setCompareAtPrice) body['compareAtPrice'] = compareAtPrice;
    if (setCouponFields == true) {
      body['couponCode'] = couponCode?.trim().isEmpty == true ? null : couponCode?.trim();
      body['couponActive'] = couponActive ?? false;
    }

    return _api.patch<Product>(
      '/products/$id',
      body,
      _productFromJson,
    );
  }
}
