import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wallet/config/configDB.dart';

class userService {
  final _db = dbConfig().db;

  final userData = <String, dynamic>{
    "id": "150254553",
    "email": "victor@gmail.com",
    "password": "12345678",
    "nameUser": "V23",
  };

  // POST 
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _db.collection('users').add(userData);
      print('Usuario creado exitosamente');
    } catch (e) {
      print('Error al crear usuario: $e');
      rethrow;
    }
  }

}
