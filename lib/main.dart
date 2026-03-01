import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/login/login_page.dart';
import 'presentation/products/products_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
  }
  runApp(const WmtechAdminApp());
}

class WmtechAdminApp extends StatelessWidget {
  const WmtechAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'wmtech Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Verifica se há token; mostra login ou lista de produtos.
/// Não chama API na UI; usa apenas o repositório.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authRepository = AuthRepositoryImpl();
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authRepository.isLoggedIn();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _loggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? ProductsListPage() : LoginPage();
  }
}
