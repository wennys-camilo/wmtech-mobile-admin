import 'package:flutter/material.dart';
import '../../data/datasources/consignment_remote_datasource.dart';
import '../../domain/entities/consignment.dart';

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

  final _quantityReturnedController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantityReturnedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncFromConsignment(Consignment c) {
    _quantityReturnedController.text = '${c.quantityReturned}';
    _notesController.text = c.notes ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _datasource.getConsignmentById(widget.consignmentId);
      if (!mounted) return;
      setState(() {
        _consignment = c;
        _loading = false;
        _syncFromConsignment(c);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final c = _consignment;
    if (c == null || _saving) return;
    final qtyReturned = int.tryParse(_quantityReturnedController.text.trim());
    if (qtyReturned == null || qtyReturned < 0 || qtyReturned > c.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quantidade devolvida deve ser entre 0 e ${c.quantity}',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await _datasource.updateConsignment(
        c.id,
        quantityReturned: qtyReturned,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _consignment = updated;
        _saving = false;
        _syncFromConsignment(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consignação atualizada.')),
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
                    Text('Deixados: ${c.quantity} · Devolvidos: ${c.quantityReturned} · Em loja: ${c.quantityRemaining}'),
                    Text('Data: ${_formatPlacedAt(c.placedAt)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Quantidade devolvida',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityReturnedController,
              decoration: InputDecoration(
                hintText: '0 a ${c.quantity}',
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
          ],
        ),
      ),
    );
  }
}
