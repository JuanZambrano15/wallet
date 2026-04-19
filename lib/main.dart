import 'package:flutter/material.dart';
import 'package:wallet/screens/home_screen.dart';
import 'package:wallet/screens/login_screen.dart';
import 'package:wallet/screens/register_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wallet/services/auth_service.dart';
import 'package:wallet/utils/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final authService = AuthService();
  bool isValid = await authService.isTokenValid();

  runApp(MyApp(initialRoute: isValid ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet App',
      theme: AppTheme.dark(),
      initialRoute: initialRoute,
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
