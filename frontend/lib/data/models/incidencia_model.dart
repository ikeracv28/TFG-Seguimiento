/**
 * Modelo de datos para las Incidencias durante las prácticas.
 * Sincronizado con IncidenciaResponse.java del backend.
 */
class Incidencia {
  final int id;
  final int practicaId;
  final int creadaPorId;
  final String creadaPorNombre;
  final String? tipo;
  final String descripcion;
  final String estado;
  final DateTime fechaCreacion;
  final String? resueltaPorNombre;
  final DateTime? fechaResolucion;

  Incidencia({
    required this.id,
    required this.practicaId,
    required this.creadaPorId,
    required this.creadaPorNombre,
    this.tipo,
    required this.descripcion,
    required this.estado,
    required this.fechaCreacion,
    this.resueltaPorNombre,
    this.fechaResolucion,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id'],
      practicaId: json['practicaId'],
      creadaPorId: json['creadaPorId'],
      creadaPorNombre: json['creadaPorNombre'] ?? '',
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'ABIERTA',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      resueltaPorNombre: json['resueltaPorNombre'],
      fechaResolucion: json['fechaResolucion'] != null
          ? DateTime.parse(json['fechaResolucion'])
          : null,
    );
  }

  /// Devuelve true si la incidencia sigue sin resolver.
  bool get estaAbierta => estado == 'ABIERTA' || estado == 'EN_PROCESO';
}
