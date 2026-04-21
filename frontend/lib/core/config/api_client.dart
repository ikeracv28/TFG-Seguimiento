import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 * Cliente de red centralizado para Nexus-TFG.
 * Gestiona la URL base, timeouts e interceptores para seguridad.
 */
class ApiClient {
  static const String _baseUrl = 'http://localhost:8080/api/v1'; // Cambiar según entorno
  final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    contentType: 'application/json',
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Recuperamos el token de almacenamiento seguro
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Aquí podríamos gestionar renovaciones de token o errores 401 globales
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
