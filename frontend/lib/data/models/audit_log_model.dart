class AuditLogModel {
  final int id;
  final DateTime fecha;
  final String? usuarioEmail;
  final String modulo;
  final String accion;
  final int? entidadId;
  final String? descripcion;

  AuditLogModel({
    required this.id,
    required this.fecha,
    this.usuarioEmail,
    required this.modulo,
    required this.accion,
    this.entidadId,
    this.descripcion,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      usuarioEmail: json['usuarioEmail'] as String?,
      modulo: json['modulo'] as String,
      accion: json['accion'] as String,
      entidadId: json['entidadId'] as int?,
      descripcion: json['descripcion'] as String?,
    );
  }
}
