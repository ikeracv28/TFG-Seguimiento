import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/models/auth_models.dart';

void main() {
  group('User.fromJson', () {
    final json = {
      'id': 1,
      'email': 'alumno@nexus.edu',
      'nombre': 'Carlos García',
      'roles': ['ROLE_ALUMNO'],
      'tieneFoto': false,
    };

    test('parsea todos los campos correctamente', () {
      final user = User.fromJson(json);
      expect(user.id, 1);
      expect(user.email, 'alumno@nexus.edu');
      expect(user.nombreCompleto, 'Carlos García');
      expect(user.roles, ['ROLE_ALUMNO']);
      expect(user.tieneFoto, false);
    });

    test('tieneFoto es false cuando el campo no está presente', () {
      final jsonSinFoto = Map<String, dynamic>.from(json)..remove('tieneFoto');
      final user = User.fromJson(jsonSinFoto);
      expect(user.tieneFoto, false);
    });

    test('tieneFoto es true cuando el campo es true', () {
      final jsonConFoto = Map<String, dynamic>.from(json)..[('tieneFoto')] = true;
      final user = User.fromJson(jsonConFoto);
      expect(user.tieneFoto, true);
    });

    test('parsea varios roles', () {
      final jsonMultiRol = Map<String, dynamic>.from(json)
        ..['roles'] = ['ROLE_ADMIN', 'ROLE_TUTOR_CENTRO'];
      final user = User.fromJson(jsonMultiRol);
      expect(user.roles.length, 2);
      expect(user.roles, contains('ROLE_ADMIN'));
    });

    test('copyWith actualiza tieneFoto sin cambiar otros campos', () {
      final user = User.fromJson(json);
      final updated = user.copyWith(tieneFoto: true);
      expect(updated.tieneFoto, true);
      expect(updated.id, user.id);
      expect(updated.email, user.email);
      expect(updated.nombreCompleto, user.nombreCompleto);
    });
  });

  group('AuthResponse.fromJson', () {
    final json = {
      'token': 'eyJhbGciOiJIUzI1NiJ9.payload.signature',
      'id': 2,
      'email': 'tutor@nexus.edu',
      'nombre': 'Ana Tutora',
      'roles': ['ROLE_TUTOR_CENTRO'],
      'tieneFoto': false,
    };

    test('parsea token y usuario anidado', () {
      final response = AuthResponse.fromJson(json);
      expect(response.token, startsWith('eyJ'));
      expect(response.user.email, 'tutor@nexus.edu');
      expect(response.user.nombreCompleto, 'Ana Tutora');
    });
  });
}
