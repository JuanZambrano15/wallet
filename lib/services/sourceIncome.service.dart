import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sourceIncome.dart';

class SourceIncomeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _collection => _db.collection('source_incomes');

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';
    if (userId.isEmpty) throw Exception('Usuario no autenticado');
    return userId;
  }

  Future<SourceIncome> createSourceIncome({
    required String name,
    String description = '',
  }) async {
    final userId = await _getCurrentUserId();

    final exists = await _nameExistsForUser(name: name, userId: userId);
    if (exists) {
      throw Exception('Ya existe una fuente de ingreso con el nombre "$name"');
    }

    final docRef = _collection.doc();
    final source = SourceIncome(
      id: docRef.id,
      userId: userId,
      name: name.trim(),
      description: description.trim(),
      personalized: true,
    );

    await docRef.set(source.toMap());
    return source;
  }

  Future<List<SourceIncome>> getSourceIncomesByUser() async {
    final userId = await _getCurrentUserId();

    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get();

    final sources = snapshot.docs
        .map((doc) => SourceIncome.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    if (sources.isEmpty) {
      return [_genericSource(userId)];
    }

    return sources;
  }

  Stream<List<SourceIncome>> streamSourceIncomesByUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          final sources = snapshot.docs
              .map(
                (doc) =>
                    SourceIncome.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          if (sources.isEmpty) return [_genericSource(userId)];
          return sources;
        });
  }

  Future<SourceIncome?> getSourceIncomeById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return SourceIncome.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateSourceIncome({
    required String id,
    required String name,
    String description = '',
  }) async {
    final userId = await _getCurrentUserId();

    final exists = await _nameExistsForUser(
      name: name,
      userId: userId,
      excludeId: id,
    );
    if (exists) {
      throw Exception('Ya existe una fuente de ingreso con el nombre "$name"');
    }

    await _collection.doc(id).update({
      'name': name.trim(),
      'description': description.trim(),
    });
  }

  Future<void> deleteSourceIncome(String id) async {
    await _collection.doc(id).delete();
  }

  Future<bool> _nameExistsForUser({
    required String name,
    required String userId,
    String? excludeId,
  }) async {
    var query = _collection
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: name.trim());

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) return false;

    if (excludeId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeId);
    }

    return true;
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
