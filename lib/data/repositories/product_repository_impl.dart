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
    );
  }
}
