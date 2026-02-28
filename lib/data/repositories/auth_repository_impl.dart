import '../../core/api_client.dart';
import '../../core/auth_storage.dart';
import '../../domain/repositories/auth_repository.dart';

/// Implementação do repositório de autenticação.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    ApiClient? apiClient,
    AuthStorage? authStorage,
  })  : _api = apiClient ?? ApiClient(authStorage: authStorage),
        _storage = authStorage ?? AuthStorage();

  final ApiClient _api;
  final AuthStorage _storage;

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final body = {'email': email, 'password': password};
      final decoded = await _api.post<Map<String, dynamic>>(
        '/auth/login',
        body,
        (v) => v as Map<String, dynamic>,
        withAuth: false,
      );
      final token = decoded['access_token'] as String?;
      final user = decoded['user'];
      final userEmail = user is Map ? user['email'] as String? : null;
      if (token == null || token.isEmpty) {
        return const AuthResult.failure('Resposta inválida');
      }
      await _storage.saveToken(token);
      return AuthResult.success(
        token: token,
        userEmail: userEmail ?? email,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        return const AuthResult.failure('Email ou senha inválidos');
      }
      return AuthResult.failure(e.body.isNotEmpty ? e.body : 'Erro ao fazer login');
    }
  }

  @override
  Future<void> logout() async {
    await _storage.clearToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null && token.isNotEmpty;
  }
}
