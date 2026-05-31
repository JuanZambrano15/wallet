import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseType { fixed, variable }

class Expense {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final ExpenseType type;
  final String categoryId; 
  final String name;
  final String description;
  final DateTime? dueDate; 

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.dueDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type.name, // 'fixed' o 'variable'
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      amount: (map['amount'] as num? ?? 0).toDouble(),
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      type: map['type'] == 'fixed' ? ExpenseType.fixed : ExpenseType.variable,
      categoryId: map['categoryId'] as String? ?? 'other',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
    );
  }

  Expense copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    ExpenseType? type,
    String? categoryId,
    String? name,
    String? description,
    DateTime? dueDate,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

// Categorías de gasto predefinidas para gastos variables
class ExpenseCategory {
  final String id;
  final String userId;
  final String name;
  final bool isDefault; // true = categoría del sistema, false = personalizada

  const ExpenseCategory({
    required this.id,
    required this.userId,
    required this.name,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'name': name,
        'isDefault': isDefault,
      };

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as String? ?? '',
        userId: map['userId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        isDefault: map['isDefault'] as bool? ?? false,
      );

  // Categorías predefinidas del sistema
  static List<ExpenseCategory> defaults(String userId) => [
        ExpenseCategory(id: 'food', userId: userId, name: 'Alimentación', isDefault: true),
        ExpenseCategory(id: 'transport', userId: userId, name: 'Transporte', isDefault: true),
        ExpenseCategory(id: 'entertainment', userId: userId, name: 'Entretenimiento', isDefault: true),
        ExpenseCategory(id: 'health', userId: userId, name: 'Salud', isDefault: true),
        ExpenseCategory(id: 'education', userId: userId, name: 'Educación', isDefault: true),
      ];
}
