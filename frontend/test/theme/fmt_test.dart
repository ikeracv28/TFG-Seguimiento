import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app_theme.dart';

void main() {
  group('fmtH — formato de horas', () {
    test('número entero muestra solo horas', () {
      expect(fmtH(8), '8h');
      expect(fmtH(0), '0h');
      expect(fmtH(1), '1h');
      expect(fmtH(40), '40h');
    });

    test('número con .5 muestra horas y 30min', () {
      expect(fmtH(7.5), '7h 30min');
      expect(fmtH(1.5), '1h 30min');
    });

    test('0.5 muestra solo 30min', () {
      expect(fmtH(0.5), '30min');
    });
  });
}
