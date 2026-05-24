import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/seguimiento_model.dart';

void main() {
  final baseJson = {
    'id': 10,
    'practicaId': 5,
    'fechaRegistro': '2026-05-19',
    'horasRealizadas': 8,
    'descripcion': 'Descripción del trabajo realizado',
    'estado': 'COMPLETADO',
    'tipo': 'DIARIO',
    'validadoPorId': null,
    'validadoPorNombre': null,
    'comentarioTutor': null,
    'fechaCreacion': '2026-05-19T10:00:00',
  };

  group('Seguimiento.fromJson', () {
    test('parsea todos los campos', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.id, 10);
      expect(s.practicaId, 5);
      expect(s.horasRealizadas, 8.0);
      expect(s.estado, 'COMPLETADO');
      expect(s.tipo, 'DIARIO');
      expect(s.descripcion, 'Descripción del trabajo realizado');
    });

    test('horasRealizadas convierte int a double', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.horasRealizadas, isA<double>());
    });

    test('horasRealizadas acepta decimales', () {
      final json = Map<String, dynamic>.from(baseJson)..['horasRealizadas'] = 7.5;
      final s = Seguimiento.fromJson(json);
      expect(s.horasRealizadas, 7.5);
    });

    test('estado por defecto es PENDIENTE_EMPRESA si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('estado');
      final s = Seguimiento.fromJson(json);
      expect(s.estado, 'PENDIENTE_EMPRESA');
    });

    test('tipo por defecto es DIARIO si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('tipo');
      final s = Seguimiento.fromJson(json);
      expect(s.tipo, 'DIARIO');
    });

    test('parsea fechaRegistro como DateTime', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.fechaRegistro, isA<DateTime>());
      expect(s.fechaRegistro.year, 2026);
      expect(s.fechaRegistro.month, 5);
      expect(s.fechaRegistro.day, 19);
    });

    test('campos opcionales son null por defecto', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.validadoPorId, isNull);
      expect(s.validadoPorNombre, isNull);
      expect(s.comentarioTutor, isNull);
    });
  });

  group('Seguimiento getters', () {
    test('esSemanal es true cuando tipo == SEMANAL', () {
      final json = Map<String, dynamic>.from(baseJson)..['tipo'] = 'SEMANAL';
      final s = Seguimiento.fromJson(json);
      expect(s.esSemanal, true);
    });

    test('esSemanal es false cuando tipo == DIARIO', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.esSemanal, false);
    });

    test('cuentaParaProgreso es true cuando estado == COMPLETADO', () {
      final s = Seguimiento.fromJson(baseJson);
      expect(s.cuentaParaProgreso, true);
    });

    test('cuentaParaProgreso es false cuando estado != COMPLETADO', () {
      final json = Map<String, dynamic>.from(baseJson)..['estado'] = 'PENDIENTE_EMPRESA';
      final s = Seguimiento.fromJson(json);
      expect(s.cuentaParaProgreso, false);
    });

    test('cuentaParaProgreso es false para PENDIENTE_TUTOR', () {
      final json = Map<String, dynamic>.from(baseJson)..['estado'] = 'PENDIENTE_TUTOR';
      final s = Seguimiento.fromJson(json);
      expect(s.cuentaParaProgreso, false);
    });
  });
}
