import 'package:dio/dio.dart';
import '../models/usuario_model.dart';
import '../models/practica_model.dart';
import '../models/empresa_model.dart';
import '../models/audit_log_model.dart';
import '../../core/config/api_client.dart';

class AdminService {
  final ApiClient _apiClient = ApiClient();

  // ---- Usuarios ----

  Future<List<UsuarioModel>> listarUsuarios() async {
    final response = await _apiClient.dio.get('/admin/usuarios');
    return (response.data as List)
        .map((j) => UsuarioModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<UsuarioModel> crearUsuario({
    required String dni,
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    required String rolNombre,
  }) async {
    try {
      final response = await _apiClient.dio.post('/admin/usuarios', data: {
        'dni': dni,
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'password': password,
        'rolNombre': rolNombre,
      });
      return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null)
          ?? 'Error al crear el usuario';
      throw Exception(message);
    }
  }

  Future<UsuarioModel> toggleActivo(int id) async {
    final response = await _apiClient.dio.patch('/admin/usuarios/$id/toggle-activo');
    return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UsuarioModel> editarUsuario({
    required int id,
    required String dni,
    required String nombre,
    required String apellidos,
    required String email,
    required String rolNombre,
  }) async {
    try {
      final response = await _apiClient.dio.put('/admin/usuarios/$id', data: {
        'dni': dni,
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'rolNombre': rolNombre,
      });
      return UsuarioModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null)
          ?? 'Error al editar el usuario';
      throw Exception(message);
    }
  }

  // ---- Prácticas ----

  Future<List<Practica>> listarPracticas() async {
    final response = await _apiClient.dio.get('/practicas', queryParameters: {'size': 200});
    final content = response.data['content'] as List;
    return content.map((j) => Practica.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Practica> crearPractica({
    required String codigo,
    required int alumnoId,
    required int tutorCentroId,
    required int tutorEmpresaId,
    required int empresaId,
    required String fechaInicio,
    required String fechaFin,
    required int horasTotales,
  }) async {
    try {
      final response = await _apiClient.dio.post('/practicas', data: {
        'codigo': codigo,
        'alumnoId': alumnoId,
        'tutorCentroId': tutorCentroId,
        'tutorEmpresaId': tutorEmpresaId,
        'empresaId': empresaId,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'horasTotales': horasTotales,
        'estado': 'BORRADOR',
      });
      return Practica.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null)
          ?? 'Error al crear la práctica';
      throw Exception(message);
    }
  }

  Future<Practica> editarPractica({
    required int id,
    required String codigo,
    required int alumnoId,
    required int tutorCentroId,
    required int tutorEmpresaId,
    required int empresaId,
    required String fechaInicio,
    required String fechaFin,
    required int horasTotales,
    required String estado,
  }) async {
    try {
      final response = await _apiClient.dio.put('/practicas/$id', data: {
        'codigo': codigo,
        'alumnoId': alumnoId,
        'tutorCentroId': tutorCentroId,
        'tutorEmpresaId': tutorEmpresaId,
        'empresaId': empresaId,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'horasTotales': horasTotales,
        'estado': estado,
      });
      return Practica.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map ? data['message'] as String? : null)
          ?? 'Error al editar la práctica';
      throw Exception(message);
    }
  }

  // ---- Empresas ----

  Future<List<EmpresaModel>> listarEmpresas() async {
    final response = await _apiClient.dio.get('/empresas');
    return (response.data as List)
        .map((j) => EmpresaModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ---- Audit logs ----

  Future<List<AuditLogModel>> listarAuditLogs({String? modulo, int page = 0, int size = 50}) async {
    final params = <String, dynamic>{'page': page, 'size': size, 'sort': 'fecha,desc'};
    if (modulo != null) params['modulo'] = modulo;
    final response = await _apiClient.dio.get('/admin/audit-logs', queryParameters: params);
    final content = response.data['content'] as List;
    return content.map((j) => AuditLogModel.fromJson(j as Map<String, dynamic>)).toList();
  }
}
