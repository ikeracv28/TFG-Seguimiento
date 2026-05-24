import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/providers/auth_provider.dart';

void main() {
  group('AuthProvider — estado inicial', () {
    late AuthProvider provider;

    setUp(() => provider = AuthProvider());

    test('sessionChecked empieza en false', () {
      expect(provider.sessionChecked, false);
    });

    test('isLoading empieza en false', () {
      expect(provider.isLoading, false);
    });

    test('isAuthenticated es false cuando no hay usuario', () {
      expect(provider.isAuthenticated, false);
    });

    test('user es null inicialmente', () {
      expect(provider.user, isNull);
    });

    test('errorMessage es null inicialmente', () {
      expect(provider.errorMessage, isNull);
    });
  });
}
