import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nexus/presentation/providers/auth_provider.dart';
import 'package:nexus/presentation/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen muestra campos de email, contraseña y botón Acceder',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Acceder'), findsOneWidget);
  });
}
