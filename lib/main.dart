import 'package:flutter/material.dart';
import 'package:wallet/screens/home_screen.dart';
import 'package:wallet/screens/login_screen.dart';
import 'package:wallet/screens/register_screen.dart';
import 'package:wallet/utils/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  runApp(const MyApp());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallet',
      theme: AppTheme.dark(),
      initialRoute: '/login',
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
