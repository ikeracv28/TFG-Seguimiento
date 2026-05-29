/**
 * Modelo de datos para los Seguimientos semanales.
 * Sincronizado con SeguimientoResponse.java del backend.
 */
class Seguimiento {
  final int id;
  final int practicaId;
  final DateTime fechaRegistro;
  final double horasRealizadas;
  final String? descripcion;
  final String estado;
  final String tipo;
  final int? validadoPorId;
  final String? validadoPorNombre;
  final String? comentarioTutor;
  final DateTime fechaCreacion;
  // Firma electrónica
  final String? firmaAlumnoImagen;
  final String? firmaAlumnoNombre;
  final DateTime? firmaAlumnoFecha;
  final String? firmaTutorEmpresaImagen;
  final String? firmaTutorEmpresaNombre;
  final DateTime? firmaTutorEmpresaFecha;

  Seguimiento({
    required this.id,
    required this.practicaId,
    required this.fechaRegistro,
    required this.horasRealizadas,
    this.descripcion,
    required this.estado,
    this.tipo = 'DIARIO',
    this.validadoPorId,
    this.validadoPorNombre,
    this.comentarioTutor,
    required this.fechaCreacion,
    this.firmaAlumnoImagen,
    this.firmaAlumnoNombre,
    this.firmaAlumnoFecha,
    this.firmaTutorEmpresaImagen,
    this.firmaTutorEmpresaNombre,
    this.firmaTutorEmpresaFecha,
  });

  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      id: json['id'],
      practicaId: json['practicaId'],
      fechaRegistro: DateTime.parse(json['fechaRegistro']),
      horasRealizadas: (json['horasRealizadas'] as num).toDouble(),
      descripcion: json['descripcion'],
      estado: json['estado'] ?? 'PENDIENTE_EMPRESA',
      tipo: json['tipo'] ?? 'DIARIO',
      validadoPorId: json['validadoPorId'],
      validadoPorNombre: json['validadoPorNombre'],
      comentarioTutor: json['comentarioTutor'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
      firmaAlumnoImagen: json['firmaAlumnoImagen'],
      firmaAlumnoNombre: json['firmaAlumnoNombre'],
      firmaAlumnoFecha: json['firmaAlumnoFecha'] != null
          ? DateTime.parse(json['firmaAlumnoFecha']) : null,
      firmaTutorEmpresaImagen: json['firmaTutorEmpresaImagen'],
      firmaTutorEmpresaNombre: json['firmaTutorEmpresaNombre'],
      firmaTutorEmpresaFecha: json['firmaTutorEmpresaFecha'] != null
          ? DateTime.parse(json['firmaTutorEmpresaFecha']) : null,
    );
  }

  bool get esSemanal => tipo == 'SEMANAL';
  bool get cuentaParaProgreso => estado == 'COMPLETADO';
  bool get firmadoPorAlumno => firmaAlumnoImagen != null;
  bool get firmadoPorTutorEmpresa => firmaTutorEmpresaImagen != null;
}
