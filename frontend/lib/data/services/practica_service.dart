import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/practica_model.dart';

/**
 * Servicio encargado de la comunicación con los endpoints de Prácticas.
 */
class PracticaService {
  final ApiClient _apiClient = ApiClient();

  /**
   * Devuelve la práctica ACTIVA del alumno autenticado.
   * El JWT incluido automáticamente en la cabecera identifica al usuario.
   * Endpoint: GET /api/v1/practicas/me
   */
  Future<Practica?> getPracticaActiva() async {
    try {
      final response = await _apiClient.dio.get('/practicas/me');
      if (response.statusCode == 200) {
        return Practica.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      // 404 significa que el alumno no tiene práctica activa aún — no es un error crítico
      if (e.response?.statusCode == 404) return null;
      throw Exception('Error al obtener la práctica activa: ${e.message}');
    }
  }

  /**
   * Obtiene las prácticas asociadas a un alumno específico.
   * Reservado para roles de TUTOR y ADMIN.
   * Endpoint: GET /api/v1/practicas/alumno/{alumnoId}
   */
  Future<List<Practica>> getPracticasPorAlumno(int alumnoId) async {
    try {
      final response = await _apiClient.dio.get('/practicas/alumno/$alumnoId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Practica.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error al obtener prácticas: ${e.message}');
    }
  }

  /**
   * Obtiene los detalles de una práctica por su ID.
   * Endpoint: GET /api/v1/practicas/{id}
   */
  Future<Practica> getPracticaPorId(int id) async {
    try {
      final response = await _apiClient.dio.get('/practicas/$id');
      if (response.statusCode == 200) {
        return Practica.fromJson(response.data);
      }
      throw Exception('Práctica no encontrada');
    } on DioException catch (e) {
      throw Exception('Error al obtener detalle de práctica: ${e.message}');
    }
  }
}
