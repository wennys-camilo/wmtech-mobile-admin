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

  String? _filterEmail;
  String? _filterCpf;
  String? _filterStatus;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;

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
      final list = await _datasource.getAllOrders(
        email: _filterEmail,
        cpf: _filterCpf,
        status: _filterStatus,
        dateFrom: _filterDateFrom,
        dateTo: _filterDateTo,
      );
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

  bool get _hasActiveFilters =>
      (_filterEmail != null && _filterEmail!.trim().isNotEmpty) ||
      (_filterCpf != null && _filterCpf!.trim().isNotEmpty) ||
      (_filterStatus != null && _filterStatus!.trim().isNotEmpty) ||
      _filterDateFrom != null ||
      _filterDateTo != null;

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OrdersFilterSheet(
        email: _filterEmail,
        cpf: _filterCpf,
        status: _filterStatus,
        dateFrom: _filterDateFrom,
        dateTo: _filterDateTo,
        onApply: (email, cpf, status, dateFrom, dateTo) {
          setState(() {
            _filterEmail = email;
            _filterCpf = cpf;
            _filterStatus = status;
            _filterDateFrom = dateFrom;
            _filterDateTo = dateTo;
          });
          _load();
          Navigator.of(ctx).pop();
        },
        onClear: () {
          setState(() {
            _filterEmail = null;
            _filterCpf = null;
            _filterStatus = null;
            _filterDateFrom = null;
            _filterDateTo = null;
          });
          _load();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  static String _formatOrderDateTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '—';
    final d = DateTime.tryParse(createdAt);
    if (d == null) return createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$min';
  }

  static String _formatCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    return cpf;
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
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _openFilters,
            tooltip: 'Filtros',
          ),
        ],
      ),
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
                                  Text(
                                    _formatOrderDateTime(o.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (o.user != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      o.user!.email,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (o.user!.cpf != null && o.user!.cpf!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'CPF: ${_formatCpf(o.user!.cpf!)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      if (o.cancellationRequestedAt != null &&
                                          o.cancellationRequestedAt!.isNotEmpty)
                                        _statusChip(
                                          context,
                                          label: 'Pedido: Cancelamento solicitado',
                                          type: _BadgeType.error,
                                        ),
                                      _statusChip(
                                        context,
                                        label: 'Pedido: ${o.status.label}',
                                        type: _orderStatusType(o.status),
                                      ),
                                      _statusChip(
                                        context,
                                        label: 'Entrega: ${o.shippingStatusLabel}',
                                        type: _shippingStatusType(o.shippingStatus),
                                      ),
                                      _statusChip(
                                        context,
                                        label: 'Pagamento: ${o.paymentSummaryLabel}',
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

class _OrdersFilterSheet extends StatefulWidget {
  const _OrdersFilterSheet({
    this.email,
    this.cpf,
    this.status,
    this.dateFrom,
    this.dateTo,
    required this.onApply,
    required this.onClear,
  });

  final String? email;
  final String? cpf;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final void Function(
    String? email,
    String? cpf,
    String? status,
    DateTime? dateFrom,
    DateTime? dateTo,
  ) onApply;
  final VoidCallback onClear;

  @override
  State<_OrdersFilterSheet> createState() => _OrdersFilterSheetState();
}

class _OrdersFilterSheetState extends State<_OrdersFilterSheet> {
  late final TextEditingController _emailController;
  late final TextEditingController _cpfController;
  String? _status;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _cpfController = TextEditingController(text: widget.cpf ?? '');
    _status = widget.status;
    _dateFrom = widget.dateFrom;
    _dateTo = widget.dateTo;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _dateFrom : _dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '';
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return '$day/$month/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-mail do cliente',
                hintText: 'Buscar por e-mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cpfController,
              decoration: const InputDecoration(
                labelText: 'CPF do cliente',
                hintText: 'Buscar por CPF',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status do pedido',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...OrderStatus.values.map(
                  (s) => DropdownMenuItem(value: s.name, child: Text(s.label)),
                ),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _dateFrom != null
                          ? _formatDate(_dateFrom)
                          : 'Data inicial',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _dateTo != null
                          ? _formatDate(_dateTo)
                          : 'Data final',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: widget.onClear,
                  child: const Text('Limpar'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      final cpf = _cpfController.text.trim();
                      widget.onApply(
                        email.isEmpty ? null : email,
                        cpf.isEmpty ? null : cpf,
                        _status,
                        _dateFrom,
                        _dateTo,
                      );
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
