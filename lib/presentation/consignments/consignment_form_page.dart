import 'package:flutter/material.dart';
import '../../data/datasources/consignment_remote_datasource.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/product.dart';

/// Formulário para criar nova consignação.
class ConsignmentFormPage extends StatefulWidget {
  const ConsignmentFormPage({super.key});

  @override
  State<ConsignmentFormPage> createState() => _ConsignmentFormPageState();
}

class _ConsignmentFormPageState extends State<ConsignmentFormPage> {
  final _consignmentDs = ConsignmentRemoteDatasource();
  final _storeDs = StoreRemoteDatasource();
  final _productDs = ProductRemoteDatasource();

  List<Store> _stores = [];
  List<Product> _products = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _selectedStoreId;
  String? _selectedProductId;
  final _quantityController = TextEditingController(text: '1');
  DateTime _placedAt = DateTime.now();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stores = await _storeDs.getStores();
      final products = await _productDs.getProducts(includeInactive: true);
      if (!mounted) return;
      setState(() {
        _stores = stores;
        _products = products;
        _loading = false;
        if (_stores.isNotEmpty && _selectedStoreId == null) _selectedStoreId = _stores.first.id;
        if (_products.isNotEmpty && _selectedProductId == null)
          _selectedProductId = _products.first.id;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _placedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null && mounted) {
      setState(() {
        _placedAt = DateTime(date.year, date.month, date.day, _placedAt.hour, _placedAt.minute);
      });
    }
  }

  Future<void> _submit() async {
    final storeId = _selectedStoreId;
    final productId = _selectedProductId;
    if (storeId == null || storeId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma loja')));
      return;
    }
    if (productId == null || productId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione um produto')));
      return;
    }
    final qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Informe a quantidade (mín. 1)')));
      return;
    }
    setState(() => _saving = true);
    try {
      final placedAtStr =
          '${_placedAt.year}-${_placedAt.month.toString().padLeft(2, '0')}-${_placedAt.day.toString().padLeft(2, '0')}';
      await _consignmentDs.createConsignment(
        storeId: storeId,
        productId: productId,
        quantity: qty,
        placedAt: placedAtStr,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Consignação registrada.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova consignação')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova consignação')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
              ],
            ),
          ),
        ),
      );
    }
    if (_stores.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova consignação')),
        body: const Center(child: Text('Cadastre ao menos uma loja antes de criar consignações.')),
      );
    }
    if (_products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nova consignação')),
        body: const Center(child: Text('Não há produtos cadastrados.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Nova consignação')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedStoreId,
              decoration: const InputDecoration(labelText: 'Loja', border: OutlineInputBorder()),
              items:
                  _stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
              onChanged: _saving ? null : (v) => setState(() => _selectedStoreId = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              value: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Produto', border: OutlineInputBorder()),
              items:
                  _products
                      .map(
                        (p) => DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (R\$ ${p.price.toStringAsFixed(2)})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
              onChanged: _saving ? null : (v) => setState(() => _selectedProductId = v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantidade deixada',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              enabled: !_saving,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Data'),
              subtitle: Text(_formatDate(_placedAt)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _saving ? null : _pickDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              enabled: !_saving,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child:
                  _saving
                      ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Registrar consignação'),
            ),
          ],
        ),
      ),
    );
  }
}
