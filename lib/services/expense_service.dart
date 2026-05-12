// lib/services/expense_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _expensesCol => _db.collection('expenses');
  CollectionReference get _categoriesCol => _db.collection('expense_categories');

  // ─── Auth helper ─────────────────────────────────────────────────────────

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) throw Exception('Usuario no autenticado');
    return userId;
  }

  // ─── CRUD Gastos ──────────────────────────────────────────────────────────

  Future<Expense> addExpense({
    required double amount,
    required DateTime date,
    required ExpenseType type,
    required String categoryId,
    required String name,
    String description = '',
    DateTime? dueDate,
  }) async {
    final userId = await _getCurrentUserId();

    final docRef = _expensesCol.doc();
    final expense = Expense(
      id: docRef.id,
      userId: userId,
      amount: amount,
      date: date,
      type: type,
      categoryId: categoryId,
      name: name,
      description: description.trim(),
      dueDate: type == ExpenseType.fixed ? dueDate : null,
    );

    await docRef.set(expense.toMap());
    return expense;
  }

  Future<List<Expense>> getExpensesByUser() async {
    final userId = await _getCurrentUserId();

    final snapshot = await _expensesCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Expense>> streamExpensesByUser(String userId) {
    return _expensesCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> updateExpense({
    required String id,
    required double amount,
    required DateTime date,
    required ExpenseType type,
    required String categoryId,
    required String name,
    String description = '',
    DateTime? dueDate,
  }) async {
    await _expensesCol.doc(id).update({
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'categoryId': categoryId,
      'name': name,
      'description': description.trim(),
      'dueDate': (type == ExpenseType.fixed && dueDate != null)
          ? Timestamp.fromDate(dueDate)
          : null,
    });
  }

  Future<void> deleteExpense(String id) async {
    await _expensesCol.doc(id).delete();
  }

  // ─── Categorías ───────────────────────────────────────────────────────────

  /// Retorna las categorías del sistema + las personalizadas del usuario.
  Future<List<ExpenseCategory>> getCategoriesByUser() async {
    final userId = await _getCurrentUserId();

    // Categorías personalizadas guardadas en Firestore
    final snapshot = await _categoriesCol
        .where('userId', isEqualTo: userId)
        .where('isDefault', isEqualTo: false)
        .get();

    final custom = snapshot.docs
        .map((doc) => ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    // Combinar: primero las predeterminadas, luego las personalizadas
    return [...ExpenseCategory.defaults(userId), ...custom];
  }

  Future<ExpenseCategory> addCustomCategory(String name) async {
    final userId = await _getCurrentUserId();

    final docRef = _categoriesCol.doc();
    final category = ExpenseCategory(
      id: docRef.id,
      userId: userId,
      name: name.trim(),
      isDefault: false,
    );

    await docRef.set(category.toMap());
    return category;
  }

  Future<void> deleteCustomCategory(String id) async {
    await _categoriesCol.doc(id).delete();
  }
}
