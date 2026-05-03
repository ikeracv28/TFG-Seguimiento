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
        // flutter_secure_storage en web puede lanzar si los datos cifrados están corruptos
        // (p.ej., tras cambiar la clave AES o reconstruir la app). Si falla, limpiamos el storage
        // y tratamos al usuario como no autenticado — verá la pantalla de login.
        String? token;
        try {
          token = await _storage.read(key: 'jwt_token');
        } catch (_) {
          try {
            await _storage.deleteAll();
          } catch (_) {}
        }
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
