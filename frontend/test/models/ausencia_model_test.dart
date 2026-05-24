import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/ausencia_model.dart';

void main() {
  final baseJson = {
    'id': 7,
    'practicaId': 5,
    'fecha': '2026-05-15',
    'motivo': 'Cita médica',
    'tipo': 'PENDIENTE',
    'tieneJustificante': false,
    'nombreFichero': null,
    'registradaPorId': 10,
    'registradaPorNombre': 'Carlos García',
    'revisadaPorId': null,
    'revisadaPorNombre': null,
    'comentarioRevision': null,
    'fechaCreacion': '2026-05-15T08:00:00',
  };

  group('Ausencia.fromJson', () {
    test('parsea todos los campos', () {
      final a = Ausencia.fromJson(baseJson);
      expect(a.id, 7);
      expect(a.practicaId, 5);
      expect(a.motivo, 'Cita médica');
      expect(a.tipo, 'PENDIENTE');
      expect(a.tieneJustificante, false);
      expect(a.registradaPorNombre, 'Carlos García');
    });

    test('tipo por defecto es PENDIENTE si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('tipo');
      final a = Ausencia.fromJson(json);
      expect(a.tipo, 'PENDIENTE');
    });

    test('tieneJustificante es false por defecto si falta', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('tieneJustificante');
      final a = Ausencia.fromJson(json);
      expect(a.tieneJustificante, false);
    });

    test('campos de revisión son null cuando no está revisada', () {
      final a = Ausencia.fromJson(baseJson);
      expect(a.revisadaPorId, isNull);
      expect(a.revisadaPorNombre, isNull);
      expect(a.comentarioRevision, isNull);
    });

    test('parsea campo revisión cuando está presente', () {
      final json = Map<String, dynamic>.from(baseJson)
        ..['revisadaPorId'] = 20
        ..['revisadaPorNombre'] = 'Ana Tutora'
        ..['comentarioRevision'] = 'Justificante recibido'
        ..['tipo'] = 'JUSTIFICADA';
      final a = Ausencia.fromJson(json);
      expect(a.revisadaPorId, 20);
      expect(a.revisadaPorNombre, 'Ana Tutora');
      expect(a.tipo, 'JUSTIFICADA');
    });

    test('parsea fecha correctamente', () {
      final a = Ausencia.fromJson(baseJson);
      expect(a.fecha.year, 2026);
      expect(a.fecha.month, 5);
      expect(a.fecha.day, 15);
    });
  });

  group('Ausencia getters', () {
    test('estaPendiente es true cuando tipo == PENDIENTE', () {
      final a = Ausencia.fromJson(baseJson);
      expect(a.estaPendiente, true);
    });

    test('estaPendiente es false cuando tipo != PENDIENTE', () {
      final json = Map<String, dynamic>.from(baseJson)..['tipo'] = 'JUSTIFICADA';
      final a = Ausencia.fromJson(json);
      expect(a.estaPendiente, false);
    });

    test('estaJustificada es true cuando tipo == JUSTIFICADA', () {
      final json = Map<String, dynamic>.from(baseJson)..['tipo'] = 'JUSTIFICADA';
      final a = Ausencia.fromJson(json);
      expect(a.estaJustificada, true);
    });

    test('estaJustificada es false cuando tipo == PENDIENTE', () {
      final a = Ausencia.fromJson(baseJson);
      expect(a.estaJustificada, false);
    });

    test('estaJustificada es false cuando tipo == NO_JUSTIFICADA', () {
      final json = Map<String, dynamic>.from(baseJson)..['tipo'] = 'NO_JUSTIFICADA';
      final a = Ausencia.fromJson(json);
      expect(a.estaJustificada, false);
    });
  });
}
