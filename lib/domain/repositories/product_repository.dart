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
    int minQuantity = 1,
    int maxQuantity = 100,
    bool isPersonalized = false,
    int? productionDays,
  });

  /// Exclui um produto pelo ID. Requer autenticação.
  Future<void> deleteProduct(String id);

  /// Atualiza um produto. Requer autenticação.
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
    int? minQuantity,
    int? maxQuantity,
    bool? isPersonalized,
    int? productionDays,
    bool setPersonalizedFields = false,
  });
}
