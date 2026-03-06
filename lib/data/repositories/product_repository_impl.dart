import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

/// Implementação do repositório de produtos (usa datasource remoto).
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl([ProductRemoteDatasource? datasource])
      : _datasource = datasource ?? ProductRemoteDatasource();

  final ProductRemoteDatasource _datasource;

  @override
  Future<List<Product>> getProducts({bool includeInactive = false}) {
    return _datasource.getProducts(includeInactive: includeInactive);
  }

  @override
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
  }) {
    return _datasource.createProduct(
      name: name,
      description: description,
      price: price,
      stock: stock,
      sku: sku,
      active: active,
      images: images,
      categoryIds: categoryIds,
      sectionIds: sectionIds,
      weightKg: weightKg,
      widthCm: widthCm,
      heightCm: heightCm,
      lengthCm: lengthCm,
      compareAtPrice: compareAtPrice,
      couponCode: couponCode,
      couponActive: couponActive,
    );
  }

  @override
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
  }) {
    return _datasource.updateProduct(
      id,
      name: name,
      description: description,
      price: price,
      stock: stock,
      sku: sku,
      active: active,
      images: images,
      categoryIds: categoryIds,
      sectionIds: sectionIds,
      weightKg: weightKg,
      widthCm: widthCm,
      heightCm: heightCm,
      lengthCm: lengthCm,
      compareAtPrice: compareAtPrice,
      setCompareAtPrice: setCompareAtPrice,
      couponCode: couponCode,
      couponActive: couponActive,
      setCouponFields: setCouponFields,
    );
  }
}
