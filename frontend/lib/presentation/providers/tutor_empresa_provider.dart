import 'package:flutter/material.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/models/evaluacion_final_model.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/services/ausencia_service.dart';
import '../../data/services/evaluacion_service.dart';
import '../../data/services/practica_tutor_service.dart';
import '../../data/services/seguimiento_service.dart';

class TutorEmpresaProvider extends ChangeNotifier {
  final PracticaTutorService _practicaService = PracticaTutorService();
  final SeguimientoService _seguimientoService = SeguimientoService();
  final AusenciaService _ausenciaService = AusenciaService();
  final EvaluacionService _evaluacionService = EvaluacionService();

  List<Practica> _practicas = [];
  Map<int, List<Seguimiento>> _todosSeguimientosPorPractica = {};
  Map<int, List<Ausencia>> _todasAusenciasPorPractica = {};
  Map<int, EvaluacionFinalModel?> _evaluacionPorPractica = {};
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

  double get totalHoras => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .fold(0.0, (sum, s) => sum + s.horasRealizadas);

  int get totalValidados => _todosSeguimientosPorPractica.values
      .expand((l) => l)
      .where((s) => s.estado == 'PENDIENTE_CENTRO' || s.estado == 'COMPLETADO')
      .length;

  // Solo prácticas ACTIVAS para los stats principales (evita sumar convenios finalizados)
  List<Practica> get _practicasActivas =>
      _practicas.where((p) => p.estado == 'ACTIVA').toList();

  // Horas aprobadas por la empresa en prácticas ACTIVAS
  double get totalHorasValidadasEmpresa => _practicasActivas.fold(0, (sum, p) {
        final segs = _todosSeguimientosPorPractica[p.id] ?? [];
        return sum +
            segs
                .where((s) => s.estado == 'PENDIENTE_CENTRO' || s.estado == 'COMPLETADO')
                .fold(0.0, (s2, seg) => s2 + seg.horasRealizadas);
      });

  // Horas totales comprometidas solo en convenios ACTIVOS
  int get totalHorasConvenio =>
      _practicasActivas.fold(0, (sum, p) => sum + (p.horasTotales ?? 0));

  // Horas que le quedan al alumno hasta completar el convenio activo
  double get totalHorasRestantes =>
      (totalHorasConvenio - totalHorasValidadasEmpresa).clamp(0.0, totalHorasConvenio.toDouble());

  // Seguimientos de una práctica concreta
  List<Seguimiento> seguimientosDe(int practicaId) =>
      _todosSeguimientosPorPractica[practicaId] ?? [];

  EvaluacionFinalModel? evaluacionDe(int practicaId) =>
      _evaluacionPorPractica[practicaId];

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _practicas = await _practicaService.getMisPracticasComoTutorEmpresa();
      _todosSeguimientosPorPractica = {};
      _todasAusenciasPorPractica = {};
      _evaluacionPorPractica = {};

      for (final practica in _practicas) {
        final results = await Future.wait([
          _seguimientoService.getSeguimientosPorPractica(practica.id),
          _ausenciaService.getAusenciasPorPractica(practica.id),
          _evaluacionService.getEvaluacion(practica.id),
        ]);
        _todosSeguimientosPorPractica[practica.id] = results[0] as List<Seguimiento>;
        _todasAusenciasPorPractica[practica.id] = results[1] as List<Ausencia>;
        _evaluacionPorPractica[practica.id] = results[2] as EvaluacionFinalModel?;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> evaluar(int practicaId, {
    double? actitudPuntualidad,
    double? competenciaTecnica,
    double? iniciativaAutonomia,
    double? trabajoEquipo,
    double? cumplimientoTareas,
    required double notaGlobal,
    String? comentario,
  }) async {
    try {
      final ev = await _evaluacionService.evaluar(
        practicaId,
        actitudPuntualidad: actitudPuntualidad,
        competenciaTecnica: competenciaTecnica,
        iniciativaAutonomia: iniciativaAutonomia,
        trabajoEquipo: trabajoEquipo,
        cumplimientoTareas: cumplimientoTareas,
        notaGlobal: notaGlobal,
        comentario: comentario,
      );
      _evaluacionPorPractica[practicaId] = ev;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
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
