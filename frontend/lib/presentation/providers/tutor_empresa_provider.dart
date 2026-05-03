import 'package:flutter/material.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/ausencia_service.dart';
import '../../data/services/practica_tutor_service.dart';
import '../../data/services/seguimiento_service.dart';

class TutorEmpresaProvider extends ChangeNotifier {
  final PracticaTutorService _practicaService = PracticaTutorService();
  final SeguimientoService _seguimientoService = SeguimientoService();
  final AusenciaService _ausenciaService = AusenciaService();

  List<Practica> _practicas = [];
  Map<int, List<Seguimiento>> _todosSeguimientosPorPractica = {};
  Map<int, List<Ausencia>> _todasAusenciasPorPractica = {};
  bool _isLoading = false;
  String? _error;

  List<Practica> get practicas => _practicas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Seguimiento> get todosPendientes => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .where((s) => s.estado == 'PENDIENTE_EMPRESA')
      .toList();

  List<Ausencia> get ausenciasPendientes => _todasAusenciasPorPractica.values
      .expand((l) => l)
      .where((a) => a.estaPendiente)
      .toList();

  int get totalPartes => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .length;

  int get totalHoras => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .fold(0, (sum, s) => sum + s.horasRealizadas);

  int get totalValidados => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .where((s) => s.estado == 'PENDIENTE_CENTRO' || s.estado == 'COMPLETADO')
      .length;

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _practicas = await _practicaService.getMisPracticasComoTutorEmpresa();
      _todosSeguimientosPorPractica = {};
      _todasAusenciasPorPractica = {};

      for (final practica in _practicas) {
        final results = await Future.wait([
          _seguimientoService.getSeguimientosPorPractica(practica.id),
          _ausenciaService.getAusenciasPorPractica(practica.id),
        ]);
        _todosSeguimientosPorPractica[practica.id] = results[0] as List<Seguimiento>;
        _todasAusenciasPorPractica[practica.id] = results[1] as List<Ausencia>;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validar(int seguimientoId) async {
    try {
      await _seguimientoService.validarEmpresa(seguimientoId, 'PENDIENTE_CENTRO');
      await cargar();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rechazar(int seguimientoId, String motivo) async {
    try {
      await _seguimientoService.validarEmpresa(
        seguimientoId,
        'RECHAZADO',
        motivo: motivo,
      );
      await cargar();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> justificarAusencia(int ausenciaId, String nuevoTipo, {String? comentario}) async {
    try {
      await _ausenciaService.revisar(
        id: ausenciaId,
        nuevoTipo: nuevoTipo,
        comentario: comentario,
      );
      await cargar();
      return true;
    } catch (_) {
      return false;
    }
  }

  Practica? practicaDe(int practicaId) {
    try {
      return _practicas.firstWhere((p) => p.id == practicaId);
    } catch (_) {
      return null;
    }
  }
}
