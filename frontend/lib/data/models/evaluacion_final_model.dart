class EvaluacionFinalModel {
  final int id;
  final int practicaId;
  final String alumnoNombre;
  final double? actitudPuntualidad;
  final double? competenciaTecnica;
  final double? iniciativaAutonomia;
  final double? trabajoEquipo;
  final double? cumplimientoTareas;
  final double notaGlobal;
  final String? comentario;
  final int tutorEmpresaId;
  final String tutorEmpresaNombre;
  final DateTime fechaEvaluacion;

  EvaluacionFinalModel({
    required this.id,
    required this.practicaId,
    required this.alumnoNombre,
    this.actitudPuntualidad,
    this.competenciaTecnica,
    this.iniciativaAutonomia,
    this.trabajoEquipo,
    this.cumplimientoTareas,
    required this.notaGlobal,
    this.comentario,
    required this.tutorEmpresaId,
    required this.tutorEmpresaNombre,
    required this.fechaEvaluacion,
  });

  factory EvaluacionFinalModel.fromJson(Map<String, dynamic> j) =>
      EvaluacionFinalModel(
        id: j['id'] as int,
        practicaId: j['practicaId'] as int,
        alumnoNombre: j['alumnoNombre'] as String,
        actitudPuntualidad: (j['actitudPuntualidad'] as num?)?.toDouble(),
        competenciaTecnica: (j['competenciaTecnica'] as num?)?.toDouble(),
        iniciativaAutonomia: (j['iniciativaAutonomia'] as num?)?.toDouble(),
        trabajoEquipo: (j['trabajoEquipo'] as num?)?.toDouble(),
        cumplimientoTareas: (j['cumplimientoTareas'] as num?)?.toDouble(),
        notaGlobal: (j['notaGlobal'] as num).toDouble(),
        comentario: j['comentario'] as String?,
        tutorEmpresaId: j['tutorEmpresaId'] as int,
        tutorEmpresaNombre: j['tutorEmpresaNombre'] as String,
        fechaEvaluacion: DateTime.parse(j['fechaEvaluacion'] as String),
      );
}
