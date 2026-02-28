import 'package:dio/dio.dart';

import 'config.dart';
import 'auth_storage.dart';

/// Cliente HTTP para o backend (Dio). Não expõe detalhes de implementação às camadas superiores.
class ApiClient {
  ApiClient({AuthStorage? authStorage})
      : _authStorage = authStorage ?? AuthStorage(),
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  final AuthStorage _authStorage;
  final Dio _dio;

  Future<T> get<T>(String path, T Function(dynamic) fromJson) async {
    try {
      final response = await _dio.get(path);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? 0,
        e.response?.data?.toString() ?? e.message ?? '',
      );
    }
  }

  Future<T> post<T>(String path, Map<String, dynamic> body,
      T Function(dynamic) fromJson, {bool withAuth = true}) async {
    try {
      final response = await _dio.post(path, data: body);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? 0,
        e.response?.data?.toString() ?? e.message ?? '',
      );
    }
  }

  Future<T> patch<T>(String path, Map<String, dynamic> body,
      T Function(dynamic) fromJson) async {
    try {
      final response = await _dio.patch(path, data: body);
      return fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? 0,
        e.response?.data?.toString() ?? e.message ?? '',
      );
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.statusCode ?? 0,
        e.response?.data?.toString() ?? e.message ?? '',
      );
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}
