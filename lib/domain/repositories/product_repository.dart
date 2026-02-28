import '../entities/product.dart';

/// Contrato do repositório de produtos (camada de domínio).
/// A UI depende apenas deste contrato; a implementação fica em data.
abstract class ProductRepository {
  /// Lista todos os produtos (all=true inclui inativos).
  Future<List<Product>> getProducts({bool includeInactive = false});

  /// Cria um novo produto. Requer autenticação.
  Future<Product> createProduct({
    required String name,
    String? description,
    required double price,
    required int stock,
    String? sku,
    bool active = true,
  });

  /// Atualiza um produto. Requer autenticação.
  Future<Product> updateProduct(
    String id, {
    String? name,
    String? description,
    double? price,
    int? stock,
    String? sku,
    bool? active,
  });
}
