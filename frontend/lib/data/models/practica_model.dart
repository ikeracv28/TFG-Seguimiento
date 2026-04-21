import 'dart:convert';

/**
 * Modelo de datos para las Prácticas Académicas.
 * Sincronizado con PracticaResponse.java del Backend.
 */
class Practica {
  final int id;
  final String codigo;
  final int alumnoId;
  final String alumnoNombre;
  final int tutorCentroId;
  final String tutorCentroNombre;
  final int tutorEmpresaId;
  final String tutorEmpresaNombre;
  final int empresaId;
  final String empresaNombre;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final int? horasTotales;
  final String estado;
  final DateTime fechaCreacion;

  Practica({
    required this.id,
    required this.codigo,
    required this.alumnoId,
    required this.alumnoNombre,
    required this.tutorCentroId,
    required this.tutorCentroNombre,
    required this.tutorEmpresaId,
    required this.tutorEmpresaNombre,
    required this.empresaId,
    required this.empresaNombre,
    this.fechaInicio,
    this.fechaFin,
    this.horasTotales,
    required this.estado,
    required this.fechaCreacion,
  });

  /**
   * Factory para construir la instancia desde JSON.
   */
  factory Practica.fromJson(Map<String, dynamic> json) {
    return Practica(
      id: json['id'],
      codigo: json['codigo'],
      alumnoId: json['alumnoId'],
      alumnoNombre: json['alumnoNombre'],
      tutorCentroId: json['tutorCentroId'],
      tutorCentroNombre: json['tutorCentroNombre'],
      tutorEmpresaId: json['tutorEmpresaId'],
      tutorEmpresaNombre: json['tutorEmpresaNombre'],
      empresaId: json['empresaId'],
      empresaNombre: json['empresaNombre'],
      fechaInicio: json['fechaInicio'] != null 
          ? DateTime.parse(json['fechaInicio']) 
          : null,
      fechaFin: json['fechaFin'] != null 
          ? DateTime.parse(json['fechaFin']) 
          : null,
      horasTotales: json['horasTotales'],
      estado: json['estado'] ?? 'BORRADOR',
      fechaCreacion: DateTime.parse(json['fechaCreacion']),
    );
  }

  /**
   * Convierte la instancia a un Map para envíos o almacenamiento.
   */
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'alumnoId': alumnoId,
      'alumnoNombre': alumnoNombre,
      'tutorCentroId': tutorCentroId,
      'tutorCentroNombre': tutorCentroNombre,
      'tutorEmpresaId': tutorEmpresaId,
      'tutorEmpresaNombre': tutorEmpresaNombre,
      'empresaId': empresaId,
      'empresaNombre': empresaNombre,
      'fechaInicio': fechaInicio?.toIso8601String().split('T')[0],
      'fechaFin': fechaFin?.toIso8601String().split('T')[0],
      'horasTotales': horasTotales,
      'estado': estado,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }
}
