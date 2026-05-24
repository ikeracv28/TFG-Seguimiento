import 'package:dio/dio.dart';
import '../../core/config/api_client.dart';
import '../models/notificacion_model.dart';

class NotificacionService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificacionItem>> listar() async {
    final response = await _apiClient.dio.get('/notificaciones/me');
    final List<dynamic> data = response.data;
    return data.map((j) => NotificacionItem.fromJson(j)).toList();
  }

  Future<int> contarNoLeidas() async {
    final response = await _apiClient.dio.get('/notificaciones/me/no-leidas');
    return (response.data['count'] as num).toInt();
  }

  Future<void> marcarLeida(int id) async {
    await _apiClient.dio.patch('/notificaciones/$id/leer');
  }

  Future<void> marcarTodasLeidas() async {
    await _apiClient.dio.patch('/notificaciones/me/leer-todas');
  }
}
