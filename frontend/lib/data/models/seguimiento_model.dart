/**
 * Modelo de datos para los Seguimientos semanales.
 * Sincronizado con SeguimientoResponse.java del backend.
 */
class Seguimiento {
  final int id;
  final int practicaId;
  final DateTime fechaRegistro;
  final int horasRealizadas;
  final String? descripcion;
  final String estado;
  final int? validadoPorId;
  final String? validadoPorNombre;
  final String? comentarioTutor;
  final DateTime fechaCreacion;

  Seguimiento({
    required this.id,
    required this.practicaId,
    required this.fechaRegistro,
    required this.horasRealizadas,
    this.descripcion,
    required this.estado,
    this.validadoPorId,
    this.validadoPorNombre,
    this.comentarioTutor,
    required this.fechaCreacion,
  });

  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      id: json['id'],
      practicaId: json['practicaId'],
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      horasRealizadas: json['horasRealizadas'],
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'PENDIENTE_EMPRESA',
      validadoPorId: json['validadoPorId'],
      validadoPorNombre: json['validadoPorNombre'],
      comentarioTutor: json['comentarioTutor'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
    );
  }

  /// Devuelve true si las horas de este parte cuentan para el progreso.
  bool get cuentaParaProgreso => estado == 'COMPLETADO';
}
