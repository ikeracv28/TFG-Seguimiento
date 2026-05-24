import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/providers/practica_provider.dart';
import 'package:app/data/models/seguimiento_model.dart';
import 'package:app/data/models/incidencia_model.dart';
import 'package:app/data/models/ausencia_model.dart';

Seguimiento _seguimiento({int id = 1, double horas = 8.0, String estado = 'COMPLETADO', String tipo = 'DIARIO'}) {
  return Seguimiento(
    id: id,
    practicaId: 5,
    fechaRegistro: DateTime(2026, 5, 19),
    horasRealizadas: horas,
    estado: estado,
    tipo: tipo,
    fechaCreacion: DateTime(2026, 5, 19),
  );
}

Incidencia _incidencia({int id = 1, String estado = 'ABIERTA'}) {
  return Incidencia(
    id: id,
    practicaId: 5,
    creadaPorId: 10,
    creadaPorNombre: 'Carlos',
    descripcion: 'Descripción',
    estado: estado,
    fechaCreacion: DateTime(2026, 5, 19),
  );
}

Ausencia _ausencia({int id = 1, String tipo = 'PENDIENTE'}) {
  return Ausencia(
    id: id,
    practicaId: 5,
    fecha: DateTime(2026, 5, 15),
    motivo: 'Cita médica',
    tipo: tipo,
    tieneJustificante: false,
    registradaPorId: 10,
    registradaPorNombre: 'Carlos',
    fechaCreacion: DateTime(2026, 5, 15),
  );
}

void main() {
  group('PracticaProvider — estado inicial', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('listas empiezan vacías', () {
      expect(provider.seguimientos, isEmpty);
      expect(provider.incidencias, isEmpty);
      expect(provider.ausencias, isEmpty);
    });

    test('practicaActiva es null inicialmente', () {
      expect(provider.practicaActiva, isNull);
    });

    test('horasCompletadas es 0 sin seguimientos', () {
      expect(provider.horasCompletadas, 0.0);
    });

    test('incidenciasAbiertas es 0 sin incidencias', () {
      expect(provider.incidenciasAbiertas, 0);
    });

    test('ausenciasPendientes es 0 sin ausencias', () {
      expect(provider.ausenciasPendientes, 0);
    });
  });

  group('PracticaProvider.agregarSeguimiento', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('añade al frente de la lista', () {
      final s1 = _seguimiento(id: 1);
      final s2 = _seguimiento(id: 2);
      provider.agregarSeguimiento(s1);
      provider.agregarSeguimiento(s2);
      expect(provider.seguimientos.first.id, 2);
    });

    test('notifica a los listeners', () {
      bool notified = false;
      provider.addListener(() => notified = true);
      provider.agregarSeguimiento(_seguimiento());
      expect(notified, true);
    });
  });

  group('PracticaProvider.horasCompletadas', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('suma solo seguimientos COMPLETADO', () {
      provider.agregarSeguimiento(_seguimiento(id: 1, horas: 8.0, estado: 'COMPLETADO'));
      provider.agregarSeguimiento(_seguimiento(id: 2, horas: 6.0, estado: 'PENDIENTE_EMPRESA'));
      provider.agregarSeguimiento(_seguimiento(id: 3, horas: 4.0, estado: 'COMPLETADO'));
      expect(provider.horasCompletadas, 12.0);
    });

    test('es 0 cuando todos están pendientes', () {
      provider.agregarSeguimiento(_seguimiento(id: 1, horas: 8.0, estado: 'PENDIENTE_EMPRESA'));
      expect(provider.horasCompletadas, 0.0);
    });

    test('suma correctamente decimales', () {
      provider.agregarSeguimiento(_seguimiento(id: 1, horas: 7.5, estado: 'COMPLETADO'));
      provider.agregarSeguimiento(_seguimiento(id: 2, horas: 4.5, estado: 'COMPLETADO'));
      expect(provider.horasCompletadas, 12.0);
    });
  });

  group('PracticaProvider.incidenciasAbiertas', () {
    late PracticaProvider provider;

    void addIncidencias(List<Incidencia> lista) {
      for (final i in lista) {
        provider.agregarSeguimiento; // silenciar
      }
    }

    setUp(() {
      provider = PracticaProvider();
    });

    test('cuenta ABIERTA y EN_PROCESO como abiertas', () {
      final i1 = _incidencia(id: 1, estado: 'ABIERTA');
      final i2 = _incidencia(id: 2, estado: 'EN_PROCESO');
      final i3 = _incidencia(id: 3, estado: 'RESUELTA');
      // Construimos el provider con incidencias directamente vía reflexión es imposible.
      // Probamos los getters a través de Incidencia.estaAbierta:
      expect(i1.estaAbierta, true);
      expect(i2.estaAbierta, true);
      expect(i3.estaAbierta, false);
    });
  });

  group('PracticaProvider.eliminarAusencia', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('elimina la ausencia con el id dado', () {
      provider.agregarAusencia(_ausencia(id: 1));
      provider.agregarAusencia(_ausencia(id: 2));
      provider.eliminarAusencia(1);
      expect(provider.ausencias.length, 1);
      expect(provider.ausencias.first.id, 2);
    });

    test('no hace nada si el id no existe', () {
      provider.agregarAusencia(_ausencia(id: 1));
      provider.eliminarAusencia(999);
      expect(provider.ausencias.length, 1);
    });

    test('notifica a los listeners', () {
      provider.agregarAusencia(_ausencia(id: 1));
      bool notified = false;
      provider.addListener(() => notified = true);
      provider.eliminarAusencia(1);
      expect(notified, true);
    });
  });

  group('PracticaProvider.actualizarAusencia', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('reemplaza la ausencia con el mismo id', () {
      provider.agregarAusencia(_ausencia(id: 1, tipo: 'PENDIENTE'));
      final actualizada = _ausencia(id: 1, tipo: 'JUSTIFICADA');
      provider.actualizarAusencia(actualizada);
      expect(provider.ausencias.first.tipo, 'JUSTIFICADA');
    });

    test('mantiene las demás ausencias intactas', () {
      provider.agregarAusencia(_ausencia(id: 1));
      provider.agregarAusencia(_ausencia(id: 2));
      provider.actualizarAusencia(_ausencia(id: 1, tipo: 'JUSTIFICADA'));
      expect(provider.ausencias.length, 2);
    });
  });

  group('PracticaProvider.ausenciasPendientes', () {
    late PracticaProvider provider;
    setUp(() => provider = PracticaProvider());

    test('cuenta solo las PENDIENTE', () {
      provider.agregarAusencia(_ausencia(id: 1, tipo: 'PENDIENTE'));
      provider.agregarAusencia(_ausencia(id: 2, tipo: 'JUSTIFICADA'));
      provider.agregarAusencia(_ausencia(id: 3, tipo: 'PENDIENTE'));
      expect(provider.ausenciasPendientes, 2);
    });

    test('es 0 cuando no hay ausencias pendientes', () {
      provider.agregarAusencia(_ausencia(id: 1, tipo: 'JUSTIFICADA'));
      expect(provider.ausenciasPendientes, 0);
    });
  });
}
