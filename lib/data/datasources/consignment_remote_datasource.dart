import '../../core/api_client.dart';
import '../../domain/entities/consignment.dart';
import '../../domain/entities/consignment_reconciliation_log.dart';

class ConsignmentRemoteDatasource {
  ConsignmentRemoteDatasource([ApiClient? apiClient])
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  /// GET /consignments — lista consignações (admin). Opcional storeId para filtrar por loja.
  Future<List<Consignment>> getConsignments({String? storeId}) async {
    final path = storeId != null && storeId.isNotEmpty
        ? '/consignments?storeId=${Uri.encodeComponent(storeId)}'
        : '/consignments';
    final list = await _api.get<List<dynamic>>(
      path,
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

  /// PATCH /consignments/:id. countAtStore = contagem na loja (reconciliação); incluir updateCountAtStore: true para enviar (ou null para limpar).
  Future<Consignment> updateConsignment(
    String id, {
    int? countAtStore,
    bool updateCountAtStore = false,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (updateCountAtStore) body['countAtStore'] = countAtStore;
    if (notes != null) body['notes'] = notes;
    return _api.patch<Consignment>('/consignments/$id', body, (v) => Consignment.fromJson(v));
  }

  /// DELETE /consignments/:id
  Future<void> deleteConsignment(String id) async {
    await _api.delete('/consignments/$id');
  }

  /// GET /consignments/:id/reconciliation-logs — histórico de conferências (quando disponível na API).
  Future<List<ConsignmentReconciliationLog>> getReconciliationLogs(String consignmentId) async {
    final list = await _api.get<List<dynamic>>(
      '/consignments/$consignmentId/reconciliation-logs',
      (v) => v is List ? v : [],
    );
    return list
        .map((e) {
          try {
            return ConsignmentReconciliationLog.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<ConsignmentReconciliationLog>()
        .toList();
  }
}
