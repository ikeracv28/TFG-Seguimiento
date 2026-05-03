import 'package:flutter/material.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/models/ausencia_model.dart';
import '../../data/services/practica_service.dart';
import '../../data/services/seguimiento_service.dart';
import '../../data/services/incidencia_service.dart';
import '../../data/services/ausencia_service.dart';

/**
 * Gestor de estado central para el dashboard del alumno.
 *
 * Coordina tres llamadas independientes al backend:
 *   1. GET /practicas/me          → práctica activa del alumno
 *   2. GET /seguimientos/practica/{id} → partes semanales
 *   3. GET /incidencias/practica/{id}  → incidencias abiertas
 *
 * El dashboard no necesita conocer el ID del alumno — el JWT lo identifica.
 */
class PracticaProvider extends ChangeNotifier {
  final PracticaService _practicaService = PracticaService();
  final SeguimientoService _seguimientoService = SeguimientoService();
  final IncidenciaService _incidenciaService = IncidenciaService();
  final AusenciaService _ausenciaService = AusenciaService();

  Practica? _practicaActiva;
  List<Seguimiento> _seguimientos = [];
  List<Incidencia> _incidencias = [];
  List<Ausencia> _ausencias = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters de estado
  Practica? get practicaActiva => _practicaActiva;
  List<Seguimiento> get seguimientos => _seguimientos;
  List<Incidencia> get incidencias => _incidencias;
  List<Ausencia> get ausencias => _ausencias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get ausenciasPendientes => _ausencias.where((a) => a.estaPendiente).length;

  /// Horas contabilizadas: solo las de seguimientos con estado COMPLETADO.
  int get horasCompletadas =>
      _seguimientos.where((s) => s.cuentaParaProgreso).fold(0, (sum, s) => sum + s.horasRealizadas);

  /// Número de incidencias que siguen abiertas o en proceso.
  int get incidenciasAbiertas => _incidencias.where((i) => i.estaAbierta).length;

  /**
   * Carga la práctica activa del alumno autenticado y, si existe,
   * carga también sus seguimientos e incidencias en paralelo.
   */
  Future<void> cargarDashboard() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Práctica activa (el endpoint /me la obtiene por JWT)
      _practicaActiva = await _practicaService.getPracticaActiva();

      if (_practicaActiva != null) {
        final practicaId = _practicaActiva!.id;

        // 2, 3 y 4. Seguimientos, incidencias y ausencias en paralelo
        final results = await Future.wait([
          _seguimientoService.getSeguimientosPorPractica(practicaId),
          _incidenciaService.getIncidenciasPorPractica(practicaId),
          _ausenciaService.getAusenciasPorPractica(practicaId),
        ]);

        _seguimientos = results[0] as List<Seguimiento>;
        _incidencias = results[1] as List<Incidencia>;
        _ausencias = results[2] as List<Ausencia>;
      } else {
        _seguimientos = [];
        _incidencias = [];
        _ausencias = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void agregarSeguimiento(Seguimiento nuevo) {
    _seguimientos = [nuevo, ..._seguimientos];
    notifyListeners();
  }

  void agregarAusencia(Ausencia nueva) {
    _ausencias = [nueva, ..._ausencias];
    notifyListeners();
  }

  void eliminarAusencia(int id) {
    _ausencias = _ausencias.where((a) => a.id != id).toList();
    notifyListeners();
  }

  void actualizarAusencia(Ausencia actualizada) {
    _ausencias = _ausencias.map((a) => a.id == actualizada.id ? actualizada : a).toList();
    notifyListeners();
  }
}
