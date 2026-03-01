import '../../core/api_client.dart';
import '../../domain/entities/section.dart';

/// Fonte de dados remota: seções no backend.
class SectionRemoteDatasource {
  SectionRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /sections
  Future<List<Section>> getSections() async {
    final list = await _api.get<List<dynamic>>(
      '/sections',
      (v) => v is List ? v : [],
    );
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

  /// POST /sections — cria seção.
  Future<Section> createSection(String name) async {
    return _api.post<Section>(
      '/sections',
      {'name': name.trim()},
      (v) => Section.fromJson(v),
    );
  }
}
