import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../domain/entities/order.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _datasource = OrderRemoteDatasource();
  Order? _order;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  bool _savingShipping = false;

  final _trackingCodeController = TextEditingController();
  final _carrierController = TextEditingController();
  final _trackingUrlController = TextEditingController();
  DateTime? _shippedAtDate;
  ShippingStatus? _shippingStatusValue;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _trackingCodeController.dispose();
    _carrierController.dispose();
    _trackingUrlController.dispose();
    super.dispose();
  }

  void _syncShippingFromOrder() {
    final o = _order;
    if (o == null) return;
    _trackingCodeController.text = o.trackingCode ?? '';
    _carrierController.text = o.carrier ?? o.shippingCarrier ?? '';
    _trackingUrlController.text = o.trackingUrl ?? '';
    _shippedAtDate = _parseShippedAt(o.shippedAt);
    _shippingStatusValue = ShippingStatus.fromString(o.shippingStatus);
  }

  static DateTime? _parseShippedAt(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return DateTime.tryParse(v.trim());
  }

  static String? _shippedAtToIso(DateTime? d) {
    if (d == null) return null;
    return d.toIso8601String();
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatCancellationRequestedAt(String isoStr) {
    final dt = DateTime.tryParse(isoStr.trim());
    if (dt == null) return 'Solicitado em: $isoStr';
    return 'Solicitado em: ${_formatDate(dt)} às ${_formatTime(dt)}';
  }

  Future<void> _pickShippedAtDate() async {
    if (_savingShipping) return;
    final now = DateTime.now();
    final initial = _shippedAtDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      helpText: 'Data do envio',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Horário do envio',
    );
    if (!mounted) return;
    setState(() {
      _shippedAtDate = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? 0,
        time?.minute ?? 0,
      );
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await _datasource.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
        _syncShippingFromOrder();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (_order == null || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _datasource.updateStatus(widget.orderId, status);
      if (!mounted) return;
      setState(() {
        _order = updated;
        _saving = false;
        _syncShippingFromOrder();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _updateShipping() async {
    if (_order == null || _savingShipping) return;
    setState(() => _savingShipping = true);
    try {
      final updated = await _datasource.updateShipping(
        widget.orderId,
        shippingStatus: _shippingStatusValue,
        trackingCode: _trackingCodeController.text.trim().isEmpty
            ? null
            : _trackingCodeController.text.trim(),
        carrier: _carrierController.text.trim().isEmpty
            ? null
            : _carrierController.text.trim(),
        trackingUrl: _trackingUrlController.text.trim().isEmpty
            ? null
            : _trackingUrlController.text.trim(),
        shippedAt: _shippedAtToIso(_shippedAtDate),
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _savingShipping = false;
        _syncShippingFromOrder();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega atualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingShipping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  List<Widget> _buildAddressLines(Map<String, dynamic> address) {
    final recipient = address['recipientName'] as String?;
    final street = address['street'] as String?;
    final number = address['number'] as String?;
    final complement = address['complement'] as String?;
    final neighborhood = address['neighborhood'] as String?;
    final city = address['city'] as String?;
    final state = address['state'] as String?;
    final zipCode = address['zipCode'] as String?;
    final parts = <String>[];
    if (recipient != null && recipient.isNotEmpty) parts.add(recipient);
    if (street != null && street.isNotEmpty) {
      parts.add('$street${number != null && number.isNotEmpty ? ', $number' : ''}');
      if (complement != null && complement.isNotEmpty) parts.add(complement);
    }
    if (neighborhood != null && neighborhood.isNotEmpty) parts.add(neighborhood);
    if (city != null && state != null) {
      parts.add('$city - $state');
    } else if (city != null) {
      parts.add(city);
    }
    if (zipCode != null && zipCode.isNotEmpty) parts.add('CEP $zipCode');
    if (parts.isEmpty) return [const Text('—')];
    return parts.map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(p),
    )).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _order != null
              ? 'Pedido #${_order!.id.length >= 8 ? _order!.id.substring(0, 8) : _order!.id}'
              : 'Pedido',
        ),
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
              : _order == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_order!.cancellationRequestedAt != null &&
                              _order!.cancellationRequestedAt!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                border: Border.all(color: Colors.amber.shade700, width: 2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.amber.shade800,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CANCELAMENTO SOLICITADO',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'O cliente solicitou o cancelamento deste pedido. '
                                          'Analise e processe o estorno manualmente no AbacatePay.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.amber.shade900,
                                          ),
                                        ),
                                        if (_order!.cancellationRequestedAt != null &&
                                            _order!.cancellationRequestedAt!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            _formatCancellationRequestedAt(_order!.cancellationRequestedAt!),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ],
                                        if (_order!.cancellationReason != null &&
                                            _order!.cancellationReason!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Motivo: ${_order!.cancellationReason}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                              color: Colors.amber.shade800,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if ((_order!.shippingCarrier != null &&
                                  _order!.shippingCarrier!.isNotEmpty) ||
                              (_order!.shippingPrice != null &&
                                  _order!.shippingPrice! > 0)) ...[
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.local_shipping),
                                title: Text(
                                  _order!.shippingCarrier ?? 'Frete',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: _order!.shippingDays != null
                                    ? Text('Até ${_order!.shippingDays} dias úteis')
                                    : null,
                                trailing: _order!.shippingPrice != null && _order!.shippingPrice! > 0
                                    ? Text(
                                        'R\$ ${_order!.shippingPrice!.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<OrderStatus>(
                                    value: _order!.status,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    items: OrderStatus.values
                                        .map((s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s.label),
                                            ))
                                        .toList(),
                                    onChanged: _saving
                                        ? null
                                        : (v) {
                                            if (v != null) _updateStatus(v);
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: ListTile(
                              title: const Text('Total'),
                              trailing: Text(
                                'R\$ ${_order!.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          if (_order!.user != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cliente',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    _detailRow('Nome', _order!.user!.fullName),
                                    _detailRow('E-mail', _order!.user!.email),
                                    if (_order!.user!.phoneNumber != null &&
                                        _order!.user!.phoneNumber!.isNotEmpty)
                                      _detailRow('Telefone', _order!.user!.phoneNumber!),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_order!.address != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Entrega',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ..._buildAddressLines(_order!.address!),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dados de envio',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<ShippingStatus>(
                                      value: _shippingStatusValue ?? ShippingStatus.pending,
                                      decoration: const InputDecoration(
                                        labelText: 'Status da entrega',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      items: ShippingStatus.values
                                          .map((s) => DropdownMenuItem(
                                                value: s,
                                                child: Text(s.label),
                                              ))
                                          .toList(),
                                      onChanged: _savingShipping
                                          ? null
                                          : (v) {
                                              if (v != null) {
                                                setState(() => _shippingStatusValue = v);
                                              }
                                            },
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _trackingCodeController,
                                      decoration: const InputDecoration(
                                        labelText: 'Código de rastreio',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      textCapitalization: TextCapitalization.characters,
                                      enabled: !_savingShipping,
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _carrierController,
                                      decoration: const InputDecoration(
                                        labelText: 'Transportadora',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      enabled: !_savingShipping,
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _trackingUrlController,
                                      decoration: const InputDecoration(
                                        labelText: 'URL de rastreio',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      keyboardType: TextInputType.url,
                                      enabled: !_savingShipping,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Data do envio',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: _savingShipping ? null : _pickShippedAtDate,
                                            icon: const Icon(Icons.calendar_today, size: 18),
                                            label: Text(
                                              _shippedAtDate != null
                                                  ? '${_formatDate(_shippedAtDate!)} ${_formatTime(_shippedAtDate!)}'
                                                  : 'Selecionar data e hora',
                                            ),
                                          ),
                                        ),
                                        if (_shippedAtDate != null) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: _savingShipping
                                                ? null
                                                : () => setState(() => _shippedAtDate = null),
                                            icon: const Icon(Icons.clear),
                                            tooltip: 'Limpar data',
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _savingShipping
                                            ? null
                                            : _updateShipping,
                                        icon: _savingShipping
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.save, size: 20),
                                        label: Text(
                                          _savingShipping
                                              ? 'Salvando...'
                                              : 'Salvar alterações da entrega',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_order!.payments != null && _order!.payments!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pagamento',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ..._order!.payments!.map(
                                      (p) => Padding(
                                        padding: const EdgeInsets.only(bottom: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${p.type.label} — ${p.status.label}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'R\$ ${p.amount.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (p.billingId != null &&
                                                p.billingId!.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'ID da cobrança:',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SelectableText(
                                                      p.billingId!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontFamily: 'monospace',
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.copy, size: 20),
                                                    tooltip: 'Copiar ID da cobrança',
                                                    onPressed: () {
                                                      Clipboard.setData(
                                                        ClipboardData(text: p.billingId!),
                                                      );
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'ID da cobrança copiado',
                                                              ),
                                                              duration: Duration(
                                                                seconds: 2,
                                                              ),
                                                            ),
                                                          );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_order!.items != null && _order!.items!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Itens',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ..._order!.items!.map(
                                      (item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.productName ?? 'Produto',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${item.quantity} × R\$ ${item.unitPrice.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
