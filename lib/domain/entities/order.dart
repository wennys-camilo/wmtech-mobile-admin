/// Status do pedido (espelho do backend).
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  shipped,
  delivered,
  cancelled;

  static OrderStatus? fromString(String? v) {
    if (v == null) return null;
    for (final e in OrderStatus.values) {
      if (e.name == v) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.preparing:
        return 'Em preparação';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// Status do envio/entrega (espelho do backend).
enum ShippingStatus {
  pending,
  shipped,
  in_transit,
  out_for_delivery,
  delivered;

  static ShippingStatus? fromString(String? v) {
    if (v == null) return null;
    final n = v.replaceAll(' ', '_');
    for (final e in ShippingStatus.values) {
      if (e.name == n) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case ShippingStatus.pending:
        return 'Pendente';
      case ShippingStatus.shipped:
        return 'Enviado';
      case ShippingStatus.in_transit:
        return 'Em trânsito';
      case ShippingStatus.out_for_delivery:
        return 'Saiu para entrega';
      case ShippingStatus.delivered:
        return 'Entregue';
    }
  }
}

class OrderItemEntity {
  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productName,
  });

  final String id;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? productName;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static OrderItemEntity fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid order item');
    final map = Map<String, dynamic>.from(json);
    final product = map['product'];
    final qty = map['quantity'];
    final q = qty is num ? qty.toInt() : int.tryParse(qty?.toString() ?? '') ?? 0;
    return OrderItemEntity(
      id: map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      quantity: q,
      unitPrice: _toDouble(map['unitPrice']),
      productName: product is Map ? product['name'] as String? : null,
    );
  }
}

/// Dados do cliente no pedido (vem do backend, sem senha).
class OrderClientEntity {
  const OrderClientEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;

  static OrderClientEntity? fromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final id = map['id'] as String?;
    final fullName = map['fullName'] as String?;
    final email = map['email'] as String?;
    if (id == null || fullName == null || email == null) return null;
    return OrderClientEntity(
      id: id,
      fullName: fullName,
      email: email,
      phoneNumber: map['phoneNumber'] as String?,
    );
  }
}

/// Status do pagamento (espelho do backend).
enum PaymentStatus {
  pending,
  approved,
  refused,
  cancelled;

  static PaymentStatus? fromString(String? v) {
    if (v == null) return null;
    for (final e in PaymentStatus.values) {
      if (e.name == v) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.approved:
        return 'Aprovado';
      case PaymentStatus.refused:
        return 'Recusado';
      case PaymentStatus.cancelled:
        return 'Cancelado';
    }
  }
}

/// Tipo de pagamento (espelho do backend).
enum PaymentType {
  credit_card,
  debit_card,
  pix,
  boleto;

  static PaymentType? fromString(String? v) {
    if (v == null) return null;
    final normalized = v.replaceAll(' ', '_');
    for (final e in PaymentType.values) {
      if (e.name == normalized) return e;
    }
    return null;
  }

  String get label {
    switch (this) {
      case PaymentType.credit_card:
        return 'Cartão de crédito';
      case PaymentType.debit_card:
        return 'Cartão de débito';
      case PaymentType.pix:
        return 'PIX';
      case PaymentType.boleto:
        return 'Boleto';
    }
  }
}

class OrderPaymentEntity {
  const OrderPaymentEntity({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    this.createdAt,
  });

  final String id;
  final PaymentType type;
  final PaymentStatus status;
  final double amount;
  final String? createdAt;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static OrderPaymentEntity? fromJson(dynamic json) {
    if (json == null || json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    final id = map['id'] as String? ?? '';
    final type = PaymentType.fromString((map['type'] as String?)?.replaceAll(' ', '_'));
    final status = PaymentStatus.fromString(map['status'] as String?);
    if (type == null || status == null) return null;
    final createdAt = map['createdAt'] ?? map['created_at'];
    final createdAtStr = createdAt is String
        ? createdAt
        : (createdAt != null && createdAt.toString().isNotEmpty)
            ? createdAt.toString()
            : null;
    return OrderPaymentEntity(
      id: id,
      type: type,
      status: status,
      amount: _toDouble(map['amount']),
      createdAt: createdAtStr,
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.total,
    required this.createdAt,
    this.items,
    this.address,
    this.user,
    this.payments,
    this.trackingCode,
    this.carrier,
    this.trackingUrl,
    this.shippedAt,
    this.shippingStatus,
  });

  final String id;
  final String userId;
  final OrderStatus status;
  final double total;
  final String createdAt;
  final List<OrderItemEntity>? items;
  final Map<String, dynamic>? address;
  final OrderClientEntity? user;
  final List<OrderPaymentEntity>? payments;
  final String? trackingCode;
  final String? carrier;
  final String? trackingUrl;
  final String? shippedAt;
  final String? shippingStatus;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  static Order fromJson(dynamic json) {
    if (json == null || json is! Map) throw FormatException('Invalid order');
    final map = Map<String, dynamic>.from(json);
    final itemsList = map['items'];
    List<OrderItemEntity> items = [];
    if (itemsList is List) {
      for (final e in itemsList) {
        try {
          items.add(OrderItemEntity.fromJson(e));
        } catch (_) {}
      }
    }
    final paymentsList = map['payments'];
    List<OrderPaymentEntity> payments = [];
    if (paymentsList is List) {
      for (final e in paymentsList) {
        final p = OrderPaymentEntity.fromJson(e);
        if (p != null) payments.add(p);
      }
    }
    final createdAt = map['createdAt'] ?? map['created_at'];
    final createdAtStr = createdAt is String
        ? createdAt
        : (createdAt != null && createdAt.toString().isNotEmpty)
            ? createdAt.toString()
            : '';
    return Order(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      status: OrderStatus.fromString(map['status'] as String?) ?? OrderStatus.pending,
      total: _toDouble(map['total']),
      createdAt: createdAtStr,
      items: items.isEmpty ? null : items,
      address: map['address'] is Map ? Map<String, dynamic>.from(map['address'] as Map) : null,
      user: OrderClientEntity.fromJson(map['user']),
      payments: payments.isEmpty ? null : payments,
      trackingCode: map['trackingCode'] as String? ?? map['tracking_code'] as String?,
      carrier: map['carrier'] as String?,
      trackingUrl: map['trackingUrl'] as String? ?? map['tracking_url'] as String?,
      shippedAt: _dateStr(map['shippedAt'] ?? map['shipped_at']),
      shippingStatus: map['shippingStatus'] as String? ?? map['shipping_status'] as String?,
    );
  }

  static String? _dateStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  /// Label do status de entrega para exibição (badge na listagem).
  String get shippingStatusLabel {
    final s = ShippingStatus.fromString(shippingStatus);
    return s?.label ?? '—';
  }

  /// Resumo do status dos pagamentos: pior status encontrado (recusado > pendente > aprovado).
  String get paymentSummaryLabel {
    final list = payments;
    if (list == null || list.isEmpty) return '—';
    if (list.any((p) => p.status == PaymentStatus.refused)) return 'Recusado';
    if (list.any((p) => p.status == PaymentStatus.pending)) return 'Pendente';
    if (list.any((p) => p.status == PaymentStatus.cancelled)) return 'Cancelado';
    return 'Aprovado';
  }
}
