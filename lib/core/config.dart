import 'dart:io' show Platform;

/// Configuração da aplicação (URL da API).
/// Em produção, use environment variables ou flavors.
///
/// No mobile, localhost aponta para o dispositivo, não para o PC.
/// - Emulador Android: 10.0.2.2 = host do PC
/// - Simulador iOS: localhost funciona (roda no Mac)
/// - Dispositivo físico: use o IP do PC na rede (ex: 192.168.1.100)
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3005
class AppConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;
    // Emulador Android: 10.0.2.2 é o alias para localhost do host
    if (Platform.isAndroid) return 'http://10.0.2.2:3005';
    return 'http://localhost:3005';
  }
}
