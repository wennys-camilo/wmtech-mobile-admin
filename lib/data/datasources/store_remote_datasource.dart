import '../../core/api_client.dart';
import '../../domain/entities/store.dart';

class StoreRemoteDatasource {
  StoreRemoteDatasource([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /stores — lista lojas (admin).
  Future<List<Store>> getStores() async {
    final list = await _api.get<List<dynamic>>('/stores', (v) => v is List ? v : []);
    return list
        .map((e) {
          try {
            return Store.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Store>()
        .toList();
  }

  /// GET /stores/:id
  Future<Store> getStoreById(String id) async {
    return _api.get<Store>('/stores/$id', (v) => Store.fromJson(v));
  }

  /// POST /stores
  Future<Store> createStore(Store store) async {
    return _api.post<Store>('/stores', store.toJson(), (v) => Store.fromJson(v));
  }

  /// PATCH /stores/:id
  Future<Store> updateStore(String id, Store store) async {
    return _api.patch<Store>('/stores/$id', store.toJson(), (v) => Store.fromJson(v));
  }

  /// DELETE /stores/:id
  Future<void> deleteStore(String id) async {
    await _api.delete('/stores/$id');
  }
}
