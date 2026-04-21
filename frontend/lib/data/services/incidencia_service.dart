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

  /**
   * Reporta una nueva incidencia en la práctica activa del usuario autenticado.
   * Endpoint: POST /api/v1/incidencias
   */
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
}
