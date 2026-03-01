import '../../core/api_client.dart';
import '../../domain/entities/category.dart';

/// Fonte de dados remota: categorias no backend.
class CategoryRemoteDatasource {
  CategoryRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /categories
  Future<List<Category>> getCategories() async {
    final list = await _api.get<List<dynamic>>(
      '/categories',
      (v) => v is List ? v : [],
    );
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

  /// POST /categories — cria categoria.
  Future<Category> createCategory(String name) async {
    return _api.post<Category>(
      '/categories',
      {'name': name.trim()},
      (v) => Category.fromJson(v),
    );
  }
}
