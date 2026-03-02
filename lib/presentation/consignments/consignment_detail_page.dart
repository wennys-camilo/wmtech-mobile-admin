import 'package:flutter/material.dart';
import '../../data/datasources/consignment_remote_datasource.dart';
import '../../domain/entities/consignment.dart';
import '../../domain/entities/consignment_reconciliation_log.dart';

class ConsignmentDetailPage extends StatefulWidget {
  const ConsignmentDetailPage({super.key, required this.consignmentId});

  final String consignmentId;

  @override
  State<ConsignmentDetailPage> createState() => _ConsignmentDetailPageState();
}

class _ConsignmentDetailPageState extends State<ConsignmentDetailPage> {
  final _datasource = ConsignmentRemoteDatasource();
  Consignment? _consignment;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<ConsignmentReconciliationLog>? _reconciliationLogs;
  bool? _reconciliationLogsAvailable; // true = loaded, false = API not available, null = not loaded

  final _countAtStoreController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countAtStoreController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncFromConsignment(Consignment c) {
    _countAtStoreController.text = c.countAtStore != null ? '${c.countAtStore}' : '';
    _notesController.text = c.notes ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _reconciliationLogs = null;
      _reconciliationLogsAvailable = null;
    });
    try {
      final c = await _datasource.getConsignmentById(widget.consignmentId);
      if (!mounted) return;
      setState(() {
        _consignment = c;
        _loading = false;
        _syncFromConsignment(c);
      });
      _loadReconciliationLogs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadReconciliationLogs() async {
    try {
      final list = await _datasource.getReconciliationLogs(widget.consignmentId);
      if (!mounted) return;
      setState(() {
        _reconciliationLogs = list;
        _reconciliationLogsAvailable = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _reconciliationLogsAvailable = false);
    }
  }

  Future<void> _save() async {
    final c = _consignment;
    if (c == null || _saving) return;
    final countStr = _countAtStoreController.text.trim();
    final countAtStore = countStr.isEmpty ? null : int.tryParse(countStr);
    if (countStr.isNotEmpty && (countAtStore == null || countAtStore < 0 || countAtStore > c.quantity)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Contagem na loja deve ser entre 0 e ${c.quantity}',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _datasource.updateConsignment(
        c.id,
        countAtStore: countAtStore,
        updateCountAtStore: true,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _consignment = updated;
        _saving = false;
        _syncFromConsignment(updated);
      });
      _loadReconciliationLogs();
      final vendidos = updated.quantitySold ?? 0;
      final valor = updated.totalSalesValue;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            valor != null
                ? 'Conferência salva. Vendidos: $vendidos · Valor: R\$ ${valor.toStringAsFixed(2)}'
                : 'Conferência salva. Vendidos: $vendidos',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final c = _consignment;
    if (c == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir consignação'),
        content: Text(
          'Excluir registro de ${c.quantity} "${c.productName ?? c.productId}" em ${c.storeName ?? c.storeId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _datasource.deleteConsignment(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consignação excluída.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _formatPlacedAt(String s) {
    if (s.length >= 10) {
      final parts = s.substring(0, 10).split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    return s;
  }

  String _formatCurrency(double? v) {
    if (v == null) return '—';
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatLoggedAt(String s) {
    if (s.length >= 19) {
      final date = s.substring(0, 10).split('-');
      final time = s.substring(11, 19);
      if (date.length == 3) return '${date[2]}/${date[1]}/${date[0]} $time';
    }
    if (s.length >= 10) {
      final date = s.substring(0, 10).split('-');
      if (date.length == 3) return '${date[2]}/${date[1]}/${date[0]}';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consignação')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _consignment == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consignação')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error ?? 'Não encontrado', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ),
      );
    }

    final c = _consignment!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consignação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _saving ? null : _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.storeName ?? c.storeId,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.productName ?? c.productId,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Data: ${_formatPlacedAt(c.placedAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conferência',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Deixados: ${c.quantity}'),
                    Text('Contagem na loja: ${c.countAtStore ?? '—'}'),
                    Text('Vendidos: ${c.quantitySold != null ? c.quantitySold : 'Não conferido'}'),
                    Text('Preço no dia: ${_formatCurrency(c.unitPriceAtPlacement)}'),
                    Text('Valor total vendidos: ${_formatCurrency(c.totalSalesValue)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Contagem atual na loja',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countAtStoreController,
              decoration: InputDecoration(
                hintText: 'Quantidade que ainda está na loja hoje (0 a ${c.quantity})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            Text(
              'Observações',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar alterações'),
            ),
            if (_reconciliationLogsAvailable == true) ...[
              const SizedBox(height: 24),
              Text(
                'Histórico de conferências',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: _reconciliationLogs == null
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _reconciliationLogs!.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Nenhuma conferência registrada ainda.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _reconciliationLogs!.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final log = _reconciliationLogs![i];
                              return ListTile(
                                title: Text('${_formatLoggedAt(log.loggedAt)} · Contagem: ${log.countAtStore}'),
                                subtitle: log.notes != null && log.notes!.isNotEmpty
                                    ? Text(log.notes!)
                                    : null,
                              );
                            },
                          ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
