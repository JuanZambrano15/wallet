import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expenseCategories.dart';
import '../data/expense_emojis.dart';

class ExpenseCategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('expense_categories');

  Future<String> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('userId') ?? '';
    if (id.isEmpty) throw Exception('Usuario no autenticado');
    return id;
  }

  List<ExpenseCategory> getSystemCategories() {
    return ExpenseEmojis.systemCategories
        .map(
          (c) => ExpenseCategory(
            id: c['id']!,
            userId: '',
            name: c['name']!,
            emoji: c['emoji']!,
            personalized: false,
          ),
        )
        .toList();
  }

  Future<ExpenseCategory> createCategory({
    required String name,
    required String emoji,
    String description = '',
  }) async {
    final userId = await _getCurrentUserId();

    await _assertNameIsUnique(name: name, userId: userId);

    final ref = _col.doc();
    final category = ExpenseCategory(
      id: ref.id,
      userId: userId,
      name: name.trim(),
      emoji: emoji,
      description: description.trim(),
      personalized: true,
    );

    await ref.set(category.toMap());
    return category;
  }

  Future<List<ExpenseCategory>> getAllCategories() async {
    final userId = await _getCurrentUserId();
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get();

    final custom = snapshot.docs
        .map((d) => ExpenseCategory.fromMap(d.data() as Map<String, dynamic>))
        .toList();

    return [...getSystemCategories(), ...custom];
  }

  Future<List<ExpenseCategory>> getUserCategories() async {
    final userId = await _getCurrentUserId();
    final snapshot = await _col
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .get();

    return snapshot.docs
        .map((d) => ExpenseCategory.fromMap(d.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ExpenseCategory>> streamAllCategories(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('name')
        .snapshots()
        .map((snap) {
          final custom = snap.docs
              .map(
                (d) =>
                    ExpenseCategory.fromMap(d.data() as Map<String, dynamic>),
              )
              .toList();
          return [...getSystemCategories(), ...custom];
        });
  }

  Future<ExpenseCategory?> getCategoryById(String id) async {
    // Primero revisar si es del sistema (sin consulta a Firestore)
    final sys = getSystemCategories().where((c) => c.id == id).firstOrNull;
    if (sys != null) return sys;

    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required String emoji,
    String description = '',
  }) async {
    final userId = await _getCurrentUserId();

    await _assertNameIsUnique(name: name, userId: userId, excludeId: id);

    await _col.doc(id).update({
      'name': name.trim(),
      'emoji': emoji,
      'description': description.trim(),
    });
  }

  Future<void> deleteCategory(String id) async {
    // Proteger categorías del sistema
    if (id.startsWith('sys_')) {
      throw Exception('Las categorías del sistema no se pueden eliminar');
    }
    await _col.doc(id).delete();
  }

  Future<void> _assertNameIsUnique({
    required String name,
    required String userId,
    String? excludeId,
  }) async {
    final systemNames = getSystemCategories()
        .map((c) => c.name.toLowerCase())
        .toList();
    if (systemNames.contains(name.trim().toLowerCase())) {
      throw Exception('"${name.trim()}" ya existe como categoría del sistema');
    }

    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('name', isEqualTo: name.trim())
        .get();

    if (snap.docs.isEmpty) return;

    if (excludeId != null && snap.docs.every((d) => d.id == excludeId)) {
      return;
    }

    throw Exception('Ya tienes una categoría llamada "${name.trim()}"');
  }
}
