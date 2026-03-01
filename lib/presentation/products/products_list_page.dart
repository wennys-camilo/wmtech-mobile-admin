import 'package:flutter/material.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/repositories/product_repository_impl.dart';
import 'product_form_page.dart';

/// Lista de produtos. Usa [ProductRepository]; não chama API na view.
class ProductsListPage extends StatefulWidget {
  ProductsListPage({super.key, ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductRepositoryImpl();

  final ProductRepository _productRepository;

  @override
  State<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends State<ProductsListPage> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;
  bool _includeInactive = false;

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
      final list = await widget._productRepository.getProducts(includeInactive: _includeInactive);
      if (!mounted) return;
      setState(() {
        _products = list;
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

  void _openForm([Product? product]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ProductFormPage(productRepository: widget._productRepository, product: product),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _load),
                FilterChip(
                  label: Text(_includeInactive ? 'Incluir inativos' : 'Só ativos'),
                  selected: _includeInactive,
                  onSelected: (v) {
                    setState(() {
                      _includeInactive = v;
                      _load();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
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
                    : _products.isEmpty
                    ? const Center(child: Text('Nenhum produto cadastrado.'))
                    : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _products.length,
                        itemBuilder: (_, i) {
                          final p = _products[i];
                          return ListTile(
                            title: Text(p.name),
                            subtitle: Text(
                              'R\$ ${p.price.toStringAsFixed(2)} • Estoque: ${p.stock}${p.active ? '' : ' • Inativo'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openForm(p),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
