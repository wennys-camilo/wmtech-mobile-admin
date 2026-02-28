/// Contrato do repositório de autenticação (camada de domínio).
abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<void> logout();
  Future<bool> isLoggedIn();
}

class AuthResult {
  const AuthResult.success({required this.token, required this.userEmail})
      : message = null;
  const AuthResult.failure(this.message)
      : token = null,
        userEmail = null;

  final String? token;
  final String? userEmail;
  final String? message;

  bool get isSuccess => token != null;
}
