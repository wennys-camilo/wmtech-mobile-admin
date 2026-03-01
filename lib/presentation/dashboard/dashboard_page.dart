import 'package:flutter/material.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../orders/orders_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _datasource = DashboardRemoteDatasource();
  DashboardStats? _stats;
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
      final stats = await _datasource.getStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  void _goToOrders() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrdersListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
      );
    }

    final s = _stats!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumo de pedidos',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _StatCard(
              title: 'Novos pedidos',
              subtitle: 'Aguardando pagamento',
              count: s.newOrders,
              icon: Icons.shopping_cart_outlined,
              color: colorScheme.tertiary,
              onTap: _goToOrders,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'A enviar',
              subtitle: 'Confirmados / em preparação',
              count: s.toShip,
              icon: Icons.local_shipping_outlined,
              color: colorScheme.primary,
              onTap: _goToOrders,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Enviados',
              subtitle: 'Em trânsito',
              count: s.shipped,
              icon: Icons.delivery_dining,
              color: colorScheme.secondary,
              onTap: _goToOrders,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Entregues',
              subtitle: 'Concluídos',
              count: s.delivered,
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: _goToOrders,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Cancelamento solicitado',
              subtitle: 'Aguardando análise',
              count: s.cancellationRequested,
              icon: Icons.pending_actions,
              color: colorScheme.error,
              onTap: _goToOrders,
            ),
            const SizedBox(height: 12),
            _StatCard(
              title: 'Cancelados',
              subtitle: 'Pedidos cancelados',
              count: s.cancelled,
              icon: Icons.cancel_outlined,
              color: colorScheme.outline,
              onTap: _goToOrders,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
