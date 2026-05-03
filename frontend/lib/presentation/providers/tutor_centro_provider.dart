import 'package:flutter/material.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/ausencia_service.dart';
import '../../data/services/incidencia_service.dart';
import '../../data/services/practica_tutor_service.dart';
import '../../data/services/seguimiento_service.dart';

class TutorCentroProvider extends ChangeNotifier {
  final PracticaTutorService _practicaService = PracticaTutorService();
  final SeguimientoService _seguimientoService = SeguimientoService();
  final IncidenciaService _incidenciaService = IncidenciaService();
  final AusenciaService _ausenciaService = AusenciaService();

  List<Practica> _practicas = [];
  Map<int, List<Seguimiento>> _seguimientosPorPractica = {};
  Map<int, List<Incidencia>> _incidenciasPorPractica = {};
  Map<int, List<Ausencia>> _ausenciasPorPractica = {};
  int? _selectedPracticaId;
  bool _isLoading = false;
  String? _error;

  List<Practica> get practicas => _practicas;
  int? get selectedPracticaId => _selectedPracticaId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Practica? get selectedPractica {
    if (_selectedPracticaId == null) return null;
    try {
      return _practicas.firstWhere((p) => p.id == _selectedPracticaId);
    } catch (_) {
      return null;
    }
  }

  List<Seguimiento> get todosPendientesCentro => _seguimientosPorPractica.values
      .expand((l) => l)
      .where((s) => s.estado == 'PENDIENTE_CENTRO')
      .toList();

  List<Incidencia> get todasIncidencias =>
      _incidenciasPorPractica.values.expand((l) => l).toList();

  List<Seguimiento> seguimientosDe(int practicaId) =>
      _seguimientosPorPractica[practicaId] ?? [];

  List<Seguimiento> pendientesCentroDe(int practicaId) =>
      seguimientosDe(practicaId)
          .where((s) => s.estado == 'PENDIENTE_CENTRO')
          .toList();

  List<Incidencia> incidenciasDe(int practicaId) =>
      _incidenciasPorPractica[practicaId] ?? [];

  List<Ausencia> ausenciasInjustificadasDe(int practicaId) =>
      (_ausenciasPorPractica[practicaId] ?? [])
          .where((a) => a.tipo == 'INJUSTIFICADA')
          .toList();

  int horasCompletadasDe(int practicaId) => seguimientosDe(practicaId)
      .where((s) => s.estado == 'COMPLETADO')
      .fold(0, (sum, s) => sum + s.horasRealizadas);

  void seleccionar(int practicaId) {
    _selectedPracticaId = practicaId;
    notifyListeners();
  }

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _practicas = await _practicaService.getMisPracticasComoTutorCentro();
      _seguimientosPorPractica = {};
      _incidenciasPorPractica = {};
      _ausenciasPorPractica = {};

      for (final practica in _practicas) {
        final results = await Future.wait([
          _seguimientoService.getSeguimientosPorPractica(practica.id),
          _incidenciaService.getIncidenciasPorPractica(practica.id),
          _ausenciaService.getAusenciasPorPractica(practica.id),
        ]);
        _seguimientosPorPractica[practica.id] = results[0] as List<Seguimiento>;
        _incidenciasPorPractica[practica.id] = results[1] as List<Incidencia>;
        _ausenciasPorPractica[practica.id] = results[2] as List<Ausencia>;
      }

      if (_selectedPracticaId == null && _practicas.isNotEmpty) {
        _selectedPracticaId = _practicas.first.id;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> validarCentro(int seguimientoId) async {
    try {
      await _seguimientoService.validarCentro(seguimientoId);
      await cargar();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> actualizarEstadoIncidencia(
      int incidenciaId, String nuevoEstado) async {
    try {
      await _incidenciaService.actualizarEstado(incidenciaId, nuevoEstado);
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
