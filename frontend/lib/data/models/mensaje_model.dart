class MensajeModel {
  final int id;
  final int practicaId;
  final int remitenteId;
  final String remitenteNombre;
  final String remitenteApellidos;
  final String contenido;
  final DateTime fechaEnvio;
  final String canal;
  final String tipo;
  final String? adjuntoNombre;

  MensajeModel({
    required this.id,
    required this.practicaId,
    required this.remitenteId,
    required this.remitenteNombre,
    required this.remitenteApellidos,
    required this.contenido,
    required this.fechaEnvio,
    this.canal = 'ALUMNO',
    this.tipo = 'TEXTO',
    this.adjuntoNombre,
  });

  String get nombreCompleto => '$remitenteNombre $remitenteApellidos';
  bool get esAdjunto => tipo == 'ADJUNTO';

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: json['id'] as int,
      practicaId: json['practicaId'] as int,
      remitenteId: json['remitenteId'] as int,
      remitenteNombre: json['remitenteNombre'] as String,
      remitenteApellidos: json['remitenteApellidos'] as String,
      contenido: (json['contenido'] as String?) ?? '',
      fechaEnvio: DateTime.parse(json['fechaEnvio'] as String),
      canal: (json['canal'] as String?) ?? 'ALUMNO',
      tipo: (json['tipo'] as String?) ?? 'TEXTO',
      adjuntoNombre: json['adjuntoNombre'] as String?,
    );
  }
}
