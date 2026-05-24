import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/practica_model.dart';

void main() {
  final baseJson = {
    'id': 5,
    'codigo': 'FCT-2026-001',
    'alumnoId': 10,
    'alumnoNombre': 'Carlos García',
    'tutorCentroId': 20,
    'tutorCentroNombre': 'Ana Tutora',
    'tutorEmpresaId': 30,
    'tutorEmpresaNombre': 'Luis Empresa',
    'empresaId': 40,
    'empresaNombre': 'Tecnología S.A.',
    'fechaInicio': '2026-03-01',
    'fechaFin': '2026-06-30',
    'horasTotales': 400,
    'estado': 'ACTIVA',
    'fechaCreacion': '2026-02-15T10:00:00',
  };

  group('Practica.fromJson', () {
    test('parsea todos los campos correctamente', () {
      final p = Practica.fromJson(baseJson);
      expect(p.id, 5);
      expect(p.codigo, 'FCT-2026-001');
      expect(p.alumnoId, 10);
      expect(p.alumnoNombre, 'Carlos García');
      expect(p.tutorCentroId, 20);
      expect(p.tutorEmpresaId, 30);
      expect(p.empresaId, 40);
      expect(p.empresaNombre, 'Tecnología S.A.');
      expect(p.horasTotales, 400);
      expect(p.estado, 'ACTIVA');
    });

    test('estado por defecto es BORRADOR si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('estado');
      final p = Practica.fromJson(json);
      expect(p.estado, 'BORRADOR');
    });

    test('fechaInicio y fechaFin son null si no están presentes', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['fechaInicio'] = null
        ..['fechaFin'] = null;
      final p = Practica.fromJson(json);
      expect(p.fechaInicio, isNull);
      expect(p.fechaFin, isNull);
    });

    test('horasTotales puede ser null', () {
      final json = Map<String, dynamic>.from(baseJson)..['horasTotales'] = null;
      final p = Practica.fromJson(json);
      expect(p.horasTotales, isNull);
    });

    test('parsea fechaCreacion correctamente', () {
      final p = Practica.fromJson(baseJson);
      expect(p.fechaCreacion.year, 2026);
      expect(p.fechaCreacion.month, 2);
      expect(p.fechaCreacion.day, 15);
    });
  });

  group('Practica.toJson', () {
    test('serializa los campos correctamente', () {
      final p = Practica.fromJson(baseJson);
      final json = p.toJson();
      expect(json['id'], 5);
      expect(json['codigo'], 'FCT-2026-001');
      expect(json['alumnoId'], 10);
      expect(json['estado'], 'ACTIVA');
    });

    test('fechaInicio serializa solo la parte de fecha (sin hora)', () {
      final p = Practica.fromJson(baseJson);
      final json = p.toJson();
      expect(json['fechaInicio'], '2026-03-01');
    });

    test('fechaInicio null serializa como null', () {
      final json = Map<String, dynamic>.from(baseJson)..['fechaInicio'] = null;
      final p = Practica.fromJson(json);
      expect(p.toJson()['fechaInicio'], isNull);
    });
  });
}
