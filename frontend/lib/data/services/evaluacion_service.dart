import '../models/evaluacion_final_model.dart';
import '../../core/config/api_client.dart';

class EvaluacionService {
  final _client = ApiClient();

  Future<EvaluacionFinalModel?> getEvaluacion(int practicaId) async {
    final response =
        await _client.dio.get('/evaluaciones/practica/$practicaId');
    if (response.statusCode == 204 || response.data == null) return null;
    return EvaluacionFinalModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<EvaluacionFinalModel> evaluar(int practicaId, {
    double? actitudPuntualidad,
    double? competenciaTecnica,
    double? iniciativaAutonomia,
    double? trabajoEquipo,
    double? cumplimientoTareas,
    required double notaGlobal,
    String? comentario,
  }) async {
    final response = await _client.dio.post(
      '/evaluaciones/practica/$practicaId',
      data: {
        if (actitudPuntualidad != null) 'actitudPuntualidad': actitudPuntualidad,
        if (competenciaTecnica != null) 'competenciaTecnica': competenciaTecnica,
        if (iniciativaAutonomia != null) 'iniciativaAutonomia': iniciativaAutonomia,
        if (trabajoEquipo != null) 'trabajoEquipo': trabajoEquipo,
        if (cumplimientoTareas != null) 'cumplimientoTareas': cumplimientoTareas,
        'notaGlobal': notaGlobal,
        if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
      },
    );
    return EvaluacionFinalModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}
