import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/practica_model.dart';

class PracticaTutorService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Practica>> getMisPracticasComoTutorEmpresa() async {
    try {
      final response = await _apiClient.dio.get('/practicas/tutor-empresa/me');
      final List<dynamic> data = response.data;
      return data.map((json) => Practica.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener prácticas: ${e.message}');
    }
  }

  Future<List<Practica>> getMisPracticasComoTutorCentro() async {
    try {
      final response = await _apiClient.dio.get('/practicas/tutor-centro/me');
      final List<dynamic> data = response.data;
      return data.map((json) => Practica.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Error al obtener prácticas: ${e.message}');
    }
  }
}
