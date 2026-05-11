// lib/services/income_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/income_model.dart';
import '../models/sourceIncome.dart';

class IncomeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('incomes');

  // ─── Mismo patrón que SourceIncomeService ─────────────────────────────────

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) throw Exception('Usuario no autenticado');
    return userId;
  }

  // ─── CRUD de ingresos ─────────────────────────────────────────────────────

  Future<Income> addIncome({
    required double amount,
    required DateTime date,
    required String sourceId,
    String description = '',
  }) async {
    final userId = await _getCurrentUserId();

    final docRef = _collection.doc();
    final income = Income(
      id: docRef.id,
      userId: userId,
      amount: amount,
      date: date,
      sourceId: sourceId,
      description: description.trim(),
    );

    await docRef.set(income.toMap());
    return income;
  }

  Future<List<Income>> getIncomesByUser() async {
    final userId = await _getCurrentUserId();

    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Income.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Income>> streamIncomesByUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<Income?> getIncomeById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Income.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateIncome({
    required String id,
    required double amount,
    required DateTime date,
    required String sourceId,
    String description = '',
  }) async {
    await _collection.doc(id).update({
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'sourceId': sourceId,
      'description': description.trim(),
    });
  }

  Future<void> deleteIncome(String id) async {
    await _collection.doc(id).delete();
  }

  // ─── Fuentes de ingreso (usa source_incomes igual que SourceIncomeService) ─

  Future<List<SourceIncome>> getSourceIncomesByUser() async {
    final userId = await _getCurrentUserId();

    final snapshot = await _db
        .collection('source_incomes')
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get();

    final sources = snapshot.docs
        .map((doc) => SourceIncome.fromMap(doc.data()))
        .toList();

    if (sources.isEmpty) return [_genericSource(userId)];
    return sources;
  }

  SourceIncome _genericSource(String userId) {
    return SourceIncome(
      id: 'generic',
      userId: userId,
      name: 'General',
      description: 'Fuente de ingreso por defecto',
      personalized: false,
    );
  }
}