import 'package:flutter/material.dart';
import '../login/login_page.dart';
import '../dashboard/dashboard_page.dart';
import '../products/products_list_page.dart';
import '../orders/orders_list_page.dart';
import '../categories/categories_list_page.dart';
import '../sections/sections_list_page.dart';
import '../consignments/consignments_list_page.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// Tela principal do admin: drawer com Dashboard, Pedidos, Produtos, etc.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static final _pages = [
    _Page(title: 'Dashboard', icon: Icons.dashboard, child: DashboardPage()),
    _Page(title: 'Pedidos', icon: Icons.shopping_bag, child: OrdersListPage()),
    _Page(title: 'Produtos', icon: Icons.inventory_2, child: ProductsListPage()),
    _Page(title: 'Consignados', icon: Icons.storefront, child: ConsignmentsListPage()),
    _Page(title: 'Categorias', icon: Icons.category, child: CategoriesListPage()),
    _Page(title: 'Seções', icon: Icons.view_list, child: SectionsListPage()),
  ];

  void _onDrawerItem(int index) {
    setState(() => _selectedIndex = index);
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    Navigator.of(context).pop();
    await AuthRepositoryImpl().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_pages[_selectedIndex].title),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'wmtech Admin',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ...List.generate(_pages.length, (i) {
              final p = _pages[i];
              return ListTile(
                leading: Icon(p.icon),
                title: Text(p.title),
                selected: _selectedIndex == i,
                onTap: () => _onDrawerItem(i),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex].child,
    );
  }
}

class _Page {
  const _Page({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
}
