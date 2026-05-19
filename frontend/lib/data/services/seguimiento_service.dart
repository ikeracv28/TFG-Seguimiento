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

  Future<Seguimiento> registrar({
    required int practicaId,
    required DateTime fechaRegistro,
    required double horasRealizadas,
    required String descripcion,
    String tipo = 'DIARIO',
  }) async {
    try {
      final body = {
        'practicaId': practicaId,
        'fechaRegistro': fechaRegistro.toIso8601String().split('T')[0],
        'horasRealizadas': horasRealizadas,
        'descripcion': descripcion,
        'tipo': tipo,
      };
      final response = await _apiClient.dio.post('/seguimientos', data: body);
      return Seguimiento.fromJson(response.data);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message'] ?? e.response?.data['error'] ?? 'Error al registrar el parte')
          : 'Error al registrar el parte';
      throw Exception(msg);
    }
  }

  /// Primera validación por el tutor de empresa.
  /// [nuevoEstado] debe ser PENDIENTE_CENTRO o RECHAZADO.
  /// [motivo] es obligatorio si nuevoEstado == RECHAZADO.
  Future<Seguimiento> validarEmpresa(int id, String nuevoEstado, {String? motivo}) async {
    try {
      final params = <String, dynamic>{'nuevoEstado': nuevoEstado};
      if (motivo != null && motivo.isNotEmpty) params['motivo'] = motivo;
      final response = await _apiClient.dio.patch(
        '/seguimientos/$id/validar-empresa',
        queryParameters: params,
      );
      return Seguimiento.fromJson(response.data);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message'] ?? 'Error al validar parte')
          : 'Error al validar parte';
      throw Exception(msg);
    }
  }

  /// Segunda y definitiva validación por el tutor del centro.
  Future<Seguimiento> validarCentro(int id) async {
    try {
      final response = await _apiClient.dio.patch('/seguimientos/$id/validar-centro');
      return Seguimiento.fromJson(response.data);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? (e.response?.data['message'] ?? 'Error al completar parte')
          : 'Error al completar parte';
      throw Exception(msg);
    }
  }
}
