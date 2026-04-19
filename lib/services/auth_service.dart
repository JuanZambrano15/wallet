import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/models/user.dart';
import 'package:wallet/config/configDB.dart';

class AuthService {
  final _db = dbConfig().db;
  final _auth = FirebaseAuth.instance;
  final String _jwtSecret = "WalletSecretKey2026";

  // Configuración de Google para Web
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: "469142840204-55uc08gq2gabtpj8v5av78m44m1a5h11.apps.googleusercontent.com",
  );

  // --- GENERACIÓN DE TOKEN ---
  Future<String> _generateAndSaveToken(String userId) async {
    final jwt = JWT({'id': userId});
    final token = jwt.sign(SecretKey(_jwtSecret));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tokenAuth', token);
    await prefs.setString('userId', userId);

    // print('-----------------------------------------');
    // print('TOKEN GENERADO Y GUARDADO: $token');
    // print('PARA EL USUARIO ID: $userId');
    // print('-----------------------------------------');
    return token;
  }

  // --- REGISTRO MANUAL ---
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String nameUser,
  }) async {
    final existing = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .get();
    
    if (existing.docs.isNotEmpty) throw Exception('email-already-in-use');

    final docRef = _db.collection('users').doc();
    final hashedPassword = BCrypt.hashpw(
      password,
      BCrypt.gensalt(logRounds: 12),
    );

    final newUser = UserModel(
      id: docRef.id,
      email: email.trim(),
      password: hashedPassword,
      nameUser: nameUser.trim(),
    );

    await docRef.set(newUser.toMap());
    await _generateAndSaveToken(docRef.id);
  }

  // --- LOGIN MANUAL ---
  Future<void> loginWithEmail(String email, String password) async {
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .get();
    
    if (query.docs.isEmpty) throw Exception('user-not-found');

    final user = UserModel.fromMap(query.docs.first.data());
    if (!BCrypt.checkpw(password, user.password)) {
      throw Exception('wrong-password');
    }

    await _generateAndSaveToken(user.id);
  }

  // --- GOOGLE SIGN IN ---
  Future<void> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _syncSocialUser(userCredential.user!);
  }

  // --- GITHUB SIGN IN (Corregido: Ahora dentro de la clase) ---
  Future<void> signInWithGithub() async {
    try {
      GithubAuthProvider githubProvider = GithubAuthProvider();
      // Usamos Popup porque estás en Web (Chrome)
      final userCredential = await _auth.signInWithPopup(githubProvider);
      
      if (userCredential.user != null) {
        await _syncSocialUser(userCredential.user!);
      }
    } catch (e) {
      print("Error detallado de GitHub: $e");
      rethrow;
    }
  }

  // --- SINCRONIZACIÓN CON FIRESTORE ---
  Future<void> _syncSocialUser(User firebaseUser) async {
    final email = firebaseUser.email!;
    final query = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    String userId;
    if (query.docs.isEmpty) {
      final docRef = _db.collection('users').doc();
      userId = docRef.id;
      await docRef.set({
        'id': userId,
        'email': email,
        'nameUser': firebaseUser.displayName ?? '',
        'password': '', // Los usuarios sociales no tienen password manual
      });
    } else {
      userId = query.docs.first.id;
    }
    await _generateAndSaveToken(userId);
  }

  // --- HELPERS ---
  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tokenAuth');
    if (token == null) return false;
    try {
      JWT.verify(token, SecretKey(_jwtSecret));
      return true;
    } catch (e) {
      return false;
    }
  }

  static String parseError(String error) {
    if (error.contains('email-already-in-use')) return 'Este correo ya está registrado.';
    if (error.contains('user-not-found')) return 'Usuario no encontrado.';
    if (error.contains('wrong-password')) return 'Contraseña incorrecta.';
    return 'Error de autenticación. Intenta de nuevo.';
  }
} // <--- Esta es la única llave que cierra la clase