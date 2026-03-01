import 'dart:io' show Platform;

import 'package:wmtech_admin/core/app_env.dart';

/// Configuração da aplicação (URL da API e Supabase).

///
/// Supabase (Storage de imagens):
///   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
class AppConfig {
  static String get baseUrl {
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (Platform.isAndroid) return 'http://10.0.2.2:3005';
    return 'http://localhost:3005';
  }

  static String get supabaseUrl {
    return AppEnv.config.supabaseUrl;
  }

  static String get supabaseAnonKey {
    return AppEnv.config.supabaseAnonKey;
  }

  static bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
