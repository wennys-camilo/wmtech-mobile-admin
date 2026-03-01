class AppEnv {
  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;

  AppEnv({required this.apiBaseUrl, required this.supabaseUrl, required this.supabaseAnonKey});

  static AppEnv get config => AppEnv(
    apiBaseUrl: 'http://10.0.2.2:3005',
    supabaseUrl: 'https://mqstzlrkqeputtnzvxzt.supabase.co',
    supabaseAnonKey: 'sb_publishable_fRKe2Kq2SXsW8_W0KIOqZw_D56rx3Nt',
  );
}
