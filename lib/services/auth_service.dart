import 'package:wallet/config/configDB.dart';
import 'package:wallet/models/user.dart';

class AuthService {
  final _db = dbConfig().db;

  // REGISTRO DE USUARIOS
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String nameUser,
  }) async {
    final docRef = _db.collection('users').doc();

    final newUser = UserModel(
      id: docRef.id,
      email: email.trim(),
      password: password,
      nameUser: nameUser.trim(),
    );

    await docRef.set(newUser.toMap());
  }

  static String parseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Este correo ya está registrado.';
    } else if (error.contains('invalid-email')) {
      return 'El correo no es válido.';
    } else if (error.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else if (error.contains('user-not-found')) {
      return 'No existe una cuenta con este correo.';
    } else if (error.contains('wrong-password')) {
      return 'Contraseña incorrecta.';
    } else if (error.contains('network-request-failed')) {
      return 'Sin conexión a internet.';
    } else {
      return 'Ocurrió un error. Intenta de nuevo.';
    }
  }
}
