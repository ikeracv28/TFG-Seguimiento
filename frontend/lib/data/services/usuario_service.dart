import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/auth_models.dart';

class UsuarioService {
  final ApiClient _apiClient = ApiClient();

  Future<User> getMe() async {
    try {
      final response = await _apiClient.dio.get('/usuarios/me');
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null)
          ?? 'Error al obtener perfil';
      throw Exception(msg);
    }
  }

  Future<void> uploadFoto({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });
      await _apiClient.dio.post('/usuarios/me/foto', data: formData);
    } on DioException catch (e) {
      final msg = (e.response?.data is Map ? e.response?.data['message'] : null)
          ?? 'Error al subir la foto';
      throw Exception(msg);
    }
  }

  Future<Uint8List> downloadFoto(int usuarioId) async {
    try {
      final response = await _apiClient.dio.get<List<int>>(
        '/usuarios/$usuarioId/foto',
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw Exception('Error al descargar foto: ${e.message}');
    }
  }
}
