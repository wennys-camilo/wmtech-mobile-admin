import 'package:flutter/foundation.dart';

import '../../core/api_client.dart';
import '../../domain/entities/order.dart';

class OrderRemoteDatasource {
  OrderRemoteDatasource([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  static String _dateToQuery(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// GET /orders — lista todos os pedidos se JWT for admin (com filtros opcionais), senão só do usuário.
  Future<List<Order>> getAllOrders({
    String? email,
    String? cpf,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final query = <String, String>{};
    if (email != null && email.trim().isNotEmpty) query['email'] = email.trim();
    if (cpf != null && cpf.trim().isNotEmpty) query['cpf'] = cpf.trim();
    if (status != null && status.trim().isNotEmpty) query['status'] = status.trim();
    if (dateFrom != null) query['dateFrom'] = _dateToQuery(dateFrom);
    if (dateTo != null) query['dateTo'] = _dateToQuery(dateTo);
    final path = query.isEmpty ? '/orders' : '/orders?${query.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}').join('&')}';
    try {
      final list = await _api.get<List<dynamic>>(path, (v) => v is List ? v : []);
      return list
          .map((e) {
            try {
              return Order.fromJson(e);
            } catch (e) {
              debugPrint('Error parsing order: $e');
              return null;
            }
          })
          .whereType<Order>()
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        throw ApiException(
          e.statusCode,
          'Acesso restrito a administradores. Faça login com conta admin (ex: admin@wmtech.com).',
        );
      }
      rethrow;
    }
  }

  /// GET /orders/:id — detalhe do pedido (qualquer pedido se JWT for admin).
  Future<Order> getOrderById(String id) async {
    return _api.get<Order>('/orders/$id', (v) => Order.fromJson(v));
  }

  /// PATCH /orders/:id/status — altera status do pedido.
  Future<Order> updateStatus(String orderId, OrderStatus status) async {
    return _api.patch<Order>('/orders/$orderId/status', {
      'status': status.name,
    }, (v) => Order.fromJson(v));
  }

  /// PATCH /orders/:id/shipping — altera dados da entrega (admin).
  Future<Order> updateShipping(
    String orderId, {
    ShippingStatus? shippingStatus,
    String? trackingCode,
    String? carrier,
    String? trackingUrl,
    String? shippedAt,
  }) async {
    final body = <String, dynamic>{};
    if (shippingStatus != null) body['shippingStatus'] = shippingStatus.name;
    if (trackingCode != null) body['trackingCode'] = trackingCode;
    if (carrier != null) body['carrier'] = carrier;
    if (trackingUrl != null) body['trackingUrl'] = trackingUrl;
    if (shippedAt != null) body['shippedAt'] = shippedAt;
    return _api.patch<Order>('/orders/$orderId/shipping', body, (v) => Order.fromJson(v));
  }
}
