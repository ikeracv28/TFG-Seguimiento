import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/incidencia_model.dart';

void main() {
  final baseJson = {
    'id': 1,
    'practicaId': 5,
    'creadaPorId': 10,
    'creadaPorNombre': 'Carlos García',
    'tipo': 'ACCIDENTE',
    'descripcion': 'Descripción del accidente',
    'estado': 'ABIERTA',
    'fechaCreacion': '2026-05-19T09:00:00',
    'resueltaPorNombre': null,
    'fechaResolucion': null,
  };

  group('Incidencia.fromJson', () {
    test('parsea todos los campos', () {
      final i = Incidencia.fromJson(baseJson);
      expect(i.id, 1);
      expect(i.practicaId, 5);
      expect(i.creadaPorId, 10);
      expect(i.creadaPorNombre, 'Carlos García');
      expect(i.tipo, 'ACCIDENTE');
      expect(i.descripcion, 'Descripción del accidente');
      expect(i.estado, 'ABIERTA');
    });

    test('estado por defecto es ABIERTA si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('estado');
      final i = Incidencia.fromJson(json);
      expect(i.estado, 'ABIERTA');
    });

    test('creadaPorNombre es vacío si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..['creadaPorNombre'] = null;
      final i = Incidencia.fromJson(json);
      expect(i.creadaPorNombre, '');
    });

    test('tipo puede ser null', () {
      final json = Map<String, dynamic>.from(baseJson)..['tipo'] = null;
      final i = Incidencia.fromJson(json);
      expect(i.tipo, isNull);
    });

    test('resueltaPorNombre y fechaResolucion son null si no está resuelta', () {
      final i = Incidencia.fromJson(baseJson);
      expect(i.resueltaPorNombre, isNull);
      expect(i.fechaResolucion, isNull);
    });

    test('parsea resueltaPorNombre y fechaResolucion cuando están presentes', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['resueltaPorNombre'] = 'Ana Tutora'
        ..['fechaResolucion'] = '2026-05-20T12:00:00'
        ..['estado'] = 'RESUELTA';
      final i = Incidencia.fromJson(json);
      expect(i.resueltaPorNombre, 'Ana Tutora');
      expect(i.fechaResolucion, isNotNull);
      expect(i.fechaResolucion!.year, 2026);
    });
  });

  group('Incidencia.estaAbierta', () {
    test('es true cuando estado es ABIERTA', () {
      final i = Incidencia.fromJson(baseJson);
      expect(i.estaAbierta, true);
    });

    test('es true cuando estado es EN_PROCESO', () {
      final json = Map<String, dynamic>.from(baseJson)..['estado'] = 'EN_PROCESO';
      final i = Incidencia.fromJson(json);
      expect(i.estaAbierta, true);
    });

    test('es false cuando estado es RESUELTA', () {
      final json = Map<String, dynamic>.from(baseJson)..['estado'] = 'RESUELTA';
      final i = Incidencia.fromJson(json);
      expect(i.estaAbierta, false);
    });

    test('es false cuando estado es CERRADA', () {
      final json = Map<String, dynamic>.from(baseJson)..['estado'] = 'CERRADA';
      final i = Incidencia.fromJson(json);
      expect(i.estaAbierta, false);
    });
  });
}
