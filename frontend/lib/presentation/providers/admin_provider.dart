import 'package:flutter/material.dart';
import '../../data/models/usuario_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/empresa_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/services/admin_service.dart';
import '../../data/services/incidencia_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminService _service = AdminService();
  final IncidenciaService _incidenciaService = IncidenciaService();

  List<UsuarioModel> _usuarios = [];
  List<Practica> _practicas = [];
  List<EmpresaModel> _empresas = [];
  List<Incidencia> _incidencias = [];
  List<AuditLogModel> _auditLogs = [];
  bool _cargandoAudit = false;

  bool _cargando = false;
  String? _error;

  List<UsuarioModel> get usuarios => _usuarios;
  List<Practica> get practicas => _practicas;
  List<EmpresaModel> get empresas => _empresas;
  List<Incidencia> get incidencias => _incidencias;
  List<AuditLogModel> get auditLogs => _auditLogs;
  bool get cargandoAudit => _cargandoAudit;
  bool get cargando => _cargando;
  String? get error => _error;

  int get totalPracticas => _practicas.length;
  int get practicasActivas => _practicas.where((p) => p.estado == 'ACTIVA').length;
  int get practicasBorrador => _practicas.where((p) => p.estado == 'BORRADOR').length;
  int get practicasFinalizadas => _practicas.where((p) => p.estado == 'FINALIZADA').length;
  int get incidenciasAbiertas => _incidencias.where((i) => i.estaAbierta).length;

  List<UsuarioModel> get alumnos =>
      _usuarios.where((u) => u.roles.contains('ROLE_ALUMNO')).toList();
  List<UsuarioModel> get tutoresCentro =>
      _usuarios.where((u) => u.roles.contains('ROLE_TUTOR_CENTRO')).toList();
  List<UsuarioModel> get tutoresEmpresa =>
      _usuarios.where((u) => u.roles.contains('ROLE_TUTOR_EMPRESA')).toList();

  Future<void> cargarTodo() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listarUsuarios(),
        _service.listarPracticas(),
        _service.listarEmpresas(),
      ]);
      _usuarios = results[0] as List<UsuarioModel>;
      _practicas = results[1] as List<Practica>;
      _empresas = results[2] as List<EmpresaModel>;

      // Cargar incidencias de todas las prácticas
      final incLists = await Future.wait(
        _practicas.map((p) => _incidenciaService
            .getIncidenciasPorPractica(p.id)
            .catchError((_) => <Incidencia>[])),
      );
      _incidencias = incLists.expand((l) => l).toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarUsuarios() async {
    try {
      _usuarios = await _service.listarUsuarios();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> crearUsuario({
    required String dni,
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
    required String rolNombre,
  }) async {
    try {
      final nuevo = await _service.crearUsuario(
        dni: dni, nombre: nombre, apellidos: apellidos,
        email: email, password: password, rolNombre: rolNombre,
      );
      _usuarios = [nuevo, ..._usuarios];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleActivo(int id) async {
    try {
      final actualizado = await _service.toggleActivo(id);
      _usuarios = _usuarios.map((u) => u.id == id ? actualizado : u).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> editarUsuario({
    required int id,
    required String dni,
    required String nombre,
    required String apellidos,
    required String email,
    required String rolNombre,
  }) async {
    try {
      final actualizado = await _service.editarUsuario(
        id: id, dni: dni, nombre: nombre,
        apellidos: apellidos, email: email, rolNombre: rolNombre,
      );
      _usuarios = _usuarios.map((u) => u.id == id ? actualizado : u).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> crearPractica({
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
      final nueva = await _service.crearPractica(
        codigo: codigo, alumnoId: alumnoId, tutorCentroId: tutorCentroId,
        tutorEmpresaId: tutorEmpresaId, empresaId: empresaId,
        fechaInicio: fechaInicio, fechaFin: fechaFin, horasTotales: horasTotales,
      );
      _practicas = [nueva, ..._practicas];
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> editarPractica({
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
      final actualizada = await _service.editarPractica(
        id: id, codigo: codigo, alumnoId: alumnoId,
        tutorCentroId: tutorCentroId, tutorEmpresaId: tutorEmpresaId,
        empresaId: empresaId, fechaInicio: fechaInicio, fechaFin: fechaFin,
        horasTotales: horasTotales, estado: estado,
      );
      _practicas = _practicas.map((p) => p.id == id ? actualizada : p).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarAuditLogs({String? modulo}) async {
    _cargandoAudit = true;
    notifyListeners();
    try {
      _auditLogs = await _service.listarAuditLogs(modulo: modulo);
    } catch (_) {
      _auditLogs = [];
    } finally {
      _cargandoAudit = false;
      notifyListeners();
    }
  }

  void limpiarError() {
    _error = null;
    notifyListeners();
  }
}
