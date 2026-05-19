import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/config/api_client.dart';
import '../models/auth_models.dart';

/**
 * Servicio encargado de la comunicación con los endpoints de autenticación.
 */
class AuthService {
  final ApiClient _apiClient = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /**
   * Realiza el inicio de sesión contra el backend de Spring Boot.
   */
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final authResponse = AuthResponse.fromJson(response.data);
      
      // Guardamos el token de forma segura
      await _storage.write(key: 'jwt_token', value: authResponse.token);
      
      return authResponse;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null)
          ?? 'Error al iniciar sesión';
      throw Exception(message);
    }
  }

  /**
   * Cierra la sesión: revoca el token en el servidor (A07) y elimina el almacenamiento local.
   */
  Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await _apiClient.dio.post('/auth/logout');
      }
    } catch (_) {
      // Si el backend falla, continuamos con el logout local igualmente
    } finally {
      try { await _storage.deleteAll(); } catch (_) {}
    }
  }

  /**
   * Llama a GET /auth/me con el token almacenado.
   * Si el token sigue siendo válido, devuelve el usuario reconstruido.
   * Si recibe 401 o no hay token, limpia el storage y devuelve null.
   */
  Future<User?> recuperarSesion() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      // Pasamos el token directamente para no depender del interceptor en este caso crítico
      final response = await _apiClient.dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        try { await _storage.deleteAll(); } catch (_) {}
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
