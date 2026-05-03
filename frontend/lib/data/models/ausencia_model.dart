class Ausencia {
  final int id;
  final int practicaId;
  final DateTime fecha;
  final String motivo;
  final String tipo;
  final bool tieneJustificante;
  final String? nombreFichero;
  final int registradaPorId;
  final String registradaPorNombre;
  final int? revisadaPorId;
  final String? revisadaPorNombre;
  final String? comentarioRevision;
  final DateTime fechaCreacion;

  const Ausencia({
    required this.id,
    required this.practicaId,
    required this.fecha,
    required this.motivo,
    required this.tipo,
    required this.tieneJustificante,
    this.nombreFichero,
    required this.registradaPorId,
    required this.registradaPorNombre,
    this.revisadaPorId,
    this.revisadaPorNombre,
    this.comentarioRevision,
    required this.fechaCreacion,
  });

  factory Ausencia.fromJson(Map<String, dynamic> json) {
    return Ausencia(
      id: json['id'],
      practicaId: json['practicaId'],
      fecha: DateTime.parse(json['fecha']),
      motivo: json['motivo'] ?? '',
      tipo: json['tipo'] ?? 'PENDIENTE',
      tieneJustificante: json['tieneJustificante'] ?? false,
      nombreFichero: json['nombreFichero'],
      registradaPorId: json['registradaPorId'],
      registradaPorNombre: json['registradaPorNombre'] ?? '',
      revisadaPorId: json['revisadaPorId'],
      revisadaPorNombre: json['revisadaPorNombre'],
      comentarioRevision: json['comentarioRevision'],
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
    );
  }

  bool get estaPendiente => tipo == 'PENDIENTE';
  bool get estaJustificada => tipo == 'JUSTIFICADA';
}
