// Conexion y configuracion de base de datos
import 'package:cloud_firestore/cloud_firestore.dart';

class dbConfig {
  static final dbConfig _instance = dbConfig._internal();
  factory dbConfig() => _instance;
  dbConfig._internal();

  final db = FirebaseFirestore.instance;
}
