import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/incidencia_model.dart';

/**
 * Servicio para comunicarse con los endpoints de Incidencias.
 */
class IncidenciaService {
  final ApiClient _apiClient = ApiClient();

  /**
   * Lista las incidencias de una práctica concreta.
   * Endpoint: GET /api/v1/incidencias/practica/{practicaId}
   */
  Future<List<Incidencia>> getIncidenciasPorPractica(int practicaId) async {
    try {
      final response = await _apiClient.dio.get('/incidencias/practica/$practicaId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Incidencia.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error al obtener incidencias: ${e.message}');
    }
  }

  Future<Incidencia> reportar({required String tipo, required String descripcion}) async {
    try {
      final response = await _apiClient.dio.post('/incidencias', data: {
        'tipo': tipo,
        'descripcion': descripcion,
      });
      return Incidencia.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al reportar incidencia: ${e.message}');
    }
  }

  /// Actualiza el estado de una incidencia (TUTOR_CENTRO).
  /// Transiciones válidas: ABIERTA → EN_PROCESO → RESUELTA → CERRADA.
  Future<Incidencia> actualizarEstado(int id, String nuevoEstado) async {
    try {
      final response = await _apiClient.dio.patch(
        '/incidencias/$id/estado',
        queryParameters: {'nuevoEstado': nuevoEstado},
      );
      return Incidencia.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al actualizar estado: ${e.message}');
    }
  }
}
