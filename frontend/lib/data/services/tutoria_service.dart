import '../models/tutoria_model.dart';
import 'api_client.dart';

class TutoriaService {
  final ApiClient _apiClient;
  TutoriaService(this._apiClient);

  Future<List<TutoriaModel>> planificar({
    required String fecha,
    required String horaInicio,
    required int duracionMinutos,
    List<int>? ordenAlumnosIds,
  }) async {
    final response = await _apiClient.dio.post('/tutorias/planificar', data: {
      'fecha': fecha,
      'horaInicio': horaInicio,
      'duracionMinutos': duracionMinutos,
      if (ordenAlumnosIds != null) 'ordenAlumnosIds': ordenAlumnosIds,
    });
    return (response.data as List)
        .map((e) => TutoriaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TutoriaModel>> getMisSesiones() async {
    final response = await _apiClient.dio.get('/tutorias/mis-sesiones');
    return (response.data as List)
        .map((e) => TutoriaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TutoriaModel?> getProximaTutoria() async {
    try {
      final response = await _apiClient.dio.get('/tutorias/mi-proxima');
      if (response.statusCode == 204 || response.data == null) return null;
      return TutoriaModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<int> enviarNotificaciones(String fecha) async {
    final response = await _apiClient.dio
        .post('/tutorias/notificar', queryParameters: {'fecha': fecha});
    return (response.data as Map<String, dynamic>)['enviados'] as int;
  }
}
