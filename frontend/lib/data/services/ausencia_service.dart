import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/ausencia_model.dart';

class AusenciaService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Ausencia>> getAusenciasPorPractica(int practicaId) async {
    try {
      final response = await _apiClient.dio.get('/ausencias/practica/$practicaId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Ausencia.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Error al obtener ausencias: ${e.message}');
    }
  }

  Future<Ausencia> registrar({
    required int practicaId,
    required DateTime fecha,
    required String motivo,
  }) async {
    try {
      final response = await _apiClient.dio.post('/ausencias', data: {
        'practicaId': practicaId,
        'fecha': '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}',
        'motivo': motivo,
      });
      return Ausencia.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al registrar ausencia';
      throw Exception(msg);
    }
  }

  Future<Ausencia> adjuntarJustificante({
    required int id,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'fichero': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      final response = await _apiClient.dio.patch(
        '/ausencias/$id/justificante',
        data: formData,
      );
      return Ausencia.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al adjuntar justificante';
      throw Exception(msg);
    }
  }

  Future<({Uint8List bytes, String mimeType})> descargarJustificante(int id) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        '/ausencias/$id/justificante',
        options: Options(responseType: ResponseType.bytes),
      );
      final mime = (response.headers['content-type']?.first ?? 'application/octet-stream')
          .split(';')
          .first
          .trim();
      return (bytes: Uint8List.fromList(response.data!), mimeType: mime);
    } on DioException catch (e) {
      throw Exception('Error al descargar justificante: ${e.message}');
    }
  }

  Future<Ausencia> revisar({
    required int id,
    required String nuevoTipo,
    String? comentario,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/ausencias/$id/revisar',
        queryParameters: {
          'nuevoTipo': nuevoTipo,
          if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
        },
      );
      return Ausencia.fromJson(response.data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al revisar ausencia';
      throw Exception(msg);
    }
  }

  Future<void> eliminar(int id) async {
    try {
      await _apiClient.dio.delete('/ausencias/$id');
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Error al eliminar ausencia';
      throw Exception(msg);
    }
  }
}
