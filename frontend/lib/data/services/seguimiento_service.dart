import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/seguimiento_model.dart';

/**
 * Servicio para comunicarse con los endpoints de Seguimientos.
 */
class SeguimientoService {
  final ApiClient _apiClient = ApiClient();

  /**
   * Lista los seguimientos de una práctica concreta.
   * Endpoint: GET /api/v1/seguimientos/practica/{practicaId}
   */
  Future<List<Seguimiento>> getSeguimientosPorPractica(int practicaId) async {
    try {
      final response = await _apiClient.dio.get('/seguimientos/practica/$practicaId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Seguimiento.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error al obtener seguimientos: ${e.message}');
    }
  }

  /**
   * Registra un nuevo parte de seguimiento para el alumno autenticado.
   * Endpoint: POST /api/v1/seguimientos
   */
  Future<Seguimiento> registrar({
    required int practicaId,
    required DateTime fechaRegistro,
    required int horasRealizadas,
    String? descripcion,
  }) async {
    try {
      final body = {
        'practicaId': practicaId,
        'fechaRegistro': fechaRegistro.toIso8601String().split('T')[0],
        'horasRealizadas': horasRealizadas,
        if (descripcion != null && descripcion.isNotEmpty) 'descripcion': descripcion,
      };
      final response = await _apiClient.dio.post('/seguimientos', data: body);
      return Seguimiento.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Error al registrar seguimiento: ${e.message}');
    }
  }
}
