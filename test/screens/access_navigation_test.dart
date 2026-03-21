import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/screens/home_screen.dart';
import 'package:wallet/screens/login_screen.dart';
import 'package:wallet/screens/register_screen.dart';

void main() {
  testWidgets('HU-03 permite navegar entre login, registro y home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );

    expect(find.text('Iniciar Sesion'), findsOneWidget);

    await tester.tap(find.text('Registrate gratis'));
    await tester.pumpAndSettle();

    expect(find.text('Crear Cuenta'), findsOneWidget);
    expect(find.text('Ya tienes cuenta? Inicia sesion'), findsOneWidget);

    await tester.tap(find.text('Ya tienes cuenta? Inicia sesion'));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesion'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      'estudiante@ufpso.edu.co',
    );
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Mis Tareas'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.exit_to_app));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesion'), findsOneWidget);
  });
}
