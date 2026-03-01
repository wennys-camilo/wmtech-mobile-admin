import 'package:flutter/material.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../../domain/entities/store.dart';

/// Lista e gerencia lojas (parceiros) para consignação.
class StoresListPage extends StatefulWidget {
  const StoresListPage({super.key});

  @override
  State<StoresListPage> createState() => _StoresListPageState();
}

class _StoresListPageState extends State<StoresListPage> {
  final _datasource = StoreRemoteDatasource();
  List<Store> _stores = [];
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
      final list = await _datasource.getStores();
      if (!mounted) return;
      setState(() {
        _stores = list;
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

  Future<void> _showCreateDialog() async {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nova loja'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da loja *',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contato',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Criar'),
              ),
            ],
          ),
    );
    if (result != true || !mounted) return;
    try {
      await _datasource.createStore(
        Store(
          id: '',
          name: nameController.text.trim(),
          contactName: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loja criada.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _showEditDialog(Store store) async {
    final nameController = TextEditingController(text: store.name);
    final contactController = TextEditingController(text: store.contactName ?? '');
    final phoneController = TextEditingController(text: store.phone ?? '');
    final addressController = TextEditingController(text: store.address ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Editar loja'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da loja *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contactController,
                    decoration: const InputDecoration(
                      labelText: 'Contato',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Telefone',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Endereço',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
    if (result != true || !mounted) return;
    try {
      await _datasource.updateStore(
        store.id,
        Store(
          id: store.id,
          name: nameController.text.trim(),
          contactName: contactController.text.trim().isEmpty ? null : contactController.text.trim(),
          phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
          address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loja atualizada.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmDelete(Store store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir loja'),
            content: Text(
              'Excluir "${store.name}"? Consignações desta loja também serão removidas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (ok != true || !mounted) return;
    try {
      await _datasource.deleteStore(store.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Loja excluída.')));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body:
            _loading
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
                        FilledButton(onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
                : _stores.isEmpty
                ? const Center(child: Text('Nenhuma loja. Adicione lojas para consignar.'))
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _stores.length,
                    itemBuilder: (_, i) {
                      final s = _stores[i];
                      return ListTile(
                        title: Text(s.name),
                        subtitle:
                            [
                                  if (s.contactName != null) s.contactName,
                                  if (s.phone != null) s.phone,
                                ].where((e) => e != null && e.toString().isNotEmpty).isEmpty
                                ? null
                                : Text(
                                  [
                                    s.contactName,
                                    s.phone,
                                  ].where((e) => e != null && e.toString().isNotEmpty).join(' · '),
                                ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit')
                              _showEditDialog(s);
                            else if (v == 'delete')
                              _confirmDelete(s);
                          },
                          itemBuilder:
                              (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                              ],
                        ),
                      );
                    },
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
