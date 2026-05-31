class TutoriaModel {
  final int id;
  final int alumnoId;
  final String alumnoNombre;
  final String alumnoEmail;
  final DateTime fechaHora;
  final int duracionMinutos;
  final bool notificado;

  const TutoriaModel({
    required this.id,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.alumnoEmail,
    required this.fechaHora,
    required this.duracionMinutos,
    required this.notificado,
  });

  factory TutoriaModel.fromJson(Map<String, dynamic> json) => TutoriaModel(
        id: json['id'] as int,
        alumnoId: json['alumnoId'] as int,
        alumnoNombre: json['alumnoNombre'] as String,
        alumnoEmail: json['alumnoEmail'] as String,
        fechaHora: DateTime.parse(json['fechaHora'] as String),
        duracionMinutos: json['duracionMinutos'] as int,
        notificado: json['notificado'] as bool,
      );
}
