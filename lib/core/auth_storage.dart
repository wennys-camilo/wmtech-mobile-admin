import 'package:shared_preferences/shared_preferences.dart';

/// Persistência do token de autenticação. Camada de infraestrutura.
class AuthStorage {
  static const _keyToken = 'wmtech_admin_token';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
  }
}
