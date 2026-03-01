import 'package:flutter/material.dart';
import '../../data/datasources/consignment_remote_datasource.dart';
import '../../domain/entities/consignment.dart';
import 'consignment_form_page.dart';
import 'consignment_detail_page.dart';
import '../stores/stores_list_page.dart';

class ConsignmentsListPage extends StatefulWidget {
  const ConsignmentsListPage({super.key});

  @override
  State<ConsignmentsListPage> createState() => _ConsignmentsListPageState();
}

class _ConsignmentsListPageState extends State<ConsignmentsListPage> {
  final _datasource = ConsignmentRemoteDatasource();
  List<Consignment> _list = [];
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
      final list = await _datasource.getConsignments();
      if (!mounted) return;
      setState(() {
        _list = list;
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

  void _openLojas() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoresListPage()));
    _load();
  }

  void _openNewConsignment() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ConsignmentFormPage()));
    if (created == true && mounted) _load();
  }

  void _openDetail(Consignment c) async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ConsignmentDetailPage(consignmentId: c.id)));
    if (updated == true && mounted) _load();
  }

  String _formatDate(String s) {
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
                : _list.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openLojas,
                          icon: const Icon(Icons.store),
                          label: const Text('Gerenciar lojas'),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        const Text('Nenhuma consignação.', textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text(
                          'Toque em + para registrar produtos deixados em lojas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OutlinedButton.icon(
                          onPressed: _openLojas,
                          icon: const Icon(Icons.store, size: 20),
                          label: const Text('Gerenciar lojas'),
                        ),
                      ),
                      ...List.generate(_list.length, (i) {
                        final c = _list[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              c.productName ?? c.productId,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 4),
                                Text(c.storeName ?? c.storeId),
                                Text(
                                  '${c.quantity} deixados · ${c.quantityReturned} devolvidos · ${_formatDate(c.placedAt)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openDetail(c),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openNewConsignment,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
