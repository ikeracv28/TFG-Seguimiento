import 'package:flutter/material.dart';
import '../../core/config/api_client.dart';
import '../../data/models/tutoria_model.dart';
import '../../data/services/tutoria_service.dart';

class TutoriaProvider extends ChangeNotifier {
  final TutoriaService _service = TutoriaService(ApiClient());

  List<TutoriaModel> _sesiones = [];
  TutoriaModel? _proximaTutoria;
  bool _cargando = false;
  String? _error;

  List<TutoriaModel> get sesiones => _sesiones;
  TutoriaModel? get proximaTutoria => _proximaTutoria;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarSesiones() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _sesiones = await _service.getMisSesiones();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cargarProximaTutoria() async {
    try {
      _proximaTutoria = await _service.getProximaTutoria();
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> planificar({
    required String fecha,
    required String horaInicio,
    required int duracionMinutos,
    List<int>? ordenAlumnosIds,
  }) async {
    try {
      _sesiones = await _service.planificar(
        fecha: fecha,
        horaInicio: horaInicio,
        duracionMinutos: duracionMinutos,
        ordenAlumnosIds: ordenAlumnosIds,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<int> enviarNotificaciones(String fecha) async {
    try {
      final n = await _service.enviarNotificaciones(fecha);
      await cargarSesiones();
      return n;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> eliminarSesion(String fecha) async {
    try {
      await _service.eliminarSesion(fecha);
      _sesiones = _sesiones.where((t) {
        final f = t.fechaHora;
        final d = '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
        return d != fecha;
      }).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
