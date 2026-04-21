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
      // Manejo de error más robusto
      String errorMessage = 'Error al iniciar sesión';
      
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'];
        } else if (data is String && data.isNotEmpty) {
          errorMessage = data;
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'El servidor tarda demasiado en responder';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'No se puede conectar con el servidor (¿está encendido?)';
      }
      
      throw Exception(errorMessage);
    }
  }

  /**
   * Cierra la sesión eliminando el token.
   */
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  /**
   * Verifica si el usuario tiene una sesión activa.
   */
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
