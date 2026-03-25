import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/screens/home_screen.dart';
import 'package:wallet/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen valida campos, muestra loading y navega a home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/login',
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
        },
      ),
    );

    expect(find.text('Iniciar Sesion'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.bySemanticsLabel('Google'), findsOneWidget);
    expect(find.bySemanticsLabel('GitHub'), findsOneWidget);
    expect(find.bySemanticsLabel('Facebook'), findsOneWidget);
    expect(find.text('¿No tienes una cuenta? '), findsOneWidget);
    expect(find.text('Registrate gratis'), findsOneWidget);

    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(
      find.text('Por favor, ingrese su correo electrónico'),
      findsOneWidget,
    );
    expect(find.text('Por favor, ingrese una contraseña'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'correo_invalido');
    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Por favor, ingrese un correo válido'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener mínimo 6 caracteres'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextFormField).first,
      'estudiante@ufpso.edu.co',
    );
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Mis Tareas'), findsOneWidget);
    expect(find.text('¡Bienvenido a To-Do UFPSO!'), findsOneWidget);
  });
}
