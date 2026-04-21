import 'package:flutter/material.dart';
import '../../data/models/practica_model.dart';
import '../../data/models/seguimiento_model.dart';
import '../../data/models/incidencia_model.dart';
import '../../data/services/practica_service.dart';
import '../../data/services/seguimiento_service.dart';
import '../../data/services/incidencia_service.dart';

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

  Practica? _practicaActiva;
  List<Seguimiento> _seguimientos = [];
  List<Incidencia> _incidencias = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters de estado
  Practica? get practicaActiva => _practicaActiva;
  List<Seguimiento> get seguimientos => _seguimientos;
  List<Incidencia> get incidencias => _incidencias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

        // 2 y 3. Seguimientos e incidencias en paralelo para menor latencia
        final results = await Future.wait([
          _seguimientoService.getSeguimientosPorPractica(practicaId),
          _incidenciaService.getIncidenciasPorPractica(practicaId),
        ]);

        _seguimientos = results[0] as List<Seguimiento>;
        _incidencias = results[1] as List<Incidencia>;
      } else {
        _seguimientos = [];
        _incidencias = [];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /**
   * Añade un seguimiento recién registrado a la lista local
   * sin necesidad de recargar todo desde la red.
   */
  void agregarSeguimiento(Seguimiento nuevo) {
    _seguimientos = [nuevo, ..._seguimientos];
    notifyListeners();
  }
}
