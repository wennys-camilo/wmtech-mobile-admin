import '../../core/api_client.dart';
import '../../domain/entities/consignment.dart';

class ConsignmentRemoteDatasource {
  ConsignmentRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /consignments — lista consignações (admin).
  Future<List<Consignment>> getConsignments() async {
    final list = await _api.get<List<dynamic>>(
      '/consignments',
      (v) => v is List ? v : [],
    );
    return list
        .map((e) {
          try {
            return Consignment.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<Consignment>()
        .toList();
  }

  /// GET /consignments/:id
  Future<Consignment> getConsignmentById(String id) async {
    return _api.get<Consignment>('/consignments/$id', (v) => Consignment.fromJson(v));
  }

  /// POST /consignments
  Future<Consignment> createConsignment({
    required String storeId,
    required String productId,
    required int quantity,
    required String placedAt,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'storeId': storeId,
      'productId': productId,
      'quantity': quantity,
      'placedAt': placedAt,
    };
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;
    return _api.post<Consignment>('/consignments', body, (v) => Consignment.fromJson(v));
  }

  /// PATCH /consignments/:id
  Future<Consignment> updateConsignment(
    String id, {
    int? quantityReturned,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (quantityReturned != null) body['quantityReturned'] = quantityReturned;
    if (notes != null) body['notes'] = notes;
    return _api.patch<Consignment>('/consignments/$id', body, (v) => Consignment.fromJson(v));
  }

  /// DELETE /consignments/:id
  Future<void> deleteConsignment(String id) async {
    await _api.delete('/consignments/$id');
  }
}
