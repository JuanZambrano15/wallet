// lib/services/income_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/income_model.dart';

class IncomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the currently authenticated user's UID.
  /// Throws [Exception] if no user is signed in.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');
    return user.uid;
  }

  /// Base collection reference for this user's incomes.
  CollectionReference<Map<String, dynamic>> get _incomesRef =>
      _firestore.collection('users').doc(_uid).collection('incomes');

  /// Base collection reference for this user's income sources.
  CollectionReference<Map<String, dynamic>> get _sourcesRef =>
      _firestore.collection('users').doc(_uid).collection('incomeSources');

  // ─── Income CRUD ──────────────────────────────────────────────────────────

  /// Saves a new [Income] to Firestore and returns the generated document ID.
  Future<String> addIncome(Income income) async {
    try {
      final docRef = await _incomesRef.add(income.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to save income: ${e.message}');
    }
  }

  /// Updates an existing [Income] in Firestore.
  /// The [income] must have a non-null [id].
  Future<void> updateIncome(Income income) async {
    if (income.id == null) {
      throw ArgumentError('Income id must not be null for an update operation.');
    }
    try {
      await _incomesRef.doc(income.id).update(income.toMap());
    } on FirebaseException catch (e) {
      throw Exception('Failed to update income: ${e.message}');
    }
  }

  /// Deletes an income by its [id].
  Future<void> deleteIncome(String id) async {
    try {
      await _incomesRef.doc(id).delete();
    } on FirebaseException catch (e) {
      throw Exception('Failed to delete income: ${e.message}');
    }
  }

  /// Returns a real-time stream of all incomes, ordered by date descending.
  Stream<List<Income>> watchIncomes() {
    return _incomesRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Income.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Fetches all incomes once (one-time read).
  Future<List<Income>> fetchIncomes() async {
    try {
      final snapshot =
          await _incomesRef.orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) => Income.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch incomes: ${e.message}');
    }
  }

  // ─── Income Sources ────────────────────────────────────────────────────────

  /// Fetches all income sources for the current user.
  /// If none exist, returns a list containing the default [IncomeSource.general].
  Future<List<IncomeSource>> fetchIncomeSources() async {
    try {
      final snapshot = await _sourcesRef.orderBy('name').get();

      if (snapshot.docs.isEmpty) {
        // Ensure the default source exists in Firestore.
        await _ensureDefaultSourceExists();
        return [IncomeSource.general];
      }

      return snapshot.docs
          .map((doc) => IncomeSource.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw Exception('Failed to fetch income sources: ${e.message}');
    }
  }

  /// Returns a real-time stream of income sources.
  Stream<List<IncomeSource>> watchIncomeSources() {
    return _sourcesRef.orderBy('name').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return [IncomeSource.general];
      return snapshot.docs
          .map((doc) => IncomeSource.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Adds a new income source to Firestore.
  Future<String> addIncomeSource(IncomeSource source) async {
    try {
      final docRef = await _sourcesRef.add(source.toMap());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw Exception('Failed to add income source: ${e.message}');
    }
  }

  // ─── Private Helpers ───────────────────────────────────────────────────────

  /// Writes the "General" default source to Firestore if it doesn't exist.
  Future<void> _ensureDefaultSourceExists() async {
    final docRef = _sourcesRef.doc(IncomeSource.general.id);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set(IncomeSource.general.toMap());
    }
  }
}