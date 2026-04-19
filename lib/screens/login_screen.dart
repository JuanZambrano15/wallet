import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:wallet/utils/app_theme.dart';
import 'package:wallet/utils/validators.dart';
import 'package:wallet/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  final _authService = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) _showErrorSnackbar(AuthService.parseError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontFamily: 'Trebuchet MS',
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _loginWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print(e);
    }
  }

  void _loginWithGithub() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGithub();
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (mounted) _showErrorSnackbar("Error al conectar con GitHub");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Semantics(label: semanticLabel, button: true, child: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesion')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Wallet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electronico',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contrasena',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'O inicia con',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildSocialButton(
                        icon: const FaIcon(FontAwesomeIcons.google),
                        semanticLabel: 'Google',
                        onTap: _loginWithGoogle,
                      ),
                      _buildSocialButton(
                        icon: const FaIcon(FontAwesomeIcons.github),
                        semanticLabel: 'Git Hub',
                        onTap: _loginWithGithub,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('¿No tienes una cuenta?'),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/register');
                              },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Registrate',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
