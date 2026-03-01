import 'package:flutter/material.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../domain/entities/order.dart';
import 'order_detail_page.dart';

enum _BadgeType { neutral, success, warning, error, info }

extension _BadgeTypeColors on _BadgeType {
  Color color(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case _BadgeType.success:
        return scheme.primary;
      case _BadgeType.warning:
        return scheme.tertiary;
      case _BadgeType.error:
        return scheme.error;
      case _BadgeType.info:
        return scheme.secondary;
      case _BadgeType.neutral:
        return scheme.onSurfaceVariant;
    }
  }
}

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  final _datasource = OrderRemoteDatasource();
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _datasource.getAllOrders();
      if (!mounted) return;
      setState(() {
        _orders = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _openDetail(Order order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailPage(orderId: order.id),
      ),
    );
    _load();
  }

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required _BadgeType type,
  }) {
    final color = type.color(context);
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  _BadgeType _orderStatusType(OrderStatus s) {
    switch (s) {
      case OrderStatus.cancelled:
        return _BadgeType.error;
      case OrderStatus.delivered:
        return _BadgeType.success;
      case OrderStatus.shipped:
      case OrderStatus.preparing:
      case OrderStatus.confirmed:
        return _BadgeType.info;
      case OrderStatus.pending:
        return _BadgeType.warning;
    }
  }

  _BadgeType _shippingStatusType(String? raw) {
    final s = ShippingStatus.fromString(raw);
    if (s == null) return _BadgeType.neutral;
    switch (s) {
      case ShippingStatus.delivered:
        return _BadgeType.success;
      case ShippingStatus.in_transit:
      case ShippingStatus.out_for_delivery:
      case ShippingStatus.shipped:
        return _BadgeType.info;
      case ShippingStatus.pending:
        return _BadgeType.warning;
    }
  }

  _BadgeType _paymentStatusType(List<OrderPaymentEntity>? payments) {
    if (payments == null || payments.isEmpty) return _BadgeType.neutral;
    if (payments.any((p) => p.status == PaymentStatus.refused)) return _BadgeType.error;
    if (payments.any((p) => p.status == PaymentStatus.pending)) return _BadgeType.warning;
    if (payments.any((p) => p.status == PaymentStatus.cancelled)) return _BadgeType.error;
    return _BadgeType.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? const Center(child: Text('Nenhum pedido.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) {
                          final o = _orders[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                'Pedido #${o.id.length >= 8 ? o.id.substring(0, 8) : o.id}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _statusChip(
                                        context,
                                        label: o.status.label,
                                        type: _orderStatusType(o.status),
                                      ),
                                      _statusChip(
                                        context,
                                        label: o.shippingStatusLabel,
                                        type: _shippingStatusType(o.shippingStatus),
                                      ),
                                      _statusChip(
                                        context,
                                        label: o.paymentSummaryLabel,
                                        type: _paymentStatusType(o.payments),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'R\$ ${o.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openDetail(o),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
